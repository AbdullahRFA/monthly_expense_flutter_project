import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_expense_flutter_project/core/utils/profile_image_helper.dart';
import 'package:monthly_expense_flutter_project/features/settings/presentation/edit_profile_screen.dart'; // Import new screen
import '../../auth/data/auth_repository.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Load image from SharedPreferences
  Future<void> _loadProfileImage() async {
    final path = await ProfileImageHelper.getImagePath();
    if (mounted) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authRepositoryProvider).currentUser;
    final isDark = ref.watch(themeProvider);

    // Dynamic Colors
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final shadowColor = isDark ? Colors.transparent : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Profile Card (Updated)
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
                // Profile Picture Logic
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null
                      ? Text(
                    (user?.email ?? "U").substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                  )
                      : null,
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
                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    // Navigate to Edit Screen and wait for result
                    await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen())
                    );
                    // Refresh data when coming back
                    await user?.reload();
                    _loadProfileImage();
                    setState(() {}); // Rebuild to show new name
                  },
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ... (Rest of your existing tiles: Preferences, Account, etc.)
          // Reuse your existing _buildTile logic here...

          // PREFERENCES
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text("PREFERENCES", style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
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
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming soon!"))),
                ),
                Divider(height: 1, indent: 60, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildTile(
                  icon: Icons.dark_mode_rounded,
                  color: Colors.purple,
                  title: "Dark Mode",
                  textColor: textColor,
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (val) => ref.read(themeProvider.notifier).state = val,
                    activeColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ACCOUNT
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text("ACCOUNT", style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: shadowColor, blurRadius: 5)],
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.logout_rounded,
                  color: Colors.red,
                  title: "Logout",
                  textColor: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text("Logout?", style: TextStyle(color: textColor)),
                        content: Text("Are you sure?", style: TextStyle(color: textColor)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              // Clear image cache on logout so next user doesn't see it
                              ProfileImageHelper.clearImage();
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
        ],
      ),
    );
  }

  // Helper Widget (Same as before)
  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required Color textColor,
    String? subtitle,
    Color? subtitleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)) : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}