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
      // Get all messages without limit
      final messages = await _query.getAllSms;

      // Group messages by sender
      final Map<String, List<SmsMessage>> groupedMessages = {};
      for (var sms in messages) {
        final sender = sms.sender ?? 'Unknown';
        groupedMessages.putIfAbsent(sender, () => []);
        groupedMessages[sender]!.add(sms);
      }

      // Process each group of messages
      List<Conversation> conversations = [];
      for (var entry in groupedMessages.entries) {
        List<Message> processedMessages = [];
        
        for (var sms in entry.value) {
          // Classify each message
          Map<String, dynamic> classification;
          try {
            classification = await _classifier.classifyMessage(sms.body ?? '');
          } catch (e) {
            print('Classification failed for message: ${e.toString()}');
            classification = {'predicted_class': 0, 'confidence': 0.0};
          }

          processedMessages.add(Message(
            id: sms.id?.hashCode ?? 0,
            sender: sms.sender ?? 'Unknown',
            content: sms.body ?? '',
            isRead: false,
            isSpam: classification['predicted_class'] == 1,
            spamConfidence: classification['confidence'] ?? 0.0,
            timestamp: sms.date ?? DateTime.now(),
          ));
        }

        conversations.add(Conversation(
          id: entry.key.hashCode,
          sender: entry.key,
          messages: processedMessages,
        ));
      }

      return conversations;
    } catch (e) {
      print('Error loading SMS messages: $e');
      return [];
    }
  }
}