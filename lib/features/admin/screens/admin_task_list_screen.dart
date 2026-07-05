import 'package:flutter/material.dart';
import 'package:sign/features/admin/screens/admin_task_edit_screen.dart';
import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class AdminTaskListScreen extends StatefulWidget {
  const AdminTaskListScreen({super.key});

  @override
  State<AdminTaskListScreen> createState() => _AdminTaskListScreenState();
}

class _AdminTaskListScreenState extends State<AdminTaskListScreen> {
  final _repository = SignRepository();
  late Future<List<SignTask>> _tasksFuture;
  SignTask? _selectedTask;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _repository.fetchTasks(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    try {
      final tasks = await _repository.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasksFuture = Future.value(tasks);
        if (_selectedTask != null &&
            !tasks.any((t) => t.id == _selectedTask!.id)) {
          _selectedTask = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _openEditor([SignTask? task]) async {
    if (isWideScreen(context)) {
      setState(() {
        if (task == null) {
          _isCreatingNew = true;
          _selectedTask = null;
        } else {
          _isCreatingNew = false;
          _selectedTask = task;
        }
      });
    } else {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AdminTaskEditScreen(task: task),
        ),
      );
      if (changed == true) {
        _reload();
      }
    }
  }

  Future<void> _deleteTask(SignTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除“${task.title}”吗？相关签到记录也会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteTask(task);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除成功')));
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务管理'), centerTitle: true),
      body: FutureBuilder<List<SignTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('暂无任务'));
          }

          final list = RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isSelected = _selectedTask?.id == task.id;

                return Card(
                  elevation: isSelected ? 4 : 0,
                  color: isSelected
                      ? AppCardStyle.selectedBackground(context)
                      : AppCardStyle.background(context),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: AppCardStyle.shape(context).copyWith(
                    side: isSelected
                        ? BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => _openEditor(task),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('时间: ${task.timeRange}'),
                        Text('地点: ${task.location}'),
                        Text('状态: ${task.statusLabel}'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: '编辑',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.teal,
                          ),
                          onPressed: () => _openEditor(task),
                        ),
                        IconButton(
                          tooltip: '删除',
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _deleteTask(task),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );

          return ResponsiveSplitView(
            master: list,
            detail: (_selectedTask != null || _isCreatingNew)
                ? AdminTaskEditScreen(
                    key: ValueKey(_isCreatingNew ? 'new' : _selectedTask!.id),
                    task: _selectedTask,
                    onCompleted: () {
                      _reload();
                      setState(() {
                        _selectedTask = null;
                        _isCreatingNew = false;
                      });
                    },
                    onCancelled: () {
                      setState(() {
                        _selectedTask = null;
                        _isCreatingNew = false;
                      });
                    },
                  )
                : null,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('发布新任务'),
      ),
    );
  }
}
