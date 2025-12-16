import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoListProvider);
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Tasks", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) return Center(child: Text("No tasks yet!", style: TextStyle(color: textColor)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                key: Key(todo.id),
                onDismissed: (_) => ref.read(todoRepositoryProvider).deleteTodo(todo.id),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                child: Card(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: CheckboxListTile(
                    title: Text(todo.title, style: TextStyle(
                      color: textColor,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey,
                    )),
                    value: todo.isCompleted,
                    activeColor: Colors.teal,
                    checkColor: Colors.white,
                    onChanged: (_) => ref.read(todoRepositoryProvider).toggleTodo(todo.id, todo.isCompleted),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddDialog(context, ref, isDark),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("New Task", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(hintText: "What needs to be done?", hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey[600])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(todoRepositoryProvider).addTodo(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }
}