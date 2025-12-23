import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';
import '../domain/todo_model.dart';
import 'add_edit_todo_dialog.dart';
import 'task_detail_screen.dart';

class TodoTasksScreen extends ConsumerWidget {
  final String groupId;
  final String groupTitle;

  const TodoTasksScreen({super.key, required this.groupId, required this.groupTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch tasks for this specific group
    final todosAsync = ref.watch(todoListProvider(groupId));
    final isDark = ref.watch(themeProvider);

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(groupTitle, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text("New Task"),
        onPressed: () {
          showDialog(
            context: context,
            // Pass groupId to Dialog
            builder: (_) => AddEditTodoDialog(groupId: groupId),
          );
        },
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No tasks yet!", style: TextStyle(color: subTextColor, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Add a task to get started", style: TextStyle(color: subTextColor)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: todos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _TodoCard(todo: todo, isDark: isDark, ref: ref, groupId: groupId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: textColor))),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final bool isDark;
  final WidgetRef ref;
  final String groupId;

  const _TodoCard({
    required this.todo,
    required this.isDark,
    required this.ref,
    required this.groupId
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Pass groupId and Todo to Detail Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(groupId: groupId, todoId: todo.id, initialTodo: todo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: todo.isCompleted,
                      activeColor: todo.priorityColor,
                      shape: const CircleBorder(),
                      side: BorderSide(color: isDark ? Colors.grey : Colors.grey[400]!, width: 2),
                      onChanged: (val) {
                        // Pass groupId
                        ref.read(todoRepositoryProvider).toggleTodo(groupId, todo.id, todo.isCompleted);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.grey,
                          ),
                        ),
                        if (todo.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: subTextColor),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),

              // Metadata Row
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: todo.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: todo.priorityColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        todo.priority.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: todo.priorityColor),
                      ),
                    ),
                    if (todo.dueDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_rounded, size: 14, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(todo.dueDate!),
                        style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}