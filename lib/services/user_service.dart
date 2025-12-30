import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _keyUserId = 'user_uuid';
  static const _keyDisplayName = 'display_name';
  static const _uuid = Uuid();

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      userId = _uuid.v4();
      await prefs.setString(_keyUserId, userId);
    }
    return userId;
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name);
  }
}
