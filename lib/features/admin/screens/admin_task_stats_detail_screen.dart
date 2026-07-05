import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sign/features/admin/screens/admin_user_record_detail_screen.dart';
import 'package:sign/models/app_profile.dart';
import 'package:sign/models/sign_record.dart';
import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';

enum SortType { status, name }

class AdminTaskStatsDetailScreen extends StatefulWidget {
  final SignTask task;

  const AdminTaskStatsDetailScreen({super.key, required this.task});

  @override
  State<AdminTaskStatsDetailScreen> createState() =>
      _AdminTaskStatsDetailScreenState();
}

class _AdminTaskStatsDetailScreenState
    extends State<AdminTaskStatsDetailScreen> {
  final _repository = SignRepository();
  final _avatarUrlFutures = <String, Future<String>>{};
  SortType _sortType = SortType.status;
  late Future<List<_UserTaskRecord>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUsers());
  }

  Future<List<_UserTaskRecord>> _loadUsers({bool preferCache = false}) async {
    final profiles = (await _repository.fetchProfiles(
      preferCache: preferCache,
    )).where((profile) => !profile.isAdmin).toList();
    final records = await _repository.fetchTaskRecords(
      widget.task.id,
      preferCache: preferCache,
    );
    final recordsByUser = {for (final record in records) record.userId: record};

    final users = profiles.map((profile) {
      return _UserTaskRecord(
        profile: profile,
        record: recordsByUser[profile.id],
      );
    }).toList();

    _sortUsers(users);
    return users;
  }

  Future<void> _refreshUsers() async {
    try {
      final users = await _loadUsers();
      if (!mounted) return;
      setState(() {
        _usersFuture = Future.value(users);
      });
    } catch (_) {}
  }

  void _sortUsers(List<_UserTaskRecord> users) {
    if (_sortType == SortType.status) {
      int statusWeight(_UserTaskRecord user) {
        switch (user.status) {
          case '正常':
            return 0;
          case '迟到':
            return 1;
          default:
            return 2;
        }
      }

      users.sort((a, b) {
        final weightA = statusWeight(a);
        final weightB = statusWeight(b);
        if (weightA != weightB) return weightA.compareTo(weightB);
        return a.name.compareTo(b.name);
      });
    } else {
      users.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _changeSort(SortType sortType) {
    setState(() {
      _sortType = sortType;
      _usersFuture = _usersFuture.then((users) {
        _sortUsers(users);
        return users;
      });
    });
  }

  Future<String> _avatarUrlFuture(String avatarPath) {
    return _avatarUrlFutures.putIfAbsent(
      avatarPath,
      () => _repository.createAvatarUrl(avatarPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.task.title} - 统计概览',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 600,
      ),
      body: FutureBuilder<List<_UserTaskRecord>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          final expected = users.length;
          final actual = users.where((u) => u.record != null).length;
          final lateCount = users.where((u) => u.status == '迟到').length;
          final missing = users.where((u) => u.record == null).length;

          return Column(
            children: [
              _buildTopSummary(context, expected, actual, lateCount, missing),
              _buildFilterBar(),
              Expanded(child: _buildUserGrid(users)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSummary(
    BuildContext context,
    int expected,
    int actual,
    int lateCount,
    int missing,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      color: AppCardStyle.background(context),
      shape: AppCardStyle.shape(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本次签到任务概览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.task.compactTimeRange,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, '应签', expected.toString(), Colors.blue),
                _buildStatItem(context, '实签', actual.toString(), Colors.green),
                _buildStatItem(
                  context,
                  '迟到',
                  lateCount.toString(),
                  Colors.orange,
                ),
                _buildStatItem(context, '缺卡', missing.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              '签到人员列表',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              const Text('排序: ', style: TextStyle(fontSize: 14)),
              DropdownButton<SortType>(
                value: _sortType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: SortType.status, child: Text('按状态')),
                  DropdownMenuItem(value: SortType.name, child: Text('按名称')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _changeSort(val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrid(List<_UserTaskRecord> users) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final status = user.status;
        final statusColor = switch (status) {
          '正常' => Colors.green,
          '迟到' => Colors.orange,
          _ => Colors.red,
        };

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminUserRecordDetailScreen(
                  taskName: widget.task.title,
                  recordData: user.toRecordData(),
                ),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildUserAvatar(context, user),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(BuildContext context, _UserTaskRecord user) {
    final avatarPath = user.profile.avatarUrl;
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        user.name.substring(0, 1),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (avatarPath == null || avatarPath.isEmpty) return fallback;

    return FutureBuilder<String>(
      future: _avatarUrlFuture(avatarPath),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;
        if (avatarUrl == null || avatarUrl.isEmpty) return fallback;

        return CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: CachedNetworkImageProvider(
            avatarUrl,
            cacheKey: avatarPath,
          ),
          onBackgroundImageError: (_, _) {},
        );
      },
    );
  }
}

class _UserTaskRecord {
  final AppProfile profile;
  final SignRecord? record;

  const _UserTaskRecord({required this.profile, required this.record});

  String get name => profile.displayName;

  String get status {
    if (record == null) return '缺卡';
    return record!.statusLabel;
  }

  Map<String, String> toRecordData() {
    final checkedAt = record?.checkedAt;
    return {
      'user': name,
      'time': checkedAt == null
          ? '-'
          : '${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}',
      'status': status,
      'location': record?.location ?? '-',
      'photoPath': record?.photoUrl ?? '',
      'avatarPath': profile.avatarUrl ?? '',
    };
  }
}
