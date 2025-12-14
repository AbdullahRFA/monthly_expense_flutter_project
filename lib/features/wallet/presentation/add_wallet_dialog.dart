import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';

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

  // Variables for Rollover
  String? _selectedRolloverWalletId;
  String? _selectedRolloverWalletName; // To store name for the history record
  double _rolloverAmount = 0.0;

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
        // ADD (With Rollover Transaction)
        await ref.read(walletRepositoryProvider).addWallet(
          name: name,
          monthlyBudget: budget,
          rolloverAmount: _rolloverAmount,
          sourceWalletId: _selectedRolloverWalletId,
          sourceWalletName: _selectedRolloverWalletName,
        );
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
    final walletListAsync = ref.watch(walletListProvider);

    return AlertDialog(
      title: Text(widget.walletToEdit == null ? "Create Wallet" : "Edit Wallet"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Wallet Name (e.g. November)"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Monthly Budget"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),

              // --- ROLLOVER SECTION ---
              if (widget.walletToEdit == null) ...[
                const Divider(),
                const Text(
                  "Rollover Balance (Optional)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
                ),
                const SizedBox(height: 10),

                walletListAsync.when(
                  data: (wallets) {
                    if (wallets.isEmpty) return const SizedBox.shrink();

                    return DropdownButtonFormField<String>(
                      value: _selectedRolloverWalletId,
                      decoration: const InputDecoration(
                        labelText: "Select Source Wallet",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: wallets.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(
                              "${w.name} (${CurrencyHelper.format(w.currentBalance)})",
                              overflow: TextOverflow.ellipsis
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRolloverWalletId = val;
                          final selectedWallet = wallets.firstWhere((w) => w.id == val);
                          _selectedRolloverWalletName = selectedWallet.name;
                          _rolloverAmount = selectedWallet.currentBalance;
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text("Could not load wallets"),
                ),

                if (_selectedRolloverWalletId != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Starting Balance:"),
                        Text(
                          CurrencyHelper.format((double.tryParse(_amountController.text) ?? 0) + _rolloverAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ],
          ),
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