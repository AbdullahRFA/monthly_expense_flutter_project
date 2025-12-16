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
import '../../providers/theme_provider.dart';
import 'transfer_wallet_dialog.dart'; // Import this
class WalletDetailScreen extends ConsumerWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider(wallet.id));
    final walletAsync = ref.watch(walletStreamProvider(wallet.id));

    // Get the latest wallet data (real-time balance)
    final currentWallet = walletAsync.value ?? wallet;

    // 1. Theme Data
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // 2. Negative Balance Logic
    final bool isNegative = currentWallet.currentBalance < 0;

    // 3. Dynamic Header Color
    final Color headerColor = isNegative
        ? (isDark ? const Color(0xFFB71C1C) : const Color(0xFFC62828)) // Dark Red (Dark Mode) vs Red (Light Mode)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.teal); // Dark Grey (Dark Mode) vs Teal (Light Mode)

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(currentWallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: headerColor, // Apply dynamic color
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded), // Transfer Icon
            tooltip: "Transfer Funds",
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (_) => TransferWalletDialog(initialSourceWalletId: currentWallet.id)
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Analytics",
            onPressed: () => _showAnalyticsBottomSheet(context, ref, currentWallet, isDark),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () => _exportPdf(context, ref, currentWallet),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddExpenseDialog(
              walletId: currentWallet.id,
              currentBalance: currentWallet.currentBalance,
            ),
          );
        },
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: isDark ? const Color(0xFF00695C) : Colors.teal, // Slightly darker in dark mode
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Modern Header Block with Negative Balance Support
          _buildHeader(currentWallet, isDark, headerColor, isNegative, isLoading: walletAsync.isLoading),

          // 2. Expense List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState(isDark);
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
                              color: subTextColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...dayExpenses.map((expense) {
                          return _buildExpenseTile(
                              context, ref, expense,
                              liveWallet: currentWallet,
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor
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

  Widget _buildHeader(WalletModel wallet, bool isDark, Color bgColor, bool isNegative, {bool isLoading = false}) {
    // Dynamic Shadow based on background color
    final shadowColor = isNegative
        ? Colors.red.withOpacity(0.3)
        : (isDark ? Colors.black26 : Colors.teal.withOpacity(0.4));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 5))],
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

          // Budget Pill
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

          // "Over Budget" Warning Pill (Visible only if negative)
          if (isNegative) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Over Budget",
                    style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildExpenseTile(
      BuildContext context,
      WidgetRef ref,
      dynamic expense,
      {required WalletModel liveWallet, required bool isDark, required Color cardColor, required Color textColor}) {

    final bool isRefund = expense.amount < 0;
    final double displayAmount = expense.amount.abs();
    final Color color = isRefund ? Colors.green : Colors.redAccent;
    final IconData icon = _getIconForCategory(expense.category);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade900,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cardColor,
            title: Text("Delete Transaction?", style: TextStyle(color: textColor)),
            content: Text("The amount will be refunded to your wallet.", style: TextStyle(color: textColor)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(expenseRepositoryProvider).deleteExpense(
            walletId: liveWallet.id, expenseId: expense.id, amount: expense.amount);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRefund
                  ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                  : (isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isRefund ? Colors.green : Colors.teal, size: 24),
          ),
          title: Text(expense.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          subtitle: Text(expense.category, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 12)),
          trailing: Text(
            "${isRefund ? '+' : '-'}${CurrencyHelper.format(displayAmount)}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AddExpenseDialog(
                walletId: liveWallet.id,
                currentBalance: liveWallet.currentBalance,
                expenseToEdit: expense,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No expenses yet", style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[500] : Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAnalyticsBottomSheet(BuildContext context, WidgetRef ref, WalletModel wallet, bool isDark) {
    final expensesState = ref.read(expenseListProvider(wallet.id));

    // Theme colors for Sheet
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                Text("Analytics Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 20),
                BudgetSummaryCard(monthlyBudget: wallet.monthlyBudget, totalSpent: totalSpent),
                const SizedBox(height: 20),
                SpendingTrendChart(expenses: allExpenses),
                const SizedBox(height: 20),
                Text("Category Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200)),
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