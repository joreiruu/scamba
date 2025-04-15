import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _cacheKey = 'message_classifications';

  Future<void> cacheClassification(String messageContent, Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_cacheKey);
    Map<String, dynamic> classifications = {};
    
    if (cache != null) {
      classifications = Map<String, dynamic>.from(jsonDecode(cache));
    }
    
    classifications[messageContent] = result;
    await prefs.setString(_cacheKey, jsonEncode(classifications));
  }

  Future<Map<String, dynamic>?> getCachedClassification(String messageContent) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_cacheKey);
    
    if (cache != null) {
      final classifications = Map<String, dynamic>.from(jsonDecode(cache));
      return classifications[messageContent];
    }
    return null;
  }
}