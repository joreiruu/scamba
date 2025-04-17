import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import 'cache_service.dart';

class SpamClassifierService {
  final String apiUrl = 'https://scamba.serveo.net/classify_batch';
  static const double SPAM_THRESHOLD = 50.0;
  final CacheService _cacheService = CacheService();

  Future<List<Map<String, dynamic>>> classifyBatch(List<String> messages) async {
    print('\n📊 BATCH CLASSIFICATION');
    print('═' * 80);
    print('Messages to process: ${messages.length}');

    if (messages.isEmpty) return [];

    List<String> uncachedMessages = [];
    List<Map<String, dynamic>> results = List.filled(messages.length, {});
    Map<int, int> messageIndexMap = {};

    // Check cache
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final cachedResult = await _cacheService.getCachedClassification(message);
      if (cachedResult != null) {
        results[i] = cachedResult;
      } else {
        messageIndexMap[uncachedMessages.length] = i;
        uncachedMessages.add(message);
      }
    }

    if (uncachedMessages.isEmpty) return results;

    try {
      print('\n🌐 Sending API request:');
      print(const JsonEncoder.withIndent('  ').convert({'texts': uncachedMessages}));

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texts': uncachedMessages}),
      ).timeout(const Duration(seconds: 30));

      print('\n📥 API Response (${response.statusCode}):');
      print(const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body)));
      
      if (response.statusCode == 200) {
        final List<dynamic> batchResults = jsonDecode(response.body);
        
        for (int i = 0; i < batchResults.length; i++) {
          final originalIndex = messageIndexMap[i]!;
          final result = batchResults[i];
          final message = messages[originalIndex];
          
          print('\n═════════════════════════════════');
          print('MESSAGE: "${message.substring(0, min(50, message.length))}..."');
          print('RAW API RESPONSE:');
          print(const JsonEncoder.withIndent('  ').convert(result));
          print('═════════════════════════════════');

          final classification = {
            'predicted_class': result['predicted_class'],
            'confidence': result['confidence'],
            'raw_scores': [
              result['class_0_probability'] ?? 0.0,
              result['class_1_probability'] ?? 0.0
            ],
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          await _cacheService.cacheClassification(message, classification);
          results[originalIndex] = classification;
        }
        
        return results;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error: $e');
      return List.generate(messages.length, (index) => {
        'predicted_class': 0,
        'confidence': 0.0,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    print('\n🔄 Processing single message: "${message.substring(0, min(30, message.length))}..."');
    
    if (message.isEmpty) {
      print('⚠️ Empty message received');
      return {
        'predicted_class': 0,
        'confidence': 0.0,
        'error': 'Empty message'
      };
    }

    final results = await classifyBatch([message]);
    print('📤 Classification complete\n');
    return results.first;
  }
}