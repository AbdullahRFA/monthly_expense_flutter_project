import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current user email to show in profile
    final user = ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // Profile Section
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? "User"), // We didn't save DisplayName in Auth, but that's ok
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(child: Icon(Icons.person, size: 40)),
            decoration: const BoxDecoration(color: Colors.teal),
          ),

          // Settings Options (SRS Requirements)
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text("Currency"),
            subtitle: const Text("Bangladesh Taka (৳)"),
            onTap: () {
              // Future: Open dialog to change currency
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            trailing: Switch(value: true, onChanged: (val) {}), // Dummy switch
          ),
          // ... inside the build method ListView ...
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            trailing: Switch(
              // 1. Read value
              value: ref.watch(themeProvider),
              // 2. Update value
              onChanged: (val) {
                ref.read(themeProvider.notifier).state = val;
              },
            ),
          ),

          const Divider(),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              // 1. Close the drawer/screen
              Navigator.pop(context);
              // 2. Logout
              ref.read(authRepositoryProvider).signOut();
            },
          ),

        ],
      ),
    );
  }
}