import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
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

  late DateTime _selectedDate; // Variable to store the picked date

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Health'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Initialize Date: Use existing date if editing, otherwise Today
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

  // 2. Logic to Show Calendar
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Cannot pick future dates
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
        // ADD
        await ref.read(expenseRepositoryProvider).addExpense(
          walletId: widget.walletId,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate, // <--- USE SELECTED DATE
        );
      } else {
        // EDIT
        final newExpense = ExpenseModel(
          id: widget.expenseToEdit!.id,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate, // <--- USE SELECTED DATE
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

    // Calculate the actual impact on the wallet
    double impact = amount;
    if (widget.expenseToEdit != null) {
      impact = amount - widget.expenseToEdit!.amount;
    }

    // CHECK: Is the impact greater than available money?
    if (impact > widget.currentBalance) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Insufficient Balance", style: TextStyle(color: Colors.red)),
          content: Text(
              "You are trying to spend ৳$amount but you only have ৳${widget.currentBalance}.\n\n"
                  "This will result in a negative balance. Continue?"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Proceed Anyway"),
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
    return AlertDialog(
      title: Text(widget.expenseToEdit == null ? "Add New Expense" : "Edit Expense"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Item Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),

              // --- 3. DATE PICKER ROW ---
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Date: ${DateFormat('MMM d, y').format(_selectedDate)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Change"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ----------------------------

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _checkAndSave,
          child: _isLoading ? const CircularProgressIndicator() : Text(widget.expenseToEdit == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}