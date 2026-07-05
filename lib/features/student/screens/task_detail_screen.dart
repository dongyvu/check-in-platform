import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';

class TaskDetailScreen extends StatefulWidget {
  final SignTask task;
  final VoidCallback? onCompleted;

  const TaskDetailScreen({super.key, required this.task, this.onCompleted});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _repository = SignRepository();
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        return;
      }

      final photoBytes = await photo.readAsBytes();
      await _repository.submitRecord(widget.task, photoBytes: photoBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('签到成功')));

      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('签到失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 任务信息卡片
            Card(
              elevation: 0,
              color: AppCardStyle.background(context),
              shape: AppCardStyle.shape(context, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      '要求时间',
                      task.timeRange,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.timer_outlined,
                      '正常签到截止时间',
                      task.normalDeadlineText,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.location_on_outlined,
                      '目标地点',
                      task.location,
                    ),
                    if (task.remarks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        Icons.note_alt_outlined,
                        '备注',
                        task.remarks,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.description_outlined,
                      '任务要求',
                      '请在规定时间内到达指定地点，并拍摄包含特征背景的照片进行签到。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 签到提示区域
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '请拍摄现场照片以完成签到\n确保照片清晰且包含位置特征',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _isSubmitting || !task.isActive ? null : _submit,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              _buttonText(task),
              style: const TextStyle(fontSize: 18),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  String _buttonText(SignTask task) {
    if (_isSubmitting) return '提交中...';
    if (task.computedStatus == 'pending') return '任务未开始';
    if (task.computedStatus == 'ended') return '任务已结束';
    return '拍照签到';
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
}
