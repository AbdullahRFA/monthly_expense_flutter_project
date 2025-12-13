import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
import 'package:monthly_expense_flutter_project/features/auth/data/auth_repository.dart';
import 'package:monthly_expense_flutter_project/features/settings/presentation/settings_screen.dart';
import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/add_wallet_dialog.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/wallet_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the wallet list (Real-time!)
    final walletListAsync = ref.watch(walletListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallets"),
      ),
      // SIDE DRAWER (Settings & Logout)
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(
                  "Monthly Expense",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context); // Close drawer first
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (_) => const AddWalletDialog()
          );
        },
        child: const Icon(Icons.add),
      ),
      body: walletListAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(child: Text("No wallets yet. Create one!"));
          }
          return ListView.builder(
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(wallet.name),
                  subtitle: Text("Budget: ${CurrencyHelper.format(wallet.monthlyBudget)}"),

                  // --- THE 3-DOT MENU SECTION ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Vital to prevent layout errors
                    children: [
                      // Balance Text
                      Text(
                        "Bal: ${CurrencyHelper.format(wallet.currentBalance)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),

                      // The Menu Button
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert), // The 3 dots icon
                        onSelected: (value) {
                          if (value == 'edit') {
                            showDialog(
                                context: context,
                                builder: (_) => AddWalletDialog(walletToEdit: wallet)
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Wallet?"),
                                content: const Text("This cannot be undone."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                  TextButton(
                                      onPressed: () {
                                        ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("Delete", style: TextStyle(color: Colors.red))
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text("Edit")),
                          const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WalletDetailScreen(wallet: wallet),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}