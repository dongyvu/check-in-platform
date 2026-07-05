import 'package:flutter/material.dart';
import 'package:sign/features/admin/screens/admin_task_stats_detail_screen.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final _repository = SignRepository();
  late Future<List<TaskStats>> _statsFuture;
  TaskStats? _selectedStat;

  @override
  void initState() {
    super.initState();
    _statsFuture = _repository.fetchTaskStats(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final stats = await _repository.fetchTaskStats();
      if (!mounted) return;
      setState(() {
        _statsFuture = Future.value(stats);
        if (_selectedStat != null &&
            !stats.any((s) => s.task.id == _selectedStat!.task.id)) {
          _selectedStat = null;
        } else if (_selectedStat != null) {
          _selectedStat = stats.firstWhere(
            (s) => s.task.id == _selectedStat!.task.id,
          );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计'), centerTitle: true),
      body: FutureBuilder<List<TaskStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final taskStatistics = snapshot.data ?? [];
          if (taskStatistics.isEmpty) {
            return const Center(child: Text('暂无统计数据'));
          }

          final list = RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: taskStatistics.length,
              itemBuilder: (context, index) {
                final stat = taskStatistics[index];
                final isSelected = _selectedStat?.task.id == stat.task.id;

                return Card(
                  elevation: isSelected ? 4 : 0,
                  color: isSelected
                      ? AppCardStyle.selectedBackground(context)
                      : AppCardStyle.background(context),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: AppCardStyle.shape(context, radius: 16).copyWith(
                    side: isSelected
                        ? BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (isWideScreen(context)) {
                        setState(() => _selectedStat = stat);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminTaskStatsDetailScreen(task: stat.task),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.15,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      stat.task.singleLineTimeRange,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat(
                                context,
                                '已签到',
                                stat.signedIn.toString(),
                                Colors.green,
                              ),
                              _buildMiniStat(
                                context,
                                '未签到',
                                stat.missing.toString(),
                                Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );

          return ResponsiveSplitView(
            master: list,
            detail: _selectedStat != null
                ? AdminTaskStatsDetailScreen(
                    key: ValueKey(_selectedStat!.task.id),
                    task: _selectedStat!.task,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
