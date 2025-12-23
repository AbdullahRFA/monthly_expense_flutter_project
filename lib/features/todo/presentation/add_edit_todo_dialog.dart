import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';
import '../domain/todo_model.dart';

class AddEditTodoDialog extends ConsumerStatefulWidget {
  final String groupId; // REQUIRED
  final TodoModel? todoToEdit;

  const AddEditTodoDialog({super.key, required this.groupId, this.todoToEdit});

  @override
  ConsumerState<AddEditTodoDialog> createState() => _AddEditTodoDialogState();
}

class _AddEditTodoDialogState extends ConsumerState<AddEditTodoDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TodoPriority _priority = TodoPriority.medium;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      _titleController.text = widget.todoToEdit!.title;
      _descController.text = widget.todoToEdit!.description;
      _priority = widget.todoToEdit!.priority;
      _dueDate = widget.todoToEdit!.dueDate;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = ref.read(themeProvider);
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.todoToEdit == null) {
        // Add (Uses groupId)
        await ref.read(todoRepositoryProvider).addTodo(
          groupId: widget.groupId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
        );
      } else {
        // Edit (Uses groupId)
        final updatedTodo = TodoModel(
          id: widget.todoToEdit!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          isCompleted: widget.todoToEdit!.isCompleted,
          date: widget.todoToEdit!.date,
          dueDate: _dueDate,
          priority: _priority,
        );
        await ref.read(todoRepositoryProvider).updateTodo(widget.groupId, updatedTodo);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFill = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50];

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.todoToEdit == null ? "New Task" : "Edit Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 20),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(labelText: "Task Title", filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: textColor),
                  maxLines: 3,
                  decoration: InputDecoration(labelText: "Description (Optional)", filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),

                // Priority & Date Row
                Row(
                  children: [
                    // Priority
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Priority", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<TodoPriority>(
                                value: _priority,
                                isExpanded: true,
                                dropdownColor: bgColor,
                                items: TodoPriority.values.map((p) {
                                  Color color = p == TodoPriority.high ? Colors.red : (p == TodoPriority.medium ? Colors.orange : Colors.green);
                                  return DropdownMenuItem(value: p, child: Text(p.name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                                }).toList(),
                                onChanged: (val) => setState(() => _priority = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Due Date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_dueDate == null ? "None" : DateFormat('MMM d').format(_dueDate!), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Save Task"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}