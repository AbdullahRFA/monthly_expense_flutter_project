import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';
import '../domain/task_group_model.dart';
import 'add_edit_task_group_dialog.dart';
import 'todo_tasks_screen.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  // Helper to group lists by date
  Map<String, List<TaskGroupModel>> _groupGroupsByDate(List<TaskGroupModel> groups) {
    final Map<String, List<TaskGroupModel>> grouped = {};
    for (var group in groups) {
      final dateKey = DateFormat('yyyy-MM-dd').format(group.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(group);
    }
    return grouped;
  }

  // Helper to get nice header text (Today, Yesterday, etc.)
  String _getNiceHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Groups
    final groupsAsync = ref.watch(taskGroupListProvider);
    final isDark = ref.watch(themeProvider);

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("My Lists", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text("New List"),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditTaskGroupDialog(),
          );
        },
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No task lists yet", style: TextStyle(color: subTextColor, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Create a folder to organize tasks", style: TextStyle(color: subTextColor, fontSize: 14)),
                ],
              ),
            );
          }

          // 1. Group the data
          final groupedMap = _groupGroupsByDate(groups);
          final dateKeys = groupedMap.keys.toList(); // keys are already sorted if incoming list is sorted by date

          // 2. Build the list with headers
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              final dateKey = dateKeys[index];
              final dayGroups = groupedMap[dateKey]!;
              final headerText = _getNiceHeader(dateKey);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      headerText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // List of Cards for this date
                  ...dayGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _TaskGroupCard(group: group, isDark: isDark, ref: ref),
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: textColor))),
      ),
    );
  }
}

class _TaskGroupCard extends StatelessWidget {
  final TaskGroupModel group;
  final bool isDark;
  final WidgetRef ref;

  const _TaskGroupCard({required this.group, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to the Tasks Screen
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodoTasksScreen(groupId: group.id, groupTitle: group.title))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon & Title
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.list_alt_rounded, color: Colors.purple),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.title,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                if (group.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      group.description,
                                      style: TextStyle(fontSize: 13, color: subTextColor),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // More Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: subTextColor),
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(context: context, builder: (_) => AddEditTaskGroupDialog(groupToEdit: group));
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, group.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text("Edit", style: TextStyle(color: textColor))),
                        const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: subTextColor),
                    const SizedBox(width: 6),
                    Text(
                      "Created on ${DateFormat('MMM d, y').format(group.createdAt)}",
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text("Open", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.purple)
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String groupId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete List?"),
        content: const Text("This will remove the list and all tasks inside it."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                ref.read(todoRepositoryProvider).deleteTaskGroup(groupId);
                Navigator.pop(ctx);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}