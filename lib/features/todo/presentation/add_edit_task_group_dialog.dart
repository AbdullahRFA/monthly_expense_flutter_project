import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/todo_repository.dart';
import '../domain/task_group_model.dart';

class AddEditTaskGroupDialog extends ConsumerStatefulWidget {
  final TaskGroupModel? groupToEdit;
  const AddEditTaskGroupDialog({super.key, this.groupToEdit});

  @override
  ConsumerState<AddEditTaskGroupDialog> createState() => _AddEditTaskGroupDialogState();
}

class _AddEditTaskGroupDialogState extends ConsumerState<AddEditTaskGroupDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupToEdit != null) {
      _titleController.text = widget.groupToEdit!.title;
      _descController.text = widget.groupToEdit!.description;
      _selectedDate = widget.groupToEdit!.createdAt;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = ref.read(themeProvider);
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.teal))
              : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.groupToEdit == null) {
        // Create
        await ref.read(todoRepositoryProvider).addTaskGroup(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          date: _selectedDate,
        );
      } else {
        // Update
        final updatedGroup = TaskGroupModel(
          id: widget.groupToEdit!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          createdAt: _selectedDate,
        );
        await ref.read(todoRepositoryProvider).updateTaskGroup(updatedGroup);
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle
                      ),
                      child: const Icon(Icons.folder_copy_rounded, color: Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    Text(
                        widget.groupToEdit == null ? "New Task List" : "Edit List",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                      labelText: "List Name",
                      hintText: "e.g., Groceries, Work, Travel",
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: textColor),
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: "Description (Optional)",
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                            DateFormat('MMMM d, y').format(_selectedDate),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                        ),
                        const Spacer(),
                        const Text("Change", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text("Cancel")
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save List"),
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