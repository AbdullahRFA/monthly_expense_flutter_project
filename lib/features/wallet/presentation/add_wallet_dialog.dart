import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
import '../../providers/theme_provider.dart';

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

  String? _selectedRolloverWalletId;
  String? _selectedRolloverWalletName;
  double _rolloverAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.walletToEdit?.name ?? '');
    _amountController = TextEditingController(text: widget.walletToEdit?.monthlyBudget.toString() ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final budget = double.parse(_amountController.text.trim());
      final name = _nameController.text.trim();
      String? newId;

      if (widget.walletToEdit == null) {
        newId = await ref.read(walletRepositoryProvider).addWallet(
          name: name,
          monthlyBudget: budget,
          rolloverAmount: _rolloverAmount,
          sourceWalletId: _selectedRolloverWalletId,
          sourceWalletName: _selectedRolloverWalletName,
        );
      } else {
        await ref.read(walletRepositoryProvider).updateWallet(
            oldWallet: widget.walletToEdit!, newName: name, newBudget: budget);
      }
      if (mounted) Navigator.pop(context, newId); // Return the ID
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletListAsync = ref.watch(walletListProvider);
    final isEdit = widget.walletToEdit != null;
    final isDark = ref.watch(themeProvider);
    final dialogColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(isDark ? 0.2 : 0.1), shape: BoxShape.circle),
                        child: Icon(isEdit ? Icons.edit_note_rounded : Icons.account_balance_wallet_rounded, color: Colors.teal),
                      ),
                      const SizedBox(width: 15),
                      Text(isEdit ? "Edit Wallet" : "New Budget", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: "Wallet Name", filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: "Monthly Limit", filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 24),

                  if (!isEdit) ...[
                    walletListAsync.when(
                      data: (wallets) {
                        if(wallets.isEmpty) return const SizedBox.shrink();
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: "Rollover From (Optional)", filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
                          items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                          onChanged: (val) {
                            final w = wallets.firstWhere((element) => element.id == val);
                            setState(() { _selectedRolloverWalletId = val; _rolloverAmount = w.currentBalance; _selectedRolloverWalletName = w.name; });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_,__) => const SizedBox(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? "Save Changes" : "Create Wallet"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}