import 'sign_task.dart';

class SignRecord {
  final String id;
  final String taskId;
  final String userId;
  final DateTime checkedAt;
  final String location;
  final String status;
  final String? photoUrl;
  final SignTask? task;

  const SignRecord({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.checkedAt,
    required this.location,
    required this.status,
    required this.photoUrl,
    this.task,
  });

  bool get isMissing => status == 'missing';

  String get statusLabel {
    switch (status) {
      case 'late':
        return '迟到';
      case 'missing':
        return '缺卡';
      default:
        return '正常';
    }
  }

  factory SignRecord.fromMap(Map<String, dynamic> map) {
    final taskMap = map['sign_tasks'];
    return SignRecord(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      userId: map['user_id'] as String,
      checkedAt: DateTime.parse(map['checked_at'] as String).toLocal(),
      location: map['location'] as String,
      status: (map['status'] as String?) ?? 'normal',
      photoUrl: map['photo_url'] as String?,
      task: taskMap is Map<String, dynamic> ? SignTask.fromMap(taskMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'checked_at': checkedAt.toUtc().toIso8601String(),
      'location': location,
      'status': status,
      'photo_url': photoUrl,
      'sign_tasks': task?.toMap(),
    };
  }
}
