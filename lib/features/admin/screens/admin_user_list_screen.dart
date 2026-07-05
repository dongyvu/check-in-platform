import 'package:flutter/material.dart';
import 'package:sign/features/admin/screens/admin_user_record_detail_screen.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class AdminUserListScreen extends StatefulWidget {
  final String taskName;
  final String categoryName;
  final List<Map<String, String>> users;

  const AdminUserListScreen({
    super.key,
    required this.taskName,
    required this.categoryName,
    required this.users,
  });

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final list = widget.users.isEmpty
        ? const Center(child: Text('暂无人员记录'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.users.length,
            itemBuilder: (context, index) {
              final record = widget.users[index];
              final status = record['status'];
              Color statusColor;
              IconData statusIcon;

              if (status == '正常') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == '迟到') {
                statusColor = Colors.orange;
                statusIcon = Icons.warning;
              } else {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              }

              final isSelected = _selectedIndex == index;

              return Card(
                elevation: isSelected ? 4 : 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: isSelected
                    ? AppCardStyle.selectedBackground(context)
                    : AppCardStyle.background(context),
                shape: AppCardStyle.shape(context).copyWith(
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    record['user']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    status == '缺卡' ? '无打卡记录' : '打卡时间: ${record['time']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isWideScreen(context)) {
                      setState(() => _selectedIndex = index);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminUserRecordDetailScreen(
                            taskName: widget.taskName,
                            recordData: record,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.taskName} - ${widget.categoryName}人员'),
      ),
      body: ResponsiveSplitView(
        master: list,
        detail: _selectedIndex != null
            ? AdminUserRecordDetailScreen(
                key: ValueKey(_selectedIndex),
                taskName: widget.taskName,
                recordData: widget.users[_selectedIndex!],
              )
            : null,
      ),
    );
  }
}
