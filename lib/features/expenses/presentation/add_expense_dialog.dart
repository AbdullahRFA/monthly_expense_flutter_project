import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/expenses/data/expense_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/domain/expense_model.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final String walletId;
  final ExpenseModel? expenseToEdit;

  const AddExpenseDialog({super.key, required this.walletId, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Health'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();

      if (widget.expenseToEdit == null) {
        // --- ADD MODE ---
        await ref.read(expenseRepositoryProvider).addExpense(
          walletId: widget.walletId,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: DateTime.now(),
        );
      } else {
        // --- EDIT MODE ---
        final newExpense = ExpenseModel(
          id: widget.expenseToEdit!.id,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: widget.expenseToEdit!.date,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? "Edit Expense" : "Add New Expense"),
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
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator() : Text(isEditing ? "Update" : "Add"),
        ),
      ],
    );
  }
}