import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageHelper {
  static const String _keyProfileImage = 'user_profile_image_path';

  // Save Image Path
  static Future<void> saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImage, path);
  }

  // Get Image Path
  static Future<String?> getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileImage);
  }

  // Clear Image (e.g. on logout)
  static Future<void> clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileImage);
  }
}