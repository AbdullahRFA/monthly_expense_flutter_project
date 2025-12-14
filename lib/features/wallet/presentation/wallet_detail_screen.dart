import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/data/expense_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/presentation/add_expense_dialog.dart';
import 'package:monthly_expense_flutter_project/core/utils/expense_grouper.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/category_pie_chart.dart';
import '../../../core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/core/utils/pdf_helper.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/budget_summary_card.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/spending_trend_chart.dart';

class WalletDetailScreen extends ConsumerWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider(wallet.id));
    final walletAsync = ref.watch(walletStreamProvider(wallet.id));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Analytics",
            onPressed: () => _showAnalyticsBottomSheet(context, ref, wallet),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () => _exportPdf(context, ref, wallet),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentBalance = walletAsync.value?.currentBalance ?? wallet.currentBalance;
          showDialog(
            context: context,
            builder: (_) => AddExpenseDialog(
              walletId: wallet.id,
              currentBalance: currentBalance,
            ),
          );
        },
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Modern Header Block
          walletAsync.when(
            data: (liveWallet) => _buildHeader(liveWallet),
            loading: () => _buildHeader(wallet, isLoading: true),
            error: (e, s) => Container(padding: const EdgeInsets.all(20), child: Text("Error: $e")),
          ),

          // 2. Expense List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState();
                }
                final groupedMap = ExpenseGrouper.groupExpensesByDate(expenses);
                final dateKeys = groupedMap.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, index) {
                    final dateKey = dateKeys[index];
                    final dayExpenses = groupedMap[dateKey]!;
                    final headerText = ExpenseGrouper.getNiceHeader(dateKey);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Text(
                            headerText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...dayExpenses.map((expense) {
                          return _buildExpenseTile(context, ref, expense, liveWallet: walletAsync.value ?? wallet);
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

  Widget _buildHeader(WalletModel wallet, {bool isLoading = false}) {
    final balanceColor = wallet.currentBalance < 0 ? Colors.red.shade100 : Colors.teal.shade700;
    final bgColor = wallet.currentBalance < 0 ? Colors.red.shade900 : Colors.teal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            isLoading ? "..." : CurrencyHelper.format(wallet.currentBalance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Monthly Budget: ${CurrencyHelper.format(wallet.monthlyBudget)}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, WidgetRef ref, dynamic expense, {required WalletModel liveWallet}) {
    final bool isRefund = expense.amount < 0;
    final double displayAmount = expense.amount.abs();
    final Color color = isRefund ? Colors.green : Colors.redAccent;
    final IconData icon = _getIconForCategory(expense.category);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Transaction?"),
            content: const Text("The amount will be refunded to your wallet."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(expenseRepositoryProvider).deleteExpense(
            walletId: wallet.id, expenseId: expense.id, amount: expense.amount);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRefund ? Colors.green.shade50 : Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isRefund ? Colors.green : Colors.teal, size: 24),
          ),
          title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(expense.category, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          trailing: Text(
            "${isRefund ? '+' : '-'}${CurrencyHelper.format(displayAmount)}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AddExpenseDialog(
                walletId: wallet.id,
                currentBalance: liveWallet.currentBalance,
                expenseToEdit: expense,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No expenses yet", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAnalyticsBottomSheet(BuildContext context, WidgetRef ref, WalletModel wallet) {
    final expensesState = ref.read(expenseListProvider(wallet.id));
    if (expensesState.hasValue) {
      final allExpenses = expensesState.value!;
      final totalSpent = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24, top: 8),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Text("Analytics Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                BudgetSummaryCard(monthlyBudget: wallet.monthlyBudget, totalSpent: totalSpent),
                const SizedBox(height: 20),
                SpendingTrendChart(expenses: allExpenses),
                const SizedBox(height: 20),
                const Text("Category Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CategoryPieChart(expenses: allExpenses),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, WalletModel wallet) async {
    final expensesState = ref.read(expenseListProvider(wallet.id));
    if (expensesState.hasValue && expensesState.value!.isNotEmpty) {
      try {
        await PdfHelper.generateAndPrint(expensesState.value!, wallet.name);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Failed: $e"), backgroundColor: Colors.red));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No expenses to export!")));
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood_rounded;
      case 'Groceries': return Icons.local_grocery_store_rounded;
      case 'Transport': return Icons.directions_bus_rounded;
      case 'Fuel': return Icons.local_gas_station_rounded;
      case 'Rent': return Icons.house_rounded;
      case 'Bills': return Icons.receipt_long_rounded;
      case 'Education': return Icons.school_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Entertainment': return Icons.movie_rounded;
      case 'Personal Care': return Icons.face_rounded;
      case 'Pets': return Icons.pets_rounded;
      case 'Travel': return Icons.flight_takeoff_rounded;
      case 'Gifts': return Icons.card_giftcard_rounded;
      case 'Health': return Icons.local_hospital_rounded;
      case 'Family': return Icons.family_restroom_rounded;
      case 'Donation': return Icons.volunteer_activism_rounded;
      case 'Loan': return Icons.account_balance_rounded;
      case 'Investment': return Icons.trending_up_rounded;
      case 'Savings': return Icons.savings_rounded;
      case 'Repairs': return Icons.build_rounded;
      default: return Icons.attach_money_rounded;
    }
  }
}