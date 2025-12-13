import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';

class AddWalletDialog extends ConsumerStatefulWidget {
  final WalletModel? walletToEdit;

  const AddWalletDialog({super.key, this.walletToEdit});

  @override
  ConsumerState<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends ConsumerState<AddWalletDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.walletToEdit?.name ?? 'Main Wallet');
    _amountController = TextEditingController(text: widget.walletToEdit?.monthlyBudget.toString() ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final budget = double.parse(_amountController.text.trim());
      final name = _nameController.text.trim();

      if (widget.walletToEdit == null) {
        // ADD
        await ref.read(walletRepositoryProvider).addWallet(name: name, monthlyBudget: budget);
      } else {
        // EDIT
        await ref.read(walletRepositoryProvider).updateWallet(
            oldWallet: widget.walletToEdit!,
            newName: name,
            newBudget: budget
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
    return AlertDialog(
      title: Text(widget.walletToEdit == null ? "Create Wallet" : "Edit Wallet"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Wallet Name")),
            const SizedBox(height: 10),
            TextFormField(controller: _amountController, decoration: const InputDecoration(labelText: "Budget Amount")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator() : Text(widget.walletToEdit == null ? "Create" : "Update"),
        ),
      ],
    );
  }
}