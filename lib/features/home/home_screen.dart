// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:monthly_expense_flutter_project/core/utils/currency_helper.dart';
// import 'package:monthly_expense_flutter_project/core/utils/profile_image_helper.dart';
// import 'package:monthly_expense_flutter_project/features/auth/data/auth_repository.dart';
// import 'package:monthly_expense_flutter_project/features/settings/presentation/settings_screen.dart';
// import 'package:monthly_expense_flutter_project/features/wallet/data/wallet_repository.dart';
// import 'package:monthly_expense_flutter_project/features/wallet/domain/wallet_model.dart';
// import 'package:monthly_expense_flutter_project/features/wallet/presentation/add_wallet_dialog.dart';
// import 'package:monthly_expense_flutter_project/features/wallet/presentation/wallet_detail_screen.dart';
// import 'package:monthly_expense_flutter_project/features/savings/presentation/savings_list_screen.dart';
// import 'package:monthly_expense_flutter_project/features/analytics/presentation/summary_screen.dart';
// import '../providers/theme_provider.dart';
//
// class HomeScreen extends ConsumerWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final walletListAsync = ref.watch(walletListProvider);
//
//     // 1. WATCH THEME
//     final isDark = ref.watch(themeProvider);
//
//     // 2. DEFINE COLORS
//     final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[100];
//     final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.teal;
//     final textColor = isDark ? Colors.white : Colors.black87;
//     final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
//
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         title: const Text("My Wallets", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: appBarColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           // Quick Toggle for convenience
//           IconButton(
//             icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
//             onPressed: () => ref.read(themeProvider.notifier).state = !isDark,
//           )
//         ],
//       ),
//       drawer: _buildDrawer(context, ref, isDark),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           showDialog(context: context, builder: (_) => const AddWalletDialog());
//         },
//         label: const Text("New Wallet"),
//         icon: const Icon(Icons.add),
//         backgroundColor: Colors.teal,
//         foregroundColor: Colors.white,
//       ),
//       body: walletListAsync.when(
//         data: (wallets) {
//           if (wallets.isEmpty) {
//             return _buildEmptyState(isDark);
//           }
//           return _buildGroupedWalletList(context, ref, wallets, isDark, textColor, subTextColor);
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => Center(child: Text("Error: $err", style: TextStyle(color: textColor))),
//       ),
//     );
//   }
//
//   // Helper to get Image Provider (Web vs Mobile)
//   ImageProvider? _getImageProvider(String? path) {
//     if (path == null) return null;
//     if (kIsWeb) {
//       try {
//         return MemoryImage(base64Decode(path));
//       } catch (e) {
//         return null;
//       }
//     } else {
//       return FileImage(File(path));
//     }
//   }
//
//   // --- 1. GROUPING LOGIC ---
//   Widget _buildGroupedWalletList(
//       BuildContext context,
//       WidgetRef ref,
//       List<WalletModel> wallets,
//       bool isDark,
//       Color textColor,
//       Color? subTextColor
//       ) {
//     String getGroupKey(WalletModel wallet) {
//       final now = DateTime.now();
//       if (wallet.year == now.year && wallet.month == now.month) {
//         return "Current Month";
//       } else if (wallet.year == now.year && wallet.month == now.month - 1) {
//         return "Last Month";
//       } else {
//         final date = DateTime(wallet.year, wallet.month);
//         return DateFormat('MMMM yyyy').format(date);
//       }
//     }
//
//     final Map<String, List<WalletModel>> grouped = {};
//     for (var wallet in wallets) {
//       final key = getGroupKey(wallet);
//       if (!grouped.containsKey(key)) grouped[key] = [];
//       grouped[key]!.add(wallet);
//     }
//
//     final groupKeys = grouped.keys.toList();
//
//     return ListView.builder(
//       padding: const EdgeInsets.only(bottom: 80),
//       itemCount: groupKeys.length,
//       itemBuilder: (context, index) {
//         final key = groupKeys[index];
//         final groupWallets = grouped[key]!;
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
//               child: Text(
//                 key.toUpperCase(),
//                 style: TextStyle(
//                   color: subTextColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 13,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ),
//             ...groupWallets.map((wallet) => _WalletCard(wallet: wallet, ref: ref, isDark: isDark)),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildEmptyState(bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.account_balance_wallet_outlined, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
//           const SizedBox(height: 16),
//           Text(
//             "No wallets yet",
//             style: TextStyle(fontSize: 20, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text("Create a monthly budget to get started.", style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDrawer(BuildContext context, WidgetRef ref, bool isDark) {
//     final drawerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
//     final textColor = isDark ? Colors.white : Colors.black87;
//     final user = ref.read(authRepositoryProvider).currentUser;
//
//     return Drawer(
//       backgroundColor: drawerBg,
//       child: Column(
//         children: [
//           FutureBuilder<String?>(
//             future: ProfileImageHelper.getImagePath(),
//             builder: (context, snapshot) {
//               final imagePath = snapshot.data;
//               final imageProvider = _getImageProvider(imagePath);
//
//               return UserAccountsDrawerHeader(
//                 decoration: const BoxDecoration(
//                   color: Colors.teal,
//                   image: DecorationImage(
//                     image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
//                     fit: BoxFit.cover,
//                     opacity: 0.1,
//                   ),
//                 ),
//                 accountName: Text(
//                   user?.displayName ?? "Monthly Expense",
//                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 accountEmail: Text(user?.email ?? "Track your wealth"),
//                 currentAccountPicture: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   backgroundImage: imageProvider,
//                   onBackgroundImageError: imageProvider != null ? (_, __) {} : null,
//                   child: imageProvider == null
//                       ? Text(
//                     (user?.email ?? "U").substring(0, 1).toUpperCase(),
//                     style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.teal),
//                   )
//                       : null,
//                 ),
//               );
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.savings, color: Colors.green),
//             title: Text("Savings Goals", style: TextStyle(color: textColor)),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsListScreen()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.bar_chart_rounded, color: Colors.purple),
//             title: Text("Global Summary", style: TextStyle(color: textColor)),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
//             },
//           ),
//           Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
//           ListTile(
//             leading: Icon(Icons.settings, color: textColor),
//             title: Text("Settings", style: TextStyle(color: textColor)),
//             onTap: () async {
//               Navigator.pop(context);
//               await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
//             },
//           ),
//           const Spacer(),
//           Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.red),
//             title: const Text("Logout", style: TextStyle(color: Colors.red)),
//             onTap: () {
//               ref.read(authRepositoryProvider).signOut();
//             },
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }
//
// // --- 2. MODERN WALLET CARD (UPDATED BACKGROUND LOGIC) ---
// class _WalletCard extends StatelessWidget {
//   final WalletModel wallet;
//   final WidgetRef ref;
//   final bool isDark;
//
//   const _WalletCard({required this.wallet, required this.ref, required this.isDark});
//
//   @override
//   Widget build(BuildContext context) {
//     // Check status
//     final bool isNegative = wallet.currentBalance < 0;
//     final bool isLowBalance = wallet.currentBalance < (wallet.monthlyBudget * 0.2);
//
//     // Dynamic Card Colors
//     Color cardColor;
//     if (isNegative) {
//       // Red background for negative balance
//       cardColor = isDark ? const Color(0xFF3E1515) : const Color(0xFFFFEBEE);
//     } else {
//       // Normal background
//       cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
//     }
//
//     final textColor = isDark ? Colors.white : Colors.black87;
//     final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
//     final shadowColor = isDark ? Colors.transparent : (isNegative ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.15));
//
//     // Calculate progress
//     final double progress = (wallet.monthlyBudget == 0)
//         ? 0
//         : (wallet.monthlyBudget - wallet.currentBalance) / wallet.monthlyBudget;
//
//     final double safeProgress = progress.clamp(0.0, 1.0);
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
//         ],
//       ),
//       child: Material(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             Navigator.push(context, MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet)));
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Top Row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           wallet.name,
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           DateFormat('MMMM yyyy').format(DateTime(wallet.year, wallet.month)),
//                           style: TextStyle(fontSize: 12, color: subTextColor),
//                         ),
//                       ],
//                     ),
//                     _buildPopupMenu(context, ref, wallet, isDark, textColor),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Balance
//                 Text("Current Balance", style: TextStyle(fontSize: 12, color: subTextColor)),
//                 Row(
//                   children: [
//                     Text(
//                       CurrencyHelper.format(wallet.currentBalance),
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: isNegative ? Colors.red : Colors.teal,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 15),
//
//                 // Progress Bar
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: 1.0 - safeProgress,
//                     minHeight: 8,
//                     backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
//                     // If negative, show Red bar. If low balance, Orange. Else Green.
//                     color: isNegative ? Colors.red : (isLowBalance ? Colors.orange : Colors.green),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Spent: ${CurrencyHelper.format(wallet.monthlyBudget - wallet.currentBalance)}",
//                       style: TextStyle(fontSize: 12, color: subTextColor),
//                     ),
//                     Text(
//                       "Limit: ${CurrencyHelper.format(wallet.monthlyBudget)}",
//                       style: TextStyle(fontSize: 12, color: subTextColor),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPopupMenu(BuildContext context, WidgetRef ref, WalletModel wallet, bool isDark, Color textColor) {
//     return PopupMenuButton(
//       icon: Icon(Icons.more_horiz, color: isDark ? Colors.grey[400] : Colors.grey[400]),
//       color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       onSelected: (value) {
//         if (value == 'edit') {
//           showDialog(context: context, builder: (_) => AddWalletDialog(walletToEdit: wallet));
//         } else if (value == 'delete') {
//           _confirmDelete(context, ref, wallet, isDark, textColor);
//         }
//       },
//       itemBuilder: (context) => [
//         PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20, color: textColor), const SizedBox(width: 8), Text("Edit", style: TextStyle(color: textColor))])),
//         PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, color: Colors.red, size: 20), const SizedBox(width: 8), const Text("Delete", style: TextStyle(color: Colors.red))])),
//       ],
//     );
//   }
//
//   void _confirmDelete(BuildContext context, WidgetRef ref, WalletModel wallet, bool isDark, Color textColor) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Text("Delete Wallet?", style: TextStyle(color: textColor)),
//         content: Text("This cannot be undone. All expenses in this wallet will be lost.", style: TextStyle(color: textColor)),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
//           ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
//               onPressed: () {
//                 ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
//                 Navigator.pop(ctx);
//               },
//               child: const Text("Delete")
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/core/utils/profile_image_helper.dart';
import 'package:monthly_expense_flutter_project/features/auth/data/auth_repository.dart';
import 'package:monthly_expense_flutter_project/features/settings/presentation/settings_screen.dart';
import 'package:monthly_expense_flutter_project/features/wallet/presentation/wallet_list_screen.dart';
import 'package:monthly_expense_flutter_project/features/todo/presentation/todo_list_screen.dart';
import 'package:monthly_expense_flutter_project/features/notes/presentation/note_list_screen.dart';
import 'package:monthly_expense_flutter_project/features/analytics/presentation/summary_screen.dart';
import 'package:monthly_expense_flutter_project/features/savings/presentation/savings_list_screen.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final user = ref.read(authRepositoryProvider).currentUser;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        title: Text("Dashboard", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).state = !isDark,
          )
        ],
      ),
      drawer: _buildDrawer(context, ref, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text("Hello, ${user?.displayName ?? 'User'}!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 5),
            Text("Manage your day effectively.", style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 30),

            // 1. WALLET CARD
            _DashboardCard(
              title: "My Wallet",
              subtitle: "Track expenses & budget",
              icon: Icons.account_balance_wallet,
              color: Colors.teal,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletListScreen())),
            ),
            const SizedBox(height: 16),

            // 2. TODO CARD
            _DashboardCard(
              title: "Todo List",
              subtitle: "Track your daily tasks",
              icon: Icons.check_circle_outline,
              color: Colors.orange,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoListScreen())),
            ),
            const SizedBox(height: 16),

            // 3. NOTES CARD
            _DashboardCard(
              title: "Notes",
              subtitle: "Ideas, memories & more",
              icon: Icons.edit_note_rounded,
              color: Colors.purple,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteListScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, bool isDark) {
    // [Keep your existing Drawer code logic here]
    // ... Copy from old home_screen.dart ...
    // Just ensure it points to the new screens correctly.
    final drawerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final user = ref.read(authRepositoryProvider).currentUser;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: ProfileImageHelper.getImagePath(),
            builder: (context, snapshot) {
              final imagePath = snapshot.data;
              ImageProvider? imageProvider;
              if (imagePath != null) {
                if (kIsWeb) imageProvider = MemoryImage(base64Decode(imagePath));
                else imageProvider = FileImage(File(imagePath));
              }

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.teal),
                accountName: Text(user?.displayName ?? "Monthly Expense"),
                accountEmail: Text(user?.email ?? ""),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: imageProvider,
                  child: imageProvider == null ? Text((user?.email ?? "U")[0].toUpperCase()) : null,
                ),
              );
            },
          ),
          ListTile(leading: const Icon(Icons.dashboard, color: Colors.teal), title: Text("Dashboard", style: TextStyle(color: textColor)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.savings, color: Colors.green), title: Text("Savings Goals", style: TextStyle(color: textColor)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsListScreen())); }),
          ListTile(leading: const Icon(Icons.bar_chart_rounded, color: Colors.purple), title: Text("Global Summary", style: TextStyle(color: textColor)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())); }),
          const Divider(),
          ListTile(leading: Icon(Icons.settings, color: textColor), title: Text("Settings", style: TextStyle(color: textColor)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red)), onTap: () => ref.read(authRepositoryProvider).signOut()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 5,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.grey[700] : Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}