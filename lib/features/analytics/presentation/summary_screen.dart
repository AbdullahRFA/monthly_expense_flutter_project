import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/expense_grouper.dart';
import '../data/summary_repository.dart';
import '../../expenses/domain/expense_model.dart';
import '../../providers/theme_provider.dart'; // Import Theme Provider

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalExpensesAsync = ref.watch(globalExpensesProvider);

    // 1. WATCH THEME STATE
    final isDark = ref.watch(themeProvider);

    // 2. DEFINE DYNAMIC COLORS
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.teal;
    final textColor = isDark ? Colors.white : Colors.white; // AppBar title is always white in this design
    final tabBarBg = isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade700;
    final tabBarIndicator = isDark ? Colors.teal : Colors.white;
    final tabBarLabel = isDark ? Colors.white : Colors.teal;
    final tabBarUnselected = isDark ? Colors.grey : Colors.teal.shade100;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text("Global Summary", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          backgroundColor: appBarColor,
          foregroundColor: textColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 40,
              decoration: BoxDecoration(
                color: tabBarBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: tabBarIndicator,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: tabBarLabel,
                unselectedLabelColor: tabBarUnselected,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Weekly Insights"),
                  Tab(text: "Yearly Overview"),
                ],
              ),
            ),
          ),
        ),
        body: globalExpensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return _buildEmptyState(isDark);
            }
            return TabBarView(
              children: [
                _WeeklyView(expenses: expenses),
                _YearlyView(expenses: expenses),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No Data Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text("Start spending to see insights.", style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey)),
        ],
      ),
    );
  }
}

class _WeeklyView extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const _WeeklyView({required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    // Colors
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final shadowColor = isDark ? Colors.transparent : Colors.grey.shade200;
    final dateBoxBg = isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50;
    final progressBase = isDark ? Colors.grey[800] : Colors.grey[100];

    final grouped = ExpenseGrouper.groupExpensesByWeek(expenses);
    final sortedKeys = grouped.keys.toList()..sort();

    // Calculate max for progress bars
    double maxSpend = 0;
    if (grouped.isNotEmpty) {
      maxSpend = grouped.values.reduce((a, b) => a > b ? a : b);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        // Reverse order (newest first)
        final key = sortedKeys[sortedKeys.length - 1 - index];
        final total = grouped[key]!;

        // Parse key "2025-W42"
        final parts = key.split('-');
        final year = parts[0];
        final week = parts.length > 1 ? parts[1] : "??";

        // Avoid division by zero
        final double relativeParams = maxSpend == 0 ? 0 : (total / maxSpend).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Date Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: dateBoxBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Week", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text(week.replaceAll('W', ''), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                      Text(year, style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Info & Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Spent", style: TextStyle(color: subTextColor, fontSize: 12)),
                          Text(
                            CurrencyHelper.format(total),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: relativeParams,
                          minHeight: 6,
                          backgroundColor: progressBase,
                          color: Colors.teal.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YearlyView extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const _YearlyView({required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    // Colors
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;
    final iconBg = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;

    final grouped = ExpenseGrouper.groupExpensesByYear(expenses);
    final sortedKeys = grouped.keys.toList()..sort();
    final lifetimeTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Lifetime Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF004D40), const Color(0xFF00695C)]
                  : [const Color(0xFF009688), const Color(0xFF4DB6AC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance, color: Colors.white70, size: 32),
              const SizedBox(height: 10),
              const Text("Lifetime Spending", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                CurrencyHelper.format(lifetimeTotal),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Across all wallets", style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text("Yearly Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),

        // Yearly List
        ...sortedKeys.map((year) {
          final total = grouped[year]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.orange),
              ),
              title: Text(year, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              trailing: Text(
                CurrencyHelper.format(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          );
        }),
      ],
    );
  }
}