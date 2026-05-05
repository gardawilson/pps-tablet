import 'package:shared_preferences/shared_preferences.dart';

class UserSessionStorage {
  static const String _usernameKey = 'logged_username';
  static const String _fullNameKey = 'logged_full_name';

  static Future<void> saveUser({
    required String username,
    String? fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);

    final normalizedFullName = fullName?.trim();
    if (normalizedFullName == null || normalizedFullName.isEmpty) {
      await prefs.remove(_fullNameKey);
    } else {
      await prefs.setString(_fullNameKey, normalizedFullName);
    }
  }

  static Future<String> getUsername({String fallback = 'unknown'}) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey)?.trim();
    return username == null || username.isEmpty ? fallback : username;
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_fullNameKey)?.trim();
    return fullName == null || fullName.isEmpty ? null : fullName;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_fullNameKey);
  }
}
