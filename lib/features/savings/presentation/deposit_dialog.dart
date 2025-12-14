import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet_model.dart';
import '../data/savings_repository.dart';
import '../../../core/utils/currency_helper.dart';

class DepositDialog extends ConsumerStatefulWidget {
  final String goalId;
  final String goalTitle;

  const DepositDialog({super.key, required this.goalId, required this.goalTitle});

  @override
  ConsumerState<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends ConsumerState<DepositDialog> {
  String? _selectedWalletId;
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Transfer Funds",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Move money from a wallet to your '${widget.goalTitle}' goal.",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // 1. Source Wallet Selector
              const Text("From Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              walletsAsync.when(
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text("No wallets available", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedWalletId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    hint: const Text("Select Source Wallet"),
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                w.name,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              CurrencyHelper.format(w.currentBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedWalletId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, s) => const Text("Error loading wallets"),
              ),
              const SizedBox(height: 20),

              // 2. Amount Input
              const Text("Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "0.00",
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
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
                    onPressed: _isLoading ? null : _transfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Confirm Transfer"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _transfer() async {
    if (_selectedWalletId == null || _amountController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(savingsRepositoryProvider).depositToGoal(
        walletId: _selectedWalletId!,
        goalId: widget.goalId,
        goalTitle: widget.goalTitle,
        amount: double.parse(_amountController.text.trim()),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}