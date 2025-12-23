import 'package:shared_preferences/shared_preferences.dart';

class ActivitySettings {
  static const _keyAutoPause = "auto_pause_enabled";

  static Future<bool> getAutoPause() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPause) ?? true; // default ON
  }

  static Future<void> setAutoPause(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPause, value);
  }
}
