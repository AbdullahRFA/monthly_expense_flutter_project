import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/savings_repository.dart';
import '../../providers/theme_provider.dart'; // Import Theme

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(savingsRepositoryProvider).addGoal(
        title: _titleController.text.trim(),
        targetAmount: double.parse(_amountController.text.trim()),
        deadline: _selectedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) {
        // Theme the DatePicker dynamically
        final isDark = ref.read(themeProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: Colors.teal, surface: Color(0xFF1E1E1E))
                : const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH THEME STATE
    final isDark = ref.watch(themeProvider);

    // 2. DEFINE DYNAMIC COLORS
    final dialogColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final inputFill = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;
    final iconColor = isDark ? Colors.grey[400] : Colors.grey;

    return PopScope(
      canPop: !_isLoading, // PREVENT DISMISSAL WHEN LOADING
      child: Dialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.teal),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "New Savings Goal",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Goal Name
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: _buildInputDecoration("Goal Name", "e.g., New Laptop", Icons.label_outline, isDark, inputFill, borderColor),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Target Amount
                  TextFormField(
                    controller: _amountController,
                    style: TextStyle(color: textColor),
                    decoration: _buildInputDecoration("Target Amount", "0.00", Icons.track_changes, isDark, inputFill, borderColor),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Deadline Picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: iconColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Target Deadline", style: TextStyle(fontSize: 12, color: subTextColor)),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM d, y').format(_selectedDate),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text("Change", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: subTextColor)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Create Goal"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon, bool isDark, Color fill, Color border) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
      prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.teal, width: 2)),
    );
  }
}