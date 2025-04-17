import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import 'cache_service.dart';

class SpamClassifierService {
  final String apiUrl = 'https://scamba.serveo.net/classify_batch';
  static const double SPAM_THRESHOLD = 50.0;
  final CacheService _cacheService = CacheService();

  Future<List<Map<String, dynamic>>> classifyBatch(List<String> messages) async {
    print('📥 Starting batch classification for ${messages.length} messages');
    if (messages.isEmpty) return [];

    // Create a map to track original indices and timestamps
    List<String> uncachedMessages = [];
    List<Map<String, dynamic>> results = List.filled(messages.length, {});
    Map<int, int> messageIndexMap = {}; // Maps batch index to original index
    
    print('🔍 Checking cache and organizing messages...');
    for (int i = 0; i < messages.length; i++) {
      final cachedResult = await _cacheService.getCachedClassification(messages[i]);
      if (cachedResult != null) {
        print('✅ Cache hit for message $i: $cachedResult');
        results[i] = cachedResult;
      } else {
        print('❌ Cache miss for message $i');
        messageIndexMap[uncachedMessages.length] = i;
        uncachedMessages.add(messages[i]);
      }
    }

    if (uncachedMessages.isEmpty) {
      print('💫 All messages found in cache');
      return results;
    }

    print('🌐 Sending ${uncachedMessages.length} messages to API...');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texts': uncachedMessages}),
      ).timeout(const Duration(seconds: 30));

      print('📊 API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> batchResults = jsonDecode(response.body);
        print('✨ Received classifications for ${batchResults.length} messages');
        
        // Process results maintaining original order
        for (int i = 0; i < batchResults.length; i++) {
          final originalIndex = messageIndexMap[i]!;
          final result = batchResults[i];
          final confidence = result['confidence'] as double;
          
          final classification = {
            'predicted_class': confidence >= SPAM_THRESHOLD ? 1 : 0,
            'confidence': confidence,
            'timestamp': DateTime.now().millisecondsSinceEpoch, // Add timestamp
          };

          print('📝 Message ${originalIndex + 1}/${messages.length}: ${classification['predicted_class'] == 1 ? "SPAM" : "HAM"} (${confidence.toStringAsFixed(2)}%)');
          
          await _cacheService.cacheClassification(messages[originalIndex], classification);
          results[originalIndex] = classification;
        }

        print('✅ Batch classification completed successfully');
        return results;
      } else {
        print('❌ API Error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error during batch classification: $e');
      return List.generate(messages.length, (index) => {
        'predicted_class': 0,
        'confidence': 0.0,
        'error': 'Connection error: ${e.toString()}',
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