import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import '../../providers/theme_provider.dart';
import '../data/savings_repository.dart';
import '../domain/savings_goal_model.dart';
import 'add_goal_dialog.dart';
import 'deposit_dialog.dart';
import 'withdraw_goal_dialog.dart';

class SavingsListScreen extends ConsumerWidget {
  const SavingsListScreen({super.key});

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String goalId, double currentSaved, bool isDark) {
    String? selectedWalletId;

    // Dynamic Colors for Dialog
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final containerColor = isDark ? Colors.teal.withOpacity(0.1) : Colors.teal.shade50;
    final borderColor = isDark ? Colors.teal.withOpacity(0.3) : Colors.teal.shade100;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final walletsAsync = ref.watch(walletListProvider);

          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Delete Goal?", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Are you sure you want to delete this goal?", style: TextStyle(color: textColor)),
                const SizedBox(height: 15),
                if (currentSaved > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Refund: ${CurrencyHelper.format(currentSaved)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text("Select a wallet to receive funds:", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  walletsAsync.when(
                    data: (wallets) {
                      if (wallets.isEmpty) return Text("No wallets found to refund.", style: TextStyle(color: textColor));
                      if (selectedWalletId == null && wallets.isNotEmpty) {
                        selectedWalletId = wallets.first.id;
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedWalletId,
                        isExpanded: true,
                        dropdownColor: cardColor,
                        decoration: InputDecoration(
                          labelText: "Refund To",
                          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade600)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: TextStyle(color: textColor),
                        items: wallets.map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name, style: TextStyle(color: textColor)),
                        )).toList(),
                        onChanged: (val) => setState(() => selectedWalletId = val),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text("Error: $e", style: TextStyle(color: textColor)),
                  ),
                ] else ...[
                  Text(
                    "This goal has no funds. It will be deleted permanently.",
                    style: TextStyle(color: textColor.withOpacity(0.6), fontStyle: FontStyle.italic),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.7))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ref.read(savingsRepositoryProvider).deleteGoal(
                    goalId: goalId,
                    refundWalletId: selectedWalletId,
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
    final isDark = ref.watch(themeProvider);

    // Dynamic Colors
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final shadowColor = isDark ? Colors.transparent : Colors.teal.withOpacity(0.08);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Savings Goals", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("New Goal"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => showDialog(
            context: context,
            builder: (_) => const AddGoalDialog()
        ),
      ),
      body: savingsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Dream Big!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: subTextColor)),
                  const SizedBox(height: 8),
                  Text("Create a goal to start saving.", style: TextStyle(color: subTextColor)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _SavingsGoalCard(
                goal: goals[index],
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor!,
                shadowColor: shadowColor,
                onDelete: () => _showDeleteDialog(context, ref, goals[index].id, goals[index].currentSaved, isDark),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: textColor))),
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback onDelete;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color shadowColor;

  const _SavingsGoalCard({
    required this.goal,
    required this.onDelete,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (goal.targetAmount == 0) ? 0.0 : (goal.currentSaved / goal.targetAmount).clamp(0.0, 1.0);
    final String percentage = (progress * 100).toStringAsFixed(1);
    final bool isCompleted = progress >= 1.0;

    final iconBgColor = isCompleted
        ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
        : (isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.track_changes,
                    color: isCompleted ? Colors.green : Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Target: ${DateFormat('MMM d, y').format(goal.deadline)}",
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: subTextColor.withOpacity(0.5)),
                  onPressed: onDelete,
                )
              ],
            ),
            const SizedBox(height: 20),

            // Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Saved", style: TextStyle(fontSize: 12, color: subTextColor)),
                    Text(
                      CurrencyHelper.format(goal.currentSaved),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Goal", style: TextStyle(fontSize: 12, color: subTextColor)),
                    Text(
                      CurrencyHelper.format(goal.targetAmount),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : (progress > 0.5 ? Colors.teal : Colors.orange),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (progress > 0.5 ? Colors.teal : Colors.orange).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$percentage% Completed",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor),
              ),
            ),

            const SizedBox(height: 20),

            // ACTION BUTTONS (Withdraw & Deposit)
            Row(
              children: [
                // Withdraw Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: const Text("Withdraw"),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => WithdrawGoalDialog(
                              goalId: goal.id,
                              goalTitle: goal.title,
                              currentSaved: goal.currentSaved
                          )
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Deposit Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: const Text("Deposit"),
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
          ],
        ),
      ),
    );
  }
}