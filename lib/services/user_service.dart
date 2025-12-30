import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _prefsKey = 'user_uuid';
  static const _uuid = Uuid();

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var existing = prefs.getString(_prefsKey);
    if (existing == null || existing.isEmpty) {
      existing = _uuid.v4();
      await prefs.setString(_prefsKey, existing);
    }
    return existing;
  }
}
