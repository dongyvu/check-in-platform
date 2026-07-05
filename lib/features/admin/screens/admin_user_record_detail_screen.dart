import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';

class AdminUserRecordDetailScreen extends StatefulWidget {
  final String taskName;
  final Map<String, String> recordData;

  const AdminUserRecordDetailScreen({
    super.key,
    required this.taskName,
    required this.recordData,
  });

  @override
  State<AdminUserRecordDetailScreen> createState() =>
      _AdminUserRecordDetailScreenState();
}

class _AdminUserRecordDetailScreenState
    extends State<AdminUserRecordDetailScreen> {
  final _repository = SignRepository();
  late final Future<String?> _photoUrlFuture;
  late final Future<String?> _avatarUrlFuture;

  @override
  void initState() {
    super.initState();
    final photoPath = widget.recordData['photoPath'];
    _photoUrlFuture = photoPath == null || photoPath.isEmpty
        ? Future.value(null)
        : _repository.createSignPhotoUrl(photoPath);
    final avatarPath = widget.recordData['avatarPath'];
    _avatarUrlFuture = avatarPath == null || avatarPath.isEmpty
        ? Future.value(null)
        : _repository.createAvatarUrl(avatarPath);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.recordData['status'];
    Color statusColor;
    if (status == '正常') {
      statusColor = Colors.green;
    } else if (status == '迟到') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.taskName} - ${widget.recordData['user']}'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: AppCardStyle.background(context),
              shape: AppCardStyle.shape(context, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildAvatar(context),
                    const SizedBox(height: 16),
                    Text(
                      widget.recordData['user']!,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status!,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '详细信息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.assignment_outlined,
              '任务名称',
              widget.taskName,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.access_time,
              '打卡时间',
              widget.recordData['time']!,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.location_on_outlined,
              '打卡地点',
              widget.recordData['location']!,
            ),
            const SizedBox(height: 32),
            if (status != '缺卡') ...[
              Text(
                '现场照片',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<String?>(
                future: _photoUrlFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final photoUrl = snapshot.data;
                  if (snapshot.hasError ||
                      photoUrl == null ||
                      photoUrl.isEmpty) {
                    return _buildPhotoPlaceholder(context, '暂无可查看的签到照片');
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        cacheKey: widget.recordData['photoPath'],
                        placeholder: (context, url) {
                          return const SizedBox(
                            height: 260,
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
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        widget.recordData['user']!.substring(0, 1),
        style: TextStyle(
          fontSize: 32,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );

    return FutureBuilder<String?>(
      future: _avatarUrlFuture,
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;
        if (avatarUrl == null || avatarUrl.isEmpty) return fallback;

        return CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: CachedNetworkImageProvider(
            avatarUrl,
            cacheKey: widget.recordData['avatarPath'],
          ),
          onBackgroundImageError: (_, _) {},
        );
      },
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context, String text) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
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
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
