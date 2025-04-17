import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'spam_classifier_service.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final SpamClassifierService _classifier = SpamClassifierService();

  Future<List<Conversation>> getConversations() async {
    var permission = await Permission.sms.status;
    if (!permission.isGranted) {
      permission = await Permission.sms.request();
      if (!permission.isGranted) {
        return [];
      }
    }

    try {
      final messages = await _query.getAllSms;
      final Map<String, List<SmsMessage>> groupedMessages = {};
      
      // Group messages by sender
      for (var sms in messages) {
        final sender = sms.sender ?? 'Unknown';
        groupedMessages.putIfAbsent(sender, () => []);
        groupedMessages[sender]!.add(sms);
      }

      List<Conversation> conversations = [];
      int processedCount = 0;
      
      for (var entry in groupedMessages.entries) {
        List<Message> processedMessages = entry.value.map((sms) => Message(
          id: sms.id?.hashCode ?? 0,
          sender: sms.sender ?? 'Unknown',
          content: sms.body ?? '',
          timestamp: sms.date ?? DateTime.now(),
          isRead: sms.read ?? false,
          isClassified: false,  // Initially mark as unclassified
        )).toList();

        conversations.add(Conversation(
          id: entry.key.hashCode,
          sender: entry.key,
          messages: processedMessages,
        ));

        // Only process first 10 conversations
        if (processedCount < 10) {
          // Classify messages for this conversation
          List<String> messageBodies = entry.value
              .map((sms) => sms.body ?? '')
              .where((body) => body.isNotEmpty)
              .toList();
              
          final classifications = await _classifier.classifyBatch(messageBodies);
          
          for (var i = 0; i < processedMessages.length; i++) {
            var classification = classifications[i];
            processedMessages[i] = processedMessages[i].copyWith(
              isSpam: classification['predicted_class'] == 1,
              spamConfidence: classification['confidence'] ?? 0.0,
              isClassified: true,
            );
          }
        }
        
        processedCount++;
      }

      // Sort conversations by most recent message
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      return conversations;
    } catch (e) {
      print('Error loading SMS messages: $e');
      return [];
    }
  }
}