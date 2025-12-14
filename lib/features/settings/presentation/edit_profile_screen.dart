import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monthly_expense_flutter_project/core/utils/profile_image_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../../providers/theme_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  String? _localImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    _nameController.text = user?.displayName ?? "";

    // Load local image path
    final path = await ProfileImageHelper.getImagePath();
    if (mounted) {
      setState(() {
        _localImagePath = path;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Display Name in Firebase Auth
      // (Note: To update in Firestore too, you'd add a method in AuthRepository)
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        // Force provider refresh if needed, or just rely on stream
        // For simple apps, Firebase Auth stream updates automatically eventually,
        // but reload ensures immediate effect.
        await user.reload();
      }

      // 2. Save Image Path Locally
      if (_localImagePath != null) {
        await ProfileImageHelper.saveImagePath(_localImagePath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- Profile Picture Section ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: _localImagePath != null
                        ? FileImage(File(_localImagePath!))
                        : null,
                    child: _localImagePath == null
                        ? const Icon(Icons.person, size: 60, color: Colors.teal)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Name Input ---
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey[700]),
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // --- Read-Only Email (Usually handled separately for security) ---
            TextField(
              controller: TextEditingController(text: ref.read(authRepositoryProvider).currentUser?.email),
              readOnly: true,
              style: TextStyle(color: textColor.withOpacity(0.6)),
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey[700]),
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}