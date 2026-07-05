import 'package:flutter/material.dart';

import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';

enum _TaskDateTimeField { start, late, end }

class AdminTaskEditScreen extends StatefulWidget {
  final SignTask? task;
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;

  const AdminTaskEditScreen({
    super.key,
    this.task,
    this.onCompleted,
    this.onCancelled,
  });

  @override
  State<AdminTaskEditScreen> createState() => _AdminTaskEditScreenState();
}

class _AdminTaskEditScreenState extends State<AdminTaskEditScreen> {
  final _titleController = TextEditingController();
  final _startAtController = TextEditingController();
  final _lateAtController = TextEditingController();
  final _endAtController = TextEditingController();
  final _locationController = TextEditingController();
  final _remarksController = TextEditingController();
  final _repository = SignRepository();

  DateTime? _startAt;
  DateTime? _lateAt;
  DateTime? _endAt;
  bool _lateAtTouched = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _locationController.text = task.location;
      _remarksController.text = task.remarks;
      _startAt = task.startAt;
      _lateAt = task.lateAt;
      _endAt = task.endAt;
      _lateAtTouched = true;
    } else {
      _startAt = DateTime.now();
      _endAt = _startAt!.add(const Duration(hours: 1));
      _lateAt = _endAt;
    }
    _syncDateTimeControllers();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _startAt == null ||
        _lateAt == null ||
        _endAt == null ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写任务名称、开始时间、正常截止时间、结束时间和地点')),
      );
      return;
    }

    if (!_endAt!.isAfter(_startAt!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间')));
      return;
    }

    if (_lateAt!.isBefore(_startAt!) || _lateAt!.isAfter(_endAt!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正常签到截止时间必须在开始和结束时间之间')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repository.saveTask(
        existing: widget.task,
        title: _titleController.text.trim(),
        startAt: _startAt!,
        lateAt: _lateAt!,
        endAt: _endAt!,
        location: _locationController.text.trim(),
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存成功')));

      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDateTime({required _TaskDateTimeField field}) async {
    final currentValue = switch (field) {
      _TaskDateTimeField.start => _startAt,
      _TaskDateTimeField.late => _lateAt,
      _TaskDateTimeField.end => _endAt,
    };
    final initialDate = currentValue ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: switch (field) {
        _TaskDateTimeField.start => '选择开始日期',
        _TaskDateTimeField.late => '选择正常签到截止日期',
        _TaskDateTimeField.end => '选择结束日期',
      },
      cancelText: '取消',
      confirmText: '下一步',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: switch (field) {
        _TaskDateTimeField.start => '选择开始时间',
        _TaskDateTimeField.late => '选择正常签到截止时间',
        _TaskDateTimeField.end => '选择结束时间',
      },
      cancelText: '取消',
      confirmText: '确定',
      hourLabelText: '时',
      minuteLabelText: '分',
    );

    if (pickedTime == null) return;

    final pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      switch (field) {
        case _TaskDateTimeField.start:
          _startAt = pickedDateTime;
          if (_endAt != null && !_endAt!.isAfter(_startAt!)) {
            _endAt = null;
            _lateAt = null;
          } else if (_lateAt != null && _lateAt!.isBefore(_startAt!)) {
            _lateAt = _startAt;
          }
          break;
        case _TaskDateTimeField.late:
          _lateAt = pickedDateTime;
          _lateAtTouched = true;
          break;
        case _TaskDateTimeField.end:
          _endAt = pickedDateTime;
          if (!_lateAtTouched || _lateAt == null || _lateAt!.isAfter(_endAt!)) {
            _lateAt = _endAt;
          }
          break;
      }
      _syncDateTimeControllers();
    });
  }

  void _syncDateTimeControllers() {
    _startAtController.text = _startAt == null
        ? ''
        : _formatDateTime(_startAt!);
    _lateAtController.text = _lateAt == null ? '' : _formatDateTime(_lateAt!);
    _endAtController.text = _endAt == null ? '' : _formatDateTime(_endAt!);
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startAtController.dispose();
    _lateAtController.dispose();
    _endAtController.dispose();
    _locationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '修改签到任务' : '发布签到任务'),
        automaticallyImplyLeading: !isWide,
        actions: widget.onCancelled != null
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancelled,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: _startAtController,
              decoration: const InputDecoration(
                labelText: '开始日期时间',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_available_outlined),
              ),
              onTap: () => _pickDateTime(field: _TaskDateTimeField.start),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: _lateAtController,
              decoration: const InputDecoration(
                labelText: '正常签到截止时间',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              onTap: () => _pickDateTime(field: _TaskDateTimeField.late),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: _endAtController,
              decoration: const InputDecoration(
                labelText: '结束日期时间',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_busy_outlined),
              ),
              onTap: () => _pickDateTime(field: _TaskDateTimeField.end),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '签到地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注信息（选填）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.flag_outlined),
              title: Text('迟到判定'),
              subtitle: Text('开始后到正常截止时间内为正常签到；超过正常截止时间但未超过结束时间为迟到。'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isSaving ? '保存中...' : '保存',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
