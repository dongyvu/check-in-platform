class SignTask {
  final String id;
  final String title;
  final String timeRange;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime lateAt;
  final String startTime;
  final String endTime;
  final String location;
  final String remarks;
  final String status;

  const SignTask({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.startAt,
    required this.endAt,
    required this.lateAt,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.remarks,
    required this.status,
  });

  bool get isEnded => computedStatus == 'ended';
  bool get isActive => computedStatus == 'active';
  String get compactTimeRange {
    if (_isSameDate(startAt, endAt)) {
      return '${_formatShortDate(startAt)} ${_formatTime(startAt)}-${_formatTime(endAt)}';
    }
    return '${_formatShortDate(startAt)} ${_formatTime(startAt)}\n${_formatShortDate(endAt)} ${_formatTime(endAt)}';
  }

  String get singleLineTimeRange {
    if (_isSameDate(startAt, endAt)) {
      return '${_formatShortDate(startAt)} ${_formatTime(startAt)}-${_formatTime(endAt)}';
    }
    return '${_formatShortDate(startAt)} ${_formatTime(startAt)} - ${_formatShortDate(endAt)} ${_formatTime(endAt)}';
  }

  String get normalDeadlineText => _formatDateTime(lateAt);

  String get statusLabel {
    switch (computedStatus) {
      case 'active':
        return '进行中';
      case 'ended':
        return '已结束';
      default:
        return '未开始';
    }
  }

  String get computedStatus {
    final now = DateTime.now();
    if (now.isBefore(startAt)) return 'pending';
    if (!now.isAfter(endAt)) return 'active';
    return 'ended';
  }

  factory SignTask.fromMap(Map<String, dynamic> map) {
    final startAt = _parseDateTime(map['start_at'] as String?);
    final endAt = _parseDateTime(map['end_at'] as String?);
    final lateAt = _parseDateTimeOrDefault(map['late_at'] as String?, endAt);
    final startTime = _formatTime(startAt);
    final endTime = _formatTime(endAt);
    return SignTask(
      id: map['id'] as String,
      title: map['title'] as String,
      timeRange:
          (map['time_range'] as String?) ??
          '${_formatDateTime(startAt)} - ${_formatDateTime(endAt)}',
      startAt: startAt,
      endAt: endAt,
      lateAt: lateAt,
      startTime: startTime,
      endTime: endTime,
      location: map['location'] as String,
      remarks: (map['remarks'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time_range': timeRange,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'late_at': lateAt.toUtc().toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'remarks': remarks,
      'status': status,
    };
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return DateTime.now();
    return DateTime.parse(value).toLocal();
  }

  static DateTime _parseDateTimeOrDefault(String? value, DateTime fallback) {
    if (value == null || value.isEmpty) return fallback;
    return DateTime.parse(value).toLocal();
  }

  static String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${_formatTime(value)}';
  }

  static String _formatShortDate(DateTime value) {
    return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
