import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/expense_grouper.dart';
import '../data/summary_repository.dart';
import '../../expenses/domain/expense_model.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalExpensesAsync = ref.watch(globalExpensesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Modern light background
        appBar: AppBar(
          title: const Text("Global Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.teal.shade100,
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
              return _buildEmptyState();
            }
            return TabBarView(
              children: [
                _WeeklyView(expenses: expenses),
                _YearlyView(expenses: expenses),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e")),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No Data Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text("Start spending to see insights.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _WeeklyView extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const _WeeklyView({required this.expenses});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4)),
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
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(week, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
                          const Text("Total Spent", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            CurrencyHelper.format(total),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: relativeParams,
                          minHeight: 6,
                          backgroundColor: Colors.grey[100],
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

class _YearlyView extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const _YearlyView({required this.expenses});

  @override
  Widget build(BuildContext context) {
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
            gradient: const LinearGradient(
              colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
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
        const Text("Yearly Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),

        // Yearly List
        ...sortedKeys.map((year) {
          final total = grouped[year]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.orange),
              ),
              title: Text(year, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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