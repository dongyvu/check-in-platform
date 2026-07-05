import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sign/config/supabase_config.dart';
import 'package:sign/models/app_profile.dart';
import 'package:sign/models/sign_record.dart';
import 'package:sign/models/sign_task.dart';

class TaskStats {
  final SignTask task;
  final int signedIn;
  final int missing;

  const TaskStats({
    required this.task,
    required this.signedIn,
    required this.missing,
  });

  factory TaskStats.fromMap(Map<String, dynamic> map) {
    return TaskStats(
      task: SignTask.fromMap(Map<String, dynamic>.from(map['task'] as Map)),
      signedIn: map['signed_in'] as int,
      missing: map['missing'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'task': task.toMap(), 'signed_in': signedIn, 'missing': missing};
  }
}

class SignRepository {
  static const signPhotosBucket = 'sign-photos';
  static const avatarsBucket = 'avatars';
  static const _profileCachePrefix = 'cache.profile';
  static const _tasksCacheKey = 'cache.tasks';
  static const _unsignedTasksCachePrefix = 'cache.unsignedTasks';
  static const _myRecordsCachePrefix = 'cache.myRecords';
  static const _profilesCachePrefix = 'cache.profiles';
  static const _taskRecordsCachePrefix = 'cache.taskRecords';
  static const _taskStatsCachePrefix = 'cache.taskStats';
  static const _userCacheIndexPrefix = 'cache.userIndex';

  SupabaseClient get _client => supabase;

  User? get currentUser => _client.auth.currentUser;

  Future<AppProfile> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final profile = await fetchCurrentProfile();
    if (profile == null) {
      throw const AuthException('登录成功，但未找到用户资料');
    }
    return profile;
  }

  Future<AppProfile?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName ?? email.split('@').first},
    );
    if (response.session == null) {
      return null;
    }
    return fetchCurrentProfile();
  }

  Future<void> signOut() async {
    await _clearCurrentUserCache();
    await _client.auth.signOut();
  }

  Future<AppProfile?> fetchCurrentProfile({bool preferCache = false}) async {
    final user = currentUser;
    if (user == null) return null;
    final cacheKey = _profileCacheKey(user.id);

    if (preferCache) {
      final cached = await _readMapCache(cacheKey);
      if (cached != null) return AppProfile.fromMap(cached);
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    await _writeMapCache(cacheKey, data);
    return AppProfile.fromMap(data);
  }

  Future<AppProfile> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('请先登录后再修改资料');
    }

    final payload = {'display_name': displayName, 'avatar_url': avatarUrl};

    final data = await _client
        .from('profiles')
        .update(payload)
        .eq('id', user.id)
        .select()
        .single();

    await _writeMapCache(_profileCacheKey(user.id), data);
    return AppProfile.fromMap(data);
  }

  Future<String> uploadAvatar({
    required Uint8List avatarBytes,
    required String contentType,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('请先登录后再上传头像');
    }

    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = '${user.id}/avatar_$timestamp.$extension';

    await _client.storage
        .from(avatarsBucket)
        .uploadBinary(
          path,
          avatarBytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return path;
  }

  Future<String> createAvatarUrl(String avatarPath) {
    return _client.storage
        .from(avatarsBucket)
        .createSignedUrl(
          avatarPath,
          60 * 10,
          transform: const TransformOptions(
            width: 256,
            height: 256,
            quality: 80,
            resize: ResizeMode.cover,
          ),
        );
  }

  Future<void> deleteAvatar(String avatarPath) async {
    if (avatarPath.isEmpty) return;
    await _client.storage.from(avatarsBucket).remove([avatarPath]);
  }

  Future<List<SignTask>> fetchTasks({
    bool preferCache = false,
    bool includeEnded = true,
  }) async {
    if (preferCache) {
      final cached = await _readListCache(_tasksCacheKey);
      if (cached != null) {
        return _filterTasks(
          cached.map((item) => SignTask.fromMap(item)).toList(),
          includeEnded: includeEnded,
        );
      }
    }

    final data = await _client
        .from('sign_tasks')
        .select()
        .order('created_at', ascending: false);

    await _writeListCache(_tasksCacheKey, data);
    return _filterTasks(
      data.map((item) => SignTask.fromMap(item)).toList(),
      includeEnded: includeEnded,
    );
  }

  Future<List<SignTask>> fetchUnsignedTasks({bool preferCache = false}) async {
    final user = currentUser;
    if (user == null) return [];
    final cacheKey = _unsignedTasksCacheKey(user.id);

    if (preferCache) {
      final cached = await _readListCache(cacheKey);
      if (cached != null) {
        return cached
            .map((item) => SignTask.fromMap(item))
            .where((task) => !task.isEnded)
            .toList();
      }
    }

    final tasks = await fetchTasks(includeEnded: false);
    final data = await _client
        .from('sign_records')
        .select('task_id')
        .eq('user_id', user.id);
    final signedTaskIds = {for (final item in data) item['task_id'] as String};

    final unsignedTasks = tasks
        .where((task) => !signedTaskIds.contains(task.id))
        .toList();
    await _writeListCache(
      cacheKey,
      unsignedTasks.map((task) => task.toMap()).toList(),
    );
    return unsignedTasks;
  }

  Future<SignTask> saveTask({
    SignTask? existing,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required DateTime lateAt,
    required String location,
    required String remarks,
  }) async {
    final timeRange = '${_formatDateTime(startAt)} - ${_formatDateTime(endAt)}';
    final payload = {
      'title': title,
      'time_range': timeRange,
      'start_time': '${_formatTime(startAt)}:00',
      'end_time': '${_formatTime(endAt)}:00',
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'late_at': lateAt.toUtc().toIso8601String(),
      'location': location,
      'remarks': remarks,
      'status': _statusForDateRange(startAt, endAt),
    };

    final data = await _saveTaskPayload(payload: payload, existing: existing);
    if (existing != null) {
      await _recalculateTaskRecordStatuses(taskId: existing.id, lateAt: lateAt);
    }

    await _removeCache(_tasksCacheKey);
    await _clearCurrentUserAdminCaches();
    return SignTask.fromMap(data);
  }

  Future<Map<String, dynamic>> _saveTaskPayload({
    required Map<String, dynamic> payload,
    required SignTask? existing,
  }) async {
    try {
      return await _writeTaskPayload(payload: payload, existing: existing);
    } on PostgrestException catch (error) {
      if (!_isMissingLateAtSchemaError(error)) rethrow;
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('late_at');
      return _writeTaskPayload(payload: fallbackPayload, existing: existing);
    }
  }

  Future<Map<String, dynamic>> _writeTaskPayload({
    required Map<String, dynamic> payload,
    required SignTask? existing,
  }) async {
    if (existing == null) {
      return await _client
          .from('sign_tasks')
          .insert({...payload, 'created_by': currentUser?.id})
          .select()
          .single();
    }

    return await _client
        .from('sign_tasks')
        .update(payload)
        .eq('id', existing.id)
        .select()
        .single();
  }

  bool _isMissingLateAtSchemaError(PostgrestException error) {
    return error.code == 'PGRST204' && error.message.contains('late_at');
  }

  Future<void> deleteTask(SignTask task) async {
    final records = await fetchTaskRecords(task.id);
    final photoPaths = records
        .map((record) => record.photoUrl)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();

    if (photoPaths.isNotEmpty) {
      await _client.storage.from(signPhotosBucket).remove(photoPaths);
    }

    await _client.from('sign_tasks').delete().eq('id', task.id);
    await _removeCache(_tasksCacheKey);
    await _clearCurrentUserAdminCaches(taskId: task.id);
  }

  String _statusForDateRange(DateTime startAt, DateTime endAt) {
    final now = DateTime.now();
    if (now.isBefore(startAt)) return 'pending';
    if (!now.isAfter(endAt)) return 'active';
    return 'ended';
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> submitRecord(
    SignTask task, {
    required Uint8List photoBytes,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('请先登录后再签到');
    }

    final photoPath = await _uploadSignPhoto(
      taskId: task.id,
      userId: user.id,
      photoBytes: photoBytes,
    );

    final checkedAt = DateTime.now();
    final recordStatus = checkedAt.isAfter(task.lateAt) ? 'late' : 'normal';

    await _client.from('sign_records').upsert({
      'task_id': task.id,
      'user_id': user.id,
      'location': task.location,
      'status': recordStatus,
      'checked_at': checkedAt.toUtc().toIso8601String(),
      'photo_url': photoPath,
    }, onConflict: 'task_id,user_id');
    await _removeCache(_unsignedTasksCacheKey(user.id));
    await _removeCache(_myRecordsCacheKey(user.id));
  }

  Future<void> _recalculateTaskRecordStatuses({
    required String taskId,
    required DateTime lateAt,
  }) async {
    final lateAtUtc = lateAt.toUtc().toIso8601String();
    await _client
        .from('sign_records')
        .update({'status': 'normal'})
        .eq('task_id', taskId)
        .lte('checked_at', lateAtUtc);
    await _client
        .from('sign_records')
        .update({'status': 'late'})
        .eq('task_id', taskId)
        .gt('checked_at', lateAtUtc);
  }

  Future<String> _uploadSignPhoto({
    required String taskId,
    required String userId,
    required Uint8List photoBytes,
  }) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = '$taskId/$userId/$timestamp.jpg';
    await _client.storage
        .from(signPhotosBucket)
        .uploadBinary(
          path,
          photoBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    return path;
  }

  Future<String> createSignPhotoUrl(String photoPath) {
    return _client.storage
        .from(signPhotosBucket)
        .createSignedUrl(
          photoPath,
          60 * 10,
          transform: const TransformOptions(
            width: 900,
            quality: 75,
            resize: ResizeMode.contain,
          ),
        );
  }

  Future<List<SignRecord>> fetchMyRecords({bool preferCache = false}) async {
    final user = currentUser;
    if (user == null) return [];
    final cacheKey = _myRecordsCacheKey(user.id);

    if (preferCache) {
      final cached = await _readListCache(cacheKey);
      if (cached != null) {
        return cached.map((item) => SignRecord.fromMap(item)).toList();
      }
    }

    final data = await _client
        .from('sign_records')
        .select('*, sign_tasks(*)')
        .eq('user_id', user.id)
        .order('checked_at', ascending: false);

    final records = data.map((item) => SignRecord.fromMap(item)).toList();
    final signedTaskIds = {for (final record in records) record.taskId};
    final endedTasks = (await fetchTasks()).where((task) => task.isEnded);

    final historyRecords = [
      ...records,
      for (final task in endedTasks)
        if (!signedTaskIds.contains(task.id))
          SignRecord(
            id: 'missing-${task.id}-${user.id}',
            taskId: task.id,
            userId: user.id,
            checkedAt: task.endAt,
            location: task.location,
            status: 'missing',
            photoUrl: null,
            task: task,
          ),
    ]..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));

    await _writeListCache(
      cacheKey,
      historyRecords.map((record) => record.toMap()),
    );
    return historyRecords;
  }

  Future<SignRecord?> fetchMyTaskRecord(String taskId) async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('sign_records')
        .select('*, sign_tasks(*)')
        .eq('user_id', user.id)
        .eq('task_id', taskId)
        .maybeSingle();

    return data == null ? null : SignRecord.fromMap(data);
  }

  Future<List<AppProfile>> fetchProfiles({bool preferCache = false}) async {
    final user = currentUser;
    final cacheKey = user == null ? null : _profilesCacheKey(user.id);

    if (preferCache && cacheKey != null) {
      final cached = await _readListCache(cacheKey);
      if (cached != null) {
        return cached.map((item) => AppProfile.fromMap(item)).toList();
      }
    }

    final data = await _client
        .from('profiles')
        .select()
        .order('display_name', ascending: true);

    if (cacheKey != null) {
      await _writeListCache(cacheKey, data);
    }
    return data.map((item) => AppProfile.fromMap(item)).toList();
  }

  Future<List<SignRecord>> fetchTaskRecords(
    String taskId, {
    bool preferCache = false,
  }) async {
    final user = currentUser;
    final cacheKey = user == null
        ? null
        : _taskRecordsCacheKey(user.id, taskId);

    if (preferCache && cacheKey != null) {
      final cached = await _readListCache(cacheKey);
      if (cached != null) {
        return cached.map((item) => SignRecord.fromMap(item)).toList();
      }
    }

    final data = await _client
        .from('sign_records')
        .select()
        .eq('task_id', taskId)
        .order('checked_at', ascending: true);

    if (cacheKey != null) {
      await _writeListCache(cacheKey, data);
    }
    return data.map((item) => SignRecord.fromMap(item)).toList();
  }

  Future<List<TaskStats>> fetchTaskStats({bool preferCache = false}) async {
    final user = currentUser;
    final cacheKey = user == null ? null : _taskStatsCacheKey(user.id);

    if (preferCache && cacheKey != null) {
      final cached = await _readListCache(cacheKey);
      if (cached != null) {
        return cached.map((item) => TaskStats.fromMap(item)).toList();
      }
    }

    final tasks = await fetchTasks();
    final profiles = (await fetchProfiles())
        .where((profile) => !profile.isAdmin)
        .toList();

    final data = await _client.from('sign_records').select('task_id');
    final counts = <String, int>{};
    for (final item in data) {
      final taskId = item['task_id'] as String;
      counts[taskId] = (counts[taskId] ?? 0) + 1;
    }

    final stats = tasks
        .map(
          (task) => TaskStats(
            task: task,
            signedIn: counts[task.id] ?? 0,
            missing: profiles.length - (counts[task.id] ?? 0),
          ),
        )
        .toList();
    if (cacheKey != null) {
      await _writeListCache(cacheKey, stats.map((stat) => stat.toMap()));
    }
    return stats;
  }

  String _profileCacheKey(String userId) => '$_profileCachePrefix.$userId';

  String _unsignedTasksCacheKey(String userId) =>
      '$_unsignedTasksCachePrefix.$userId';

  String _myRecordsCacheKey(String userId) => '$_myRecordsCachePrefix.$userId';

  String _profilesCacheKey(String userId) => '$_profilesCachePrefix.$userId';

  String _taskRecordsCacheKey(String userId, String taskId) =>
      '$_taskRecordsCachePrefix.$userId.$taskId';

  String _taskStatsCacheKey(String userId) => '$_taskStatsCachePrefix.$userId';

  String _userCacheIndexKey(String userId) => '$_userCacheIndexPrefix.$userId';

  List<SignTask> _filterTasks(
    List<SignTask> tasks, {
    required bool includeEnded,
  }) {
    if (includeEnded) return tasks;
    return tasks.where((task) => !task.isEnded).toList();
  }

  Future<Map<String, dynamic>?> _readMapCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      await prefs.remove(key);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> _readListCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {
      await prefs.remove(key);
    }
    return null;
  }

  Future<void> _writeMapCache(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
    await _rememberCurrentUserCacheKey(prefs, key);
  }

  Future<void> _writeListCache(
    String key,
    Iterable<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value.toList()));
    await _rememberCurrentUserCacheKey(prefs, key);
  }

  Future<void> _removeCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> _rememberCurrentUserCacheKey(
    SharedPreferences prefs,
    String key,
  ) async {
    final user = currentUser;
    if (user == null) return;
    if (key == _tasksCacheKey) return;

    final indexKey = _userCacheIndexKey(user.id);
    final keys = prefs.getStringList(indexKey) ?? <String>[];
    if (keys.contains(key)) return;
    await prefs.setStringList(indexKey, [...keys, key]);
  }

  Future<void> _clearCurrentUserCache() async {
    final user = currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final indexKey = _userCacheIndexKey(user.id);
    final keys = prefs.getStringList(indexKey) ?? <String>[];
    for (final key in keys) {
      await prefs.remove(key);
    }
    await prefs.remove(indexKey);
  }

  Future<void> _clearCurrentUserAdminCaches({String? taskId}) async {
    final user = currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final indexKey = _userCacheIndexKey(user.id);
    final keys = prefs.getStringList(indexKey) ?? <String>[];
    final taskRecordsKey = taskId == null
        ? null
        : _taskRecordsCacheKey(user.id, taskId);
    final keysToRemove = keys.where((key) {
      return key == _profilesCacheKey(user.id) ||
          key == _taskStatsCacheKey(user.id) ||
          key == taskRecordsKey ||
          (taskId == null &&
              key.startsWith('$_taskRecordsCachePrefix.${user.id}.'));
    }).toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      await prefs.setStringList(
        indexKey,
        keys.where((key) => !keysToRemove.contains(key)).toList(),
      );
    }
  }
}
