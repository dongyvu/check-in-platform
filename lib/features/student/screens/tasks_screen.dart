import 'package:flutter/material.dart';
import 'package:sign/features/student/screens/task_detail_screen.dart';
import 'package:sign/models/sign_task.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repository = SignRepository();
  late Future<List<SignTask>> _tasksFuture;
  SignTask? _selectedTask;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _repository.fetchUnsignedTasks(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final tasks = await _repository.fetchUnsignedTasks();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('签到任务'), centerTitle: true),
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
            return const Center(child: Text('暂无待签到任务'));
          }

          final list = RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskCard(
                  task: task,
                  isSelected: _selectedTask?.id == task.id,
                  onTap: () async {
                    if (isWideScreen(context)) {
                      setState(() => _selectedTask = task);
                    } else {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(task: task),
                        ),
                      );
                      if (changed == true) {
                        await _refresh();
                      }
                    }
                  },
                );
              },
            ),
          );

          return ResponsiveSplitView(
            master: list,
            detail: _selectedTask != null
                ? TaskDetailScreen(
                    key: ValueKey(_selectedTask!.id),
                    task: _selectedTask!,
                    onCompleted: () {
                      _refresh();
                      setState(() => _selectedTask = null);
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final SignTask task;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  Text(
                    task.timeRange,
                    style: TextStyle(color: Colors.grey[700]),
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
                      task.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
