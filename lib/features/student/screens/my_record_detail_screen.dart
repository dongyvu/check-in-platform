import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sign/models/sign_record.dart';
import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';

class MyRecordDetailScreen extends StatefulWidget {
  final SignRecord record;

  const MyRecordDetailScreen({super.key, required this.record});

  @override
  State<MyRecordDetailScreen> createState() => _MyRecordDetailScreenState();
}

class _MyRecordDetailScreenState extends State<MyRecordDetailScreen> {
  final _repository = SignRepository();
  late final Future<String?> _photoUrlFuture;

  @override
  void initState() {
    super.initState();
    final photoPath = widget.record.photoUrl;
    _photoUrlFuture = photoPath == null || photoPath.isEmpty
        ? Future.value(null)
        : _repository.createSignPhotoUrl(photoPath);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final task = record.task;
    final statusColor = switch (record.status) {
      'late' => Colors.orange,
      'missing' => Theme.of(context).colorScheme.error,
      _ => Colors.green,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡详情'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildTaskCard(context, task),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: AppCardStyle.background(context),
            shape: AppCardStyle.shape(context, radius: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        record.isMissing
                            ? Icons.cancel_outlined
                            : Icons.check_circle,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.isMissing ? '未完成签到' : '已完成签到',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        record.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!record.isMissing) ...[
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      '签到时间',
                      _formatDateTime(record.checkedAt),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    record.isMissing ? '目标地点' : '签到地点',
                    record.location,
                  ),
                ],
              ),
            ),
          ),
          if (!record.isMissing) ...[
            const SizedBox(height: 24),
            Text(
              '打卡照片',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: _photoUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final photoUrl = snapshot.data;
                if (snapshot.hasError || photoUrl == null || photoUrl.isEmpty) {
                  return _buildPhotoPlaceholder(context, '暂无可查看的打卡照片');
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      cacheKey: widget.record.photoUrl,
                      placeholder: (context, url) {
                        return const SizedBox(
                          height: 320,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorWidget: (context, url, error) {
                        return _buildPhotoPlaceholder(context, '照片加载失败');
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, SignTask? task) {
    return Card(
      elevation: 0,
      color: AppCardStyle.background(context),
      shape: AppCardStyle.shape(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task?.title ?? '签到任务',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (task != null) ...[
              _buildInfoRow(
                context,
                Icons.access_time,
                '要求时间',
                task.singleLineTimeRange,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.timer_outlined,
                '正常签到截止时间',
                task.normalDeadlineText,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                '目标地点',
                task.location,
              ),
              if (task.remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.note_alt_outlined,
                  '任务要求',
                  task.remarks,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context, String text) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
