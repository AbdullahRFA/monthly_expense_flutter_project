import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/savings/data/savings_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/add_wallet_dialog.dart';
import '../../providers/theme_provider.dart';

class WithdrawGoalDialog extends ConsumerStatefulWidget {
  final String goalId;
  final String goalTitle;
  final double currentSaved;

  const WithdrawGoalDialog({super.key, required this.goalId, required this.goalTitle, required this.currentSaved});

  @override
  ConsumerState<WithdrawGoalDialog> createState() => _WithdrawGoalDialogState();
}

class _WithdrawGoalDialogState extends ConsumerState<WithdrawGoalDialog> {
  String? _destWalletId;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    if (amount > widget.currentSaved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot withdraw more than saved amount")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(savingsRepositoryProvider).withdrawFromGoal(
        goalId: widget.goalId,
        goalTitle: widget.goalTitle,
        walletId: _destWalletId!,
        amount: amount,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletListProvider);
    final isDark = ref.watch(themeProvider);
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFill = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50];

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Withdraw Funds", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text("From: ${widget.goalTitle}", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
                const SizedBox(height: 20),
                walletsAsync.when(
                  data: (wallets) => DropdownButtonFormField<String>(
                    value: _destWalletId,
                    dropdownColor: dialogBg,
                    decoration: InputDecoration(labelText: "To Wallet", filled: true, fillColor: inputFill),
                    items: [
                      ...wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, style: TextStyle(color: textColor)))),
                      DropdownMenuItem(value: "CREATE_NEW", child: Text("+ Create New Wallet", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)))
                    ],
                    onChanged: (val) async {
                      if (val == "CREATE_NEW") {
                        final newId = await showDialog<String>(context: context, builder: (_) => const AddWalletDialog());
                        if (newId != null) setState(() => _destWalletId = newId);
                        else setState(() => _destWalletId = null);
                      } else {
                        setState(() => _destWalletId = val);
                      }
                    },
                    validator: (v) => v == null || v == "CREATE_NEW" ? "Required" : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text("Error loading wallets"),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(labelText: "Amount (Max ${widget.currentSaved})", filled: true, fillColor: inputFill),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _withdraw,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Withdraw"),
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