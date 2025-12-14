import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authRepositoryProvider).currentUser;

    // 1. WATCH THEME STATE
    final isDark = ref.watch(themeProvider);

    // 2. DEFINE DYNAMIC COLORS
    // Backgrounds
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Text
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // Shadows (Lighter or removed in dark mode)
    final shadowColor = isDark ? Colors.transparent : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor, // <--- Dynamic
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cardColor, // <--- Dynamic
        foregroundColor: textColor, // <--- Dynamic
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.email ?? "U").substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          user?.displayName ?? "User",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 4),
                      Text(
                          user?.email ?? "No Email",
                          style: const TextStyle(color: Colors.white70, fontSize: 13)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 2. Preferences Section
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text("PREFERENCES", style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          Container(
            decoration: BoxDecoration(
              color: cardColor, // <--- Dynamic
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: shadowColor, blurRadius: 5)],
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.currency_exchange,
                  color: Colors.orange,
                  title: "Currency",
                  subtitle: "Bangladesh Taka (৳)",
                  textColor: textColor,      // <--- Pass colors
                  subtitleColor: subtitleColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Currency selection coming soon!")));
                  },
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildTile(
                  icon: Icons.notifications_rounded,
                  color: Colors.blue,
                  title: "Notifications",
                  textColor: textColor,
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: (val) {},
                    activeColor: Colors.teal,
                  ),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildTile(
                  icon: Icons.dark_mode_rounded,
                  color: Colors.purple,
                  title: "Dark Mode",
                  textColor: textColor,
                  trailing: Switch.adaptive(
                    value: isDark,
                    // The toggle itself works, and now the colors will react to it!
                    onChanged: (val) => ref.read(themeProvider.notifier).state = val,
                    activeColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. Account Section
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text("ACCOUNT", style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          Container(
            decoration: BoxDecoration(
              color: cardColor, // <--- Dynamic
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: shadowColor, blurRadius: 5)],
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.info_outline_rounded,
                  color: Colors.grey,
                  title: "About App",
                  textColor: textColor,
                  onTap: () {
                    showAboutDialog(context: context, applicationName: "Monthly Expense", applicationVersion: "1.0.0");
                  },
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildTile(
                  icon: Icons.logout_rounded,
                  color: Colors.red,
                  title: "Logout",
                  textColor: Colors.red, // Logout is always red
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor, // Dynamic Dialog
                        title: Text("Logout?", style: TextStyle(color: textColor)),
                        content: Text("Are you sure you want to exit?", style: TextStyle(color: textColor)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              ref.read(authRepositoryProvider).signOut();
                            },
                            child: const Text("Logout", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text("Version 1.0.0", style: TextStyle(color: subtitleColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required Color textColor, // Add this
    String? subtitle,
    Color? subtitleColor,     // Add this
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)) : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}