import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_expense_flutter_project/features/expenses/data/expense_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/domain/expense_model.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final String walletId;
  final double currentBalance;
  final ExpenseModel? expenseToEdit;

  const AddExpenseDialog({
    super.key,
    required this.walletId,
    required this.currentBalance,
    this.expenseToEdit,
  });

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  String _selectedCategory = 'Food';

  final List<String> _categories = [
    'Food', 'Groceries', 'Transport', 'Fuel', 'Rent', 'Bills', 'Education',
    'Shopping', 'Entertainment', 'Health', 'Personal Care', 'Pets', 'Travel',
    'Gifts', 'Donation', 'Loan', 'Investment', 'Family', 'Repairs', 'Savings', 'Others'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _titleController = TextEditingController(text: widget.expenseToEdit?.title ?? '');
    _amountController = TextEditingController(text: widget.expenseToEdit?.amount.toString() ?? '');

    if (widget.expenseToEdit != null) {
      _selectedCategory = widget.expenseToEdit!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _processTransaction() async {
    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();

      if (widget.expenseToEdit == null) {
        await ref.read(expenseRepositoryProvider).addExpense(
          walletId: widget.walletId,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
        );
      } else {
        final newExpense = ExpenseModel(
          id: widget.expenseToEdit!.id,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
        );

        await ref.read(expenseRepositoryProvider).updateExpense(
          walletId: widget.walletId,
          oldExpense: widget.expenseToEdit!,
          newExpense: newExpense,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    double impact = amount;
    if (widget.expenseToEdit != null) {
      impact = amount - widget.expenseToEdit!.amount;
    }

    if (impact > widget.currentBalance) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              const Text("High Spending Alert", style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text.rich(
            TextSpan(
              text: "You are spending ",
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(text: "৳$amount", style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: " but you only have "),
                TextSpan(text: "৳${widget.currentBalance}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const TextSpan(text: ".\n\nThis will result in a negative balance. Proceed?"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Proceed"),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await _processTransaction();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expenseToEdit != null;

    return Dialog(
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
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isEdit ? Icons.edit_outlined : Icons.receipt_long_rounded, color: Colors.orange.shade800),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEdit ? "Edit Expense" : "New Expense",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Item Name
                TextFormField(
                  controller: _titleController,
                  decoration: _buildInputDecoration("Item Name", "e.g., Dinner", Icons.shopping_bag_outlined),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: _buildInputDecoration("Amount", "0.00", Icons.attach_money),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // Date Picker Card
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, y').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Text("Change", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  decoration: _buildInputDecoration("Category", "", Icons.category_outlined),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                const SizedBox(height: 30),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _checkAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? "Update Transaction" : "Add Transaction"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.teal, width: 2)),
    );
  }
}