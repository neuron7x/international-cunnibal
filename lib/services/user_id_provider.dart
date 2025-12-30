import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdProvider {
  static const _key = 'app_user_uuid';
  static String? _cachedUserId;
  static const _uuid = Uuid();

  static Future<String> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_key);

    if (userId == null || userId.isEmpty) {
      userId = _uuid.v4();
      await prefs.setString(_key, userId);
    }

    _cachedUserId = userId;
    return userId;
  }

  static Future<void> clearCache() async {
    _cachedUserId = null;
  }
}
