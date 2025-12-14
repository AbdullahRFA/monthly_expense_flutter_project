import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart'; // Import Wallet Repo
import '../data/savings_repository.dart';
import 'add_goal_dialog.dart';
import 'deposit_dialog.dart';

class SavingsListScreen extends ConsumerWidget {
  const SavingsListScreen({super.key});

  // Helper to show the Delete/Refund Dialog
  void _showDeleteDialog(BuildContext context, WidgetRef ref, String goalId, double currentSaved) {
    String? selectedWalletId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder allows us to update the Dropdown inside the Dialog
        builder: (context, setState) {
          final walletsAsync = ref.watch(walletListProvider);

          return AlertDialog(
            title: const Text("Delete Goal?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Are you sure you want to delete this goal?"),
                const SizedBox(height: 10),

                // IF money exists, show refund options
                if (currentSaved > 0) ...[
                  Text(
                    "You have ${CurrencyHelper.format(currentSaved)} saved.\nSelect a wallet to refund this amount:",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 10),
                  walletsAsync.when(
                    data: (wallets) {
                      if (wallets.isEmpty) return const Text("No wallets found to refund.");

                      // Auto-select the first wallet if none selected
                      if (selectedWalletId == null && wallets.isNotEmpty) {
                        selectedWalletId = wallets.first.id;
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedWalletId,
                        isExpanded: true,
                        items: wallets.map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => selectedWalletId = val);
                        },
                        decoration: const InputDecoration(
                          labelText: "Refund To",
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text("Error loading wallets: $e"),
                  ),
                ] else ...[
                  const Text("This goal has no funds, so it will simply be deleted.", style: TextStyle(color: Colors.grey)),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () {
                  // Perform Delete
                  ref.read(savingsRepositoryProvider).deleteGoal(
                    goalId: goalId,
                    refundWalletId: selectedWalletId, // Pass the ID (null if 0 saved)
                  );
                  Navigator.pop(ctx);
                },
                child: Text(currentSaved > 0 ? "Refund & Delete" : "Delete"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Goals")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("New Goal"),
        onPressed: () => showDialog(
            context: context,
            builder: (_) => const AddGoalDialog()
        ),
      ),
      body: savingsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Text("No goals yet. Dream big!", style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = (goal.targetAmount == 0) ? 0.0 : (goal.currentSaved / goal.targetAmount).clamp(0.0, 1.0);
              final percentage = (progress * 100).toStringAsFixed(1);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title and Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(goal.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              // CALL OUR NEW DIALOG
                              _showDeleteDialog(context, ref, goal.id, goal.currentSaved);
                            },
                          )
                        ],
                      ),

                      Text(
                        "Target: ${DateFormat('MMM d, y').format(goal.deadline)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 15),

                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${CurrencyHelper.format(goal.currentSaved)} / ${CurrencyHelper.format(goal.targetAmount)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("$percentage%", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text("Deposit Funds"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => DepositDialog(goalId: goal.id, goalTitle: goal.title),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}