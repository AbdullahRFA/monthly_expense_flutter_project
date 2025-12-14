import 'package:flutter/material.dart';
import '../../../core/utils/currency_helper.dart';

class BudgetSummaryCard extends StatelessWidget {
  final double monthlyBudget;
  final double totalSpent;

  const BudgetSummaryCard({
    super.key,
    required this.monthlyBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate logic
    final double remaining = monthlyBudget - totalSpent;
    final double progress = (monthlyBudget == 0) ? 0 : (totalSpent / monthlyBudget).clamp(0.0, 1.0);
    final bool isOverBudget = totalSpent > monthlyBudget;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Budget Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.grey.shade200,
              // Green if safe, Orange if close (80%), Red if over
              color: isOverBudget ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.green),
            ),
            const SizedBox(height: 15),

            // Text Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: "Budget", amount: monthlyBudget, color: Colors.black),
                _StatItem(label: "Spent", amount: totalSpent, color: isOverBudget ? Colors.red : Colors.orange.shade800),
                _StatItem(label: "Remaining", amount: remaining, color: remaining < 0 ? Colors.red : Colors.green),
              ],
            ),

            // Warning Text
            if (isOverBudget) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Over budget by ${CurrencyHelper.format(totalSpent - monthlyBudget)}!",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(CurrencyHelper.format(amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}