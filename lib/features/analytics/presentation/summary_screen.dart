import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/expense_grouper.dart';
import '../data/summary_repository.dart';
import '../../expenses/domain/expense_model.dart'; // Import ExpenseModel

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalExpensesAsync = ref.watch(globalExpensesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Global Summary"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Weekly"),
              Tab(text: "Yearly"),
            ],
          ),
        ),
        body: globalExpensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return const Center(child: Text("No expenses recorded anywhere."));
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
}

// --- TAB 1: WEEKLY VIEW ---
class _WeeklyView extends StatelessWidget {
  // FIX: Use List<ExpenseModel> instead of dynamic
  final List<ExpenseModel> expenses;

  const _WeeklyView({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // FIX: No casting needed now
    final grouped = ExpenseGrouper.groupExpensesByWeek(expenses);
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        // Show newest weeks at the top
        final key = sortedKeys[sortedKeys.length - 1 - index];
        final total = grouped[key]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.calendar_view_week, color: Colors.teal),
            ),
            title: Text(key), // e.g., "2025-W42"
            subtitle: const Text("Total Spent"),
            trailing: Text(
              CurrencyHelper.format(total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}

// --- TAB 2: YEARLY VIEW ---
class _YearlyView extends StatelessWidget {
  // FIX: Use List<ExpenseModel> instead of dynamic
  final List<ExpenseModel> expenses;

  const _YearlyView({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // FIX: No casting needed now
    final grouped = ExpenseGrouper.groupExpensesByYear(expenses);
    final sortedKeys = grouped.keys.toList()..sort();

    // Calculate Grand Total Lifetime
    final lifetimeTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Lifetime Card
        Card(
          color: Colors.teal,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Lifetime Spending", style: TextStyle(color: Colors.white70)),
                Text(
                  CurrencyHelper.format(lifetimeTotal),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text("(Across all wallets)", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Yearly Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // List of Years
        ...sortedKeys.map((year) {
          final total = grouped[year]!;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, size: 32, color: Colors.orange),
              title: Text(year, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                CurrencyHelper.format(total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
              ),
            ),
          );
        }).toList(), // Remove the incorrect cast here too if it existed
      ],
    );
  }
}