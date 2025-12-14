import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_helper.dart';
import '../../providers/theme_provider.dart'; // Import Theme Provider

class BudgetSummaryCard extends ConsumerWidget {
  final double monthlyBudget;
  final double totalSpent;

  const BudgetSummaryCard({
    super.key,
    required this.monthlyBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH THEME STATE
    final isDark = ref.watch(themeProvider);

    // 2. DEFINE DYNAMIC COLORS
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final shadowColor = isDark ? Colors.transparent : Colors.grey.shade200;
    final progressBarBase = isDark ? Colors.grey[800] : Colors.grey[100];

    // Logic
    final double remaining = monthlyBudget - totalSpent;
    final double progress = (monthlyBudget == 0) ? 0 : (totalSpent / monthlyBudget);
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final bool isOverBudget = totalSpent > monthlyBudget;

    // Color Logic
    Color statusColor;
    if (isOverBudget) {
      statusColor = Colors.red;
    } else if (progress > 0.85) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.teal;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Budget Usage", style: TextStyle(color: subTextColor, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: statusColor
                        ),
                      ),
                      Text(
                        " used",
                        style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOverBudget ? Icons.warning_amber_rounded : Icons.pie_chart_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Custom Progress Bar
          Stack(
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: progressBarBase,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withOpacity(0.7), statusColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Limit",
                  amount: monthlyBudget,
                  icon: Icons.account_balance_wallet_outlined,
                  color: isDark ? Colors.grey[300]! : Colors.grey.shade700,
                  bgColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                  subTextColor: subTextColor!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: "Spent",
                  amount: totalSpent,
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.orange.shade800,
                  bgColor: isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50,
                  subTextColor: subTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: "Left",
                  amount: remaining,
                  icon: Icons.savings_outlined,
                  color: remaining < 0 ? Colors.red : Colors.green,
                  bgColor: remaining < 0
                      ? (isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50)
                      : (isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50),
                  subTextColor: subTextColor,
                ),
              ),
            ],
          ),

          // Over Budget Warning
          if (isOverBudget) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You exceeded your budget by ${CurrencyHelper.format(totalSpent - monthlyBudget)}",
                      style: TextStyle(color: isDark ? Colors.red.shade200 : Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color subTextColor;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.8)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyHelper.format(amount),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}