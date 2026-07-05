import 'package:flutter/material.dart';
import 'package:sign/features/student/screens/my_record_detail_screen.dart';
import 'package:sign/models/sign_record.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = SignRepository();
  late Future<List<SignRecord>> _recordsFuture;
  SignRecord? _selectedRecord;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _repository.fetchMyRecords(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final records = await _repository.fetchMyRecords();
      if (!mounted) return;
      setState(() {
        _recordsFuture = Future.value(records);
        if (_selectedRecord != null &&
            !records.any((r) => r.id == _selectedRecord!.id)) {
          _selectedRecord = null;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录'), centerTitle: true),
      body: FutureBuilder<List<SignRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('暂无签到记录'));
          }

          final list = RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _HistoryTaskCard(
                  record: record,
                  isSelected: _selectedRecord?.id == record.id,
                  onTap: () {
                    if (isWideScreen(context)) {
                      setState(() => _selectedRecord = record);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyRecordDetailScreen(record: record),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );

          return ResponsiveSplitView(
            master: list,
            detail: _selectedRecord != null
                ? MyRecordDetailScreen(
                    key: ValueKey(_selectedRecord!.id),
                    record: _selectedRecord!,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _HistoryTaskCard extends StatelessWidget {
  final SignRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryTaskCard({
    required this.record,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final task = record.task;
    final statusColor = switch (record.status) {
      'late' => Colors.orange,
      'missing' => Theme.of(context).colorScheme.error,
      _ => Colors.green,
    };

    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected
          ? AppCardStyle.selectedBackground(context)
          : AppCardStyle.background(context),
      margin: const EdgeInsets.only(bottom: 16),
      shape: AppCardStyle.shape(context).copyWith(
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task?.title ?? '签到任务',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task?.singleLineTimeRange ?? _formatCheckedAt(record),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task?.location ?? record.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCheckedAt(SignRecord record) {
    final checkedAt = record.checkedAt;
    return '${checkedAt.month}-${checkedAt.day} ${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}
