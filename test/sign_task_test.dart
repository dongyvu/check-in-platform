import 'package:flutter_test/flutter_test.dart';
import 'package:sign/models/sign_record.dart';
import 'package:sign/models/sign_task.dart';

void main() {
  test('late_at falls back to end_at for old cached tasks', () {
    final task = SignTask.fromMap({
      'id': 'task-1',
      'title': '签到',
      'start_at': '2026-06-23T00:30:00.000Z',
      'end_at': '2026-06-23T01:00:00.000Z',
      'location': '公司正门',
      'remarks': '',
      'status': 'active',
    });

    expect(task.lateAt, task.endAt);
    expect(task.toMap()['late_at'], task.endAt.toUtc().toIso8601String());
  });

  test('sign record status labels include missing', () {
    final record = SignRecord(
      id: 'missing-task-1-user-1',
      taskId: 'task-1',
      userId: 'user-1',
      checkedAt: DateTime(2026, 6, 24, 9),
      location: '公司正门',
      status: 'missing',
      photoUrl: null,
    );

    expect(record.isMissing, isTrue);
    expect(record.statusLabel, '缺卡');
  });
}
