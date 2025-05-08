import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'dart:async';

class SmsService {
  static const int BATCH_SIZE = 100;
  final SmsQuery _query = SmsQuery();
  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  final Map<String, List<Message>> _messageCache = {};
  final Set<int> _processedIds = {};
  bool _isInitialized = false;

  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;

  Future<List<Conversation>> getConversations({bool loadMore = false}) async {
    if (!_isInitialized) {
      var permission = await Permission.sms.status;
      if (!permission.isGranted) {
        permission = await Permission.sms.request();
        if (!permission.isGranted) return [];
      }
      _isInitialized = true;
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: BATCH_SIZE,
      );

      print('📱 SMS Service: Checking messages...');
      print('📱 Total messages found: ${messages.length}');

      for (var sms in messages) {
        if (sms.id != null && !_processedIds.contains(sms.id)) {
          final sender = sms.sender ?? 'Unknown';
          final message = Message(
            id: sms.id?.hashCode ?? 0,
            sender: sender,
            content: sms.body ?? '',
            timestamp: sms.date ?? DateTime.now(),
            isRead: sms.read ?? false,
            isNew: true,
            isClassified: false, // Ensure new messages are marked as unclassified
          );
          
          _messageCache.putIfAbsent(sender, () => []).insert(0, message);
          _processedIds.add(sms.id!);
        }
      }

      final conversations = _groupIntoConversations();
      _conversationsController.add(conversations);
      return conversations;
    } catch (e) {
      print('❌ Error loading messages: $e');
      return _groupIntoConversations();
    }
  }

  Future<void> refreshConversations() async {
    try {
      print('📱 Refreshing conversations...');
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: BATCH_SIZE,
      );

      bool hasNewMessages = false;
      for (var sms in messages) {
        if (sms.id != null && !_processedIds.contains(sms.id)) {
          final sender = sms.sender ?? 'Unknown';
          final message = Message(
            id: sms.id?.hashCode ?? 0,
            sender: sender,
            content: sms.body ?? '',
            timestamp: sms.date ?? DateTime.now(),
            isRead: sms.read ?? false,
            isNew: true,
            isClassified: false,
            isSpam: false,
            spamConfidence: 0.0,
          );
          
          final senderMessages = _messageCache.putIfAbsent(sender, () => []);
          senderMessages.insert(0, message);
          senderMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _processedIds.add(sms.id!);
          hasNewMessages = true;
        }
      }

      if (hasNewMessages) {
        final conversations = _groupIntoConversations();
        _conversationsController.add(conversations);
      }
    } catch (e) {
      print('❌ Error refreshing conversations: $e');
    }
  }

  List<Conversation> _groupIntoConversations() {
    final conversations = _messageCache.entries.map((entry) => 
      Conversation(
        id: entry.key.hashCode,
        sender: entry.key,
        messages: List<Message>.from(entry.value),
      )
    ).toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    return conversations;
  }

  void dispose() {
    _conversationsController.close();
  }
}