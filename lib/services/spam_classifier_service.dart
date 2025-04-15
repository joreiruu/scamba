import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cache_service.dart';

class SpamClassifierService {
  final String apiUrl = 'https://0c98-136-158-102-54.ngrok-free.app/classify';
  static const double SPAM_THRESHOLD = 50.0;
  final CacheService _cacheService = CacheService();

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    if (message.isEmpty) {
      return {
        'predicted_class': 0,
        'confidence': 0.0,
        'error': 'Empty message'
      };
    }

    // Check cache first
    final cachedResult = await _cacheService.getCachedClassification(message);
    if (cachedResult != null) {
      print('Using cached classification for message');
      return cachedResult;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': message}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final confidence = result['confidence'] as double;
        
        final classification = {
          'predicted_class': confidence >= SPAM_THRESHOLD ? 1 : 0,
          'confidence': confidence,
        };

        // Cache the result
        await _cacheService.cacheClassification(message, classification);
        return classification;
      } else {
        return {
          'predicted_class': 0,
          'confidence': 0.0,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Classification error: $e'); // For debugging
      return {
        'predicted_class': 0,
        'confidence': 0.0,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }
}