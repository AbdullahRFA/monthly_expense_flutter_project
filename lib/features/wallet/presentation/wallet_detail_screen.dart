import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/data/expense_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/presentation/add_expense_dialog.dart';
import 'package:monthly_expense_flutter_project/core/utils/expense_grouper.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/category_pie_chart.dart';
import '../../../core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/core/utils/pdf_helper.dart'; // Make sure this is PdfHelper now
import 'package:monthly_expense_flutter_project/features/analytics/presentation/budget_summary_card.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/spending_trend_chart.dart';
class WalletDetailScreen extends ConsumerWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch Expenses List
    final expensesAsync = ref.watch(expenseListProvider(wallet.id));

    // 2. Watch Wallet Balance (Live!)
    final walletAsync = ref.watch(walletStreamProvider(wallet.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: "View Analytics",
            onPressed: () {
              final expensesState = ref.read(expenseListProvider(wallet.id));
              if (expensesState.hasValue) {
                final allExpenses = expensesState.value!;

                // Calculate Total Spent (Sum of all expenses)
                // Note: We include everything to show "Net Spent" position vs Budget
                final totalSpent = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allows sheet to be taller
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.85, // Opens to 85% height
                    maxChildSize: 0.95,
                    minChildSize: 0.5,
                    builder: (context, scrollController) => Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: ListView( // Changed to ListView for scrolling
                        controller: scrollController,
                        children: [
                          // Handle Bar
                          Center(
                            child: Container(
                              width: 50, height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                            ),
                          ),

                          const Text("Analytics Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 20),

                          // 1. BUDGET SUMMARY CARD
                          BudgetSummaryCard(
                            monthlyBudget: wallet.monthlyBudget,
                            totalSpent: totalSpent,
                          ),
                          const SizedBox(height: 20),

                          // 2. TREND CHART
                          SpendingTrendChart(expenses: allExpenses),
                          const SizedBox(height: 20),

                          // 3. CATEGORY PIE CHART
                          const Text("Category Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: CategoryPieChart(expenses: allExpenses),
                            ),
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),

          // --- EXPORT PDF BUTTON ---
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: () async {
              final expensesState = ref.read(expenseListProvider(wallet.id));

              if (expensesState.hasValue && expensesState.value!.isNotEmpty) {
                try {
                  // Call PDF Helper
                  await PdfHelper.generateAndPrint(expensesState.value!, wallet.name);
                } catch (e) {
                  debugPrint("PDF ERROR: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Export Failed: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No expenses to export!")),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Get the LATEST balance from the provider, fallback to the passed wallet's balance
          final currentBalance = walletAsync.value?.currentBalance ?? wallet.currentBalance;

          showDialog(
            context: context,
            builder: (_) => AddExpenseDialog(
              walletId: wallet.id,
              currentBalance: currentBalance,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // --- LIVE HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.teal.shade50,
            child: walletAsync.when(
              // Success: Show live data
              data: (liveWallet) {
                final balanceColor = liveWallet.currentBalance < 0 ? Colors.red : Colors.teal;

                return Column(
                  children: [
                    const Text("Current Balance", style: TextStyle(color: Colors.grey)),
                    Text(
                      CurrencyHelper.format(liveWallet.currentBalance),
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: balanceColor
                      ),
                    ),
                    Text("Monthly Budget: ${CurrencyHelper.format(liveWallet.monthlyBudget)}"),
                  ],
                );
              },
              // Loading
              loading: () => Column(
                children: [
                  const Text("Current Balance", style: TextStyle(color: Colors.grey)),
                  Text(
                    "${CurrencyHelper.format(wallet.currentBalance)}...",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Text("Monthly Budget: ${CurrencyHelper.format(wallet.monthlyBudget)}"),
                ],
              ),
              error: (err, stack) => Text("Error loading balance: $err"),
            ),
          ),

          // --- EXPENSE LIST ---
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(child: Text("No expenses yet. Spend some money!"));
                }
                final groupedMap = ExpenseGrouper.groupExpensesByDate(expenses);
                final dateKeys = groupedMap.keys.toList();

                return ListView.builder(
                  itemCount: dateKeys.length,
                  itemBuilder: (context, index) {
                    final dateKey = dateKeys[index];
                    final dayExpenses = groupedMap[dateKey]!;
                    final headerText = ExpenseGrouper.getNiceHeader(dateKey);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            headerText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                          ),
                        ),
                        ...dayExpenses.map((expense) {
                          // --- LOGIC FOR REFUND COLORS ---
                          final bool isRefund = expense.amount < 0;
                          final double displayAmount = expense.amount.abs();
                          final String sign = isRefund ? "+" : "-";
                          final Color color = isRefund ? Colors.green : Colors.red;
                          // -------------------------------

                          return Dismissible(
                            key: ValueKey(expense.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Expense?"),
                                  content: const Text("Money will be refunded to your wallet."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              ref.read(expenseRepositoryProvider).deleteExpense(
                                  walletId: wallet.id,
                                  expenseId: expense.id,
                                  amount: expense.amount
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRefund ? Colors.green.shade100 : Colors.teal.shade100,
                                  child: Icon(
                                      _getIconForCategory(expense.category),
                                      color: isRefund ? Colors.green : Colors.teal
                                  ),
                                ),
                                title: Text(expense.title),
                                subtitle: Text(expense.category),

                                // --- UPDATED TRAILING WIDGET ---
                                trailing: Text(
                                  "$sign${CurrencyHelper.format(displayAmount)}",
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                ),
                                // -------------------------------

                                onLongPress: () {
                                  final currentBalance = walletAsync.value?.currentBalance ?? wallet.currentBalance;
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddExpenseDialog(
                                      walletId: wallet.id,
                                      currentBalance: currentBalance,
                                      expenseToEdit: expense,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
    // Essentials
      case 'Food': return Icons.fastfood;
      case 'Groceries': return Icons.local_grocery_store;
      case 'Transport': return Icons.directions_bus;
      case 'Fuel': return Icons.local_gas_station;
      case 'Rent': return Icons.house;
      case 'Bills': return Icons.receipt_long; // Electricity, Water, Gas
      case 'Education': return Icons.school;

    // Lifestyle
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Personal Care': return Icons.content_cut; // Barber/Salon
      case 'Pets': return Icons.pets;
      case 'Travel': return Icons.flight;
      case 'Gifts': return Icons.card_giftcard;

    // Health & Family
      case 'Health': return Icons.local_hospital;
      case 'Family': return Icons.family_restroom;

    // Financial & Obligations
      case 'Donation': return Icons.volunteer_activism; // Charity/Zakat
      case 'Loan': return Icons.account_balance; // Debt repayment
      case 'Investment': return Icons.trending_up; // Stocks/Business
      case 'Savings': return Icons.savings;

    // Maintenance & Misc
      case 'Repairs': return Icons.build;
      case 'Others': return Icons.category;

      default: return Icons.attach_money;
    }
  }
}