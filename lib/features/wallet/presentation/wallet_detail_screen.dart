import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/data/expense_repository.dart';
import 'package:monthly_expense_flutter_project/features/expenses/presentation/add_expense_dialog.dart';
import 'package:monthly_expense_flutter_project/core/utils/expense_grouper.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/category_pie_chart.dart';
import '../../../core/utils/currency_helper.dart';
// import 'package:monthly_expense_flutter_project/core/utils/csv_helper.dart';
import 'package:monthly_expense_flutter_project/core/utils/pdf_helper.dart';
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
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Container(
                    padding: const EdgeInsets.all(16),
                    height: 400,
                    child: Column(
                      children: [
                        const Text("Spending Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        CategoryPieChart(expenses: expensesState.value!),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // --- EXPORT CSV BUTTON (FIXED) ---
          // IconButton(
          //   icon: const Icon(Icons.download),
          //   tooltip: "Export CSV",
          //   onPressed: () async { // <--- 1. Marked ASYNC
          //     final expensesState = ref.read(expenseListProvider(wallet.id));
          //
          //     if (expensesState.hasValue && expensesState.value!.isNotEmpty) {
          //       try {
          //         // <--- 2. Try to Export
          //         await CsvHelper.exportExpenses(expensesState.value!);
          //
          //         if (context.mounted) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text("Export successful!"), backgroundColor: Colors.green),
          //           );
          //         }
          //       } catch (e, stack) {
          //         // <--- 3. CATCH & PRINT ERROR
          //         debugPrint("CSV EXPORT ERROR: $e");
          //         debugPrint(stack.toString());
          //
          //         if (context.mounted) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             SnackBar(content: Text("Export Failed: $e"), backgroundColor: Colors.red),
          //           );
          //         }
          //       }
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text("No expenses to export!")),
          //       );
          //     }
          //   },
          // ),

          // ... inside AppBar actions ...

          // PDF EXPORT BUTTON
          IconButton(
            icon: const Icon(Icons.picture_as_pdf), // Changed Icon
            tooltip: "Export PDF",
            onPressed: () async {
              final expensesState = ref.read(expenseListProvider(wallet.id));

              if (expensesState.hasValue && expensesState.value!.isNotEmpty) {
                try {
                  // Call the new PDF Helper
                  // We pass the list AND the wallet name for the report title
                  await PdfHelper.generateAndPrint(expensesState.value!, wallet.name);

                } catch (e) {
                  debugPrint("PDF ERROR: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red),
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
                                  backgroundColor: Colors.teal.shade100,
                                  child: Icon(_getIconForCategory(expense.category), color: Colors.teal),
                                ),
                                title: Text(expense.title),
                                subtitle: Text(expense.category),
                                trailing: Text(
                                  "-${expense.amount}",
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
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
      case 'Food': return Icons.fastfood;
      case 'Transport': return Icons.directions_bus;
      case 'Bills': return Icons.receipt;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.local_hospital;
      default: return Icons.attach_money;
    }
  }
}