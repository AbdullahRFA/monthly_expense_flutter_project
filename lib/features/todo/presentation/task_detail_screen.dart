import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';
import '../domain/todo_model.dart';
import 'add_edit_todo_dialog.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String groupId; // REQUIRED
  final String todoId;
  final TodoModel initialTodo;

  const TaskDetailScreen({
    super.key,
    required this.groupId,
    required this.todoId,
    required this.initialTodo
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We pass a tuple/record of arguments to the family provider
    final todoAsync = ref.watch(singleTodoStreamProvider((groupId: groupId, todoId: todoId)));
    final isDark = ref.watch(themeProvider);

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Task Details", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        actions: [
          // EDIT
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final currentTodo = todoAsync.value ?? initialTodo;
              showDialog(
                context: context,
                builder: (_) => AddEditTodoDialog(groupId: groupId, todoToEdit: currentTodo),
              );
            },
          ),
          // DELETE
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              _confirmDelete(context, ref);
            },
          ),
        ],
      ),
      body: todoAsync.when(
        data: (todo) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: todo.priorityColor, width: 6)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: todo.priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${todo.priority.name.toUpperCase()} PRIORITY",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: todo.priorityColor),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Status Checkbox
                      Row(
                        children: [
                          Icon(
                            todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: todo.isCompleted ? Colors.teal : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            todo.isCompleted ? "Completed" : "Pending",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: todo.isCompleted ? Colors.teal : subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Due Date Section
                if (todo.dueDate != null) ...[
                  Text("DUE DATE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, color: subTextColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(todo.dueDate!),
                          style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Description Section
                Text("DESCRIPTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    todo.description.isNotEmpty ? todo.description : "No description provided.",
                    style: TextStyle(fontSize: 16, color: todo.description.isNotEmpty ? textColor : subTextColor, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: textColor))),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(todoRepositoryProvider).deleteTodo(groupId, todoId);
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Close Screen
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}