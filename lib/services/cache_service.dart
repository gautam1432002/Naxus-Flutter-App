import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  Future<void> cacheData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'timestamp': timestamp,
      'data': value,
    };
    await prefs.setString(key, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final storedString = prefs.getString(key);
    if (storedString == null) return null;

    try {
      final payload = jsonDecode(storedString) as Map<String, dynamic>;
      final timestamp = payload['timestamp'] as int;
      final data = payload['data'] as String;

      final ageMinutes = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inMinutes;

      return {
        'data': data,
        'ageMinutes': ageMinutes,
      };
    } catch (e) {
      // If parsing fails, clear the corrupt cache
      await prefs.remove(key);
      return null;
    }
  }
}
