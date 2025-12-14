import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/features/auth/data/auth_repository.dart';
import 'package:monthly_expense_flutter_project/features/settings/presentation/settings_screen.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/add_wallet_dialog.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/wallet_detail_screen.dart';
import 'package:monthly_expense_flutter_project/features/savings/presentation/savings_list_screen.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/summary_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletListAsync = ref.watch(walletListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100], // Softer background
      appBar: AppBar(
        title: const Text("My Wallets", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddWalletDialog());
        },
        label: const Text("New Wallet"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: walletListAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGroupedWalletList(context, ref, wallets);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  // --- 1. GROUPING LOGIC ---
  Widget _buildGroupedWalletList(BuildContext context, WidgetRef ref, List<WalletModel> wallets) {
    // Helper to generate group keys
    String getGroupKey(WalletModel wallet) {
      final now = DateTime.now();
      if (wallet.year == now.year && wallet.month == now.month) {
        return "Current Month";
      } else if (wallet.year == now.year && wallet.month == now.month - 1) {
        return "Last Month";
      } else {
        // e.g., "October 2025"
        final date = DateTime(wallet.year, wallet.month);
        return DateFormat('MMMM yyyy').format(date);
      }
    }

    // Organize wallets into a Map
    final Map<String, List<WalletModel>> grouped = {};
    for (var wallet in wallets) {
      final key = getGroupKey(wallet);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(wallet);
    }

    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final key = groupKeys[index];
        final groupWallets = grouped[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                key.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Wallet Cards
            ...groupWallets.map((wallet) => _WalletCard(wallet: wallet, ref: ref)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No wallets yet",
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Create a monthly budget to get started.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.teal,
              image: DecorationImage(
                image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Subtle pattern
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            accountName: const Text("Monthly Expense", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            accountEmail: const Text("Track your wealth"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.account_balance_wallet, color: Colors.teal, size: 35),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.savings, color: Colors.green),
            title: const Text("Savings Goals"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded, color: Colors.purple),
            title: const Text("Global Summary"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- 2. MODERN WALLET CARD ---
class _WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final WidgetRef ref;

  const _WalletCard({required this.wallet, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    final double progress = (wallet.monthlyBudget == 0)
        ? 0
        : (wallet.monthlyBudget - wallet.currentBalance) / wallet.monthlyBudget;

    // Clamp progress between 0 and 1
    final double safeProgress = progress.clamp(0.0, 1.0);

    // Dynamic Colors based on balance status
    final bool isLowBalance = wallet.currentBalance < (wallet.monthlyBudget * 0.2);
    final bool isNegative = wallet.currentBalance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet)));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Name and Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime(wallet.year, wallet.month)),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    _buildPopupMenu(context, ref, wallet),
                  ],
                ),

                const SizedBox(height: 20),

                // Middle Row: Balance
                Text("Current Balance", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Row(
                  children: [
                    Text(
                      CurrencyHelper.format(wallet.currentBalance),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isNegative ? Colors.red : Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Bottom Row: Budget Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0 - safeProgress, // Fill represents remaining money
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    color: isNegative ? Colors.red : (isLowBalance ? Colors.orange : Colors.green),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Spent: ${CurrencyHelper.format(wallet.monthlyBudget - wallet.currentBalance)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      "Limit: ${CurrencyHelper.format(wallet.monthlyBudget)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref, WalletModel wallet) {
    return PopupMenuButton(
      icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          showDialog(context: context, builder: (_) => AddWalletDialog(walletToEdit: wallet));
        } else if (value == 'delete') {
          _confirmDelete(context, ref, wallet);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Edit")])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WalletModel wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Wallet?"),
        content: const Text("This cannot be undone. All expenses in this wallet will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
                Navigator.pop(ctx);
              },
              child: const Text("Delete")
          ),
        ],
      ),
    );
  }
}