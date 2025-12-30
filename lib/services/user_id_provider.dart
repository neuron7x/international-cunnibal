import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdProvider {
  static const _key = 'user_uuid';
  static String? _cachedId;

  static Future<String> getUserId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_key);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_key, userId);
    }

    _cachedId = userId;
    return userId;
  }
}
