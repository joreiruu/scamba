import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'dart:async';
import 'dart:math';

class SmsService {
  static const int BATCH_SIZE = 100;
  final SmsQuery _query = SmsQuery();
  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  final Map<String, List<Message>> _messageCache = {};
  int _lastLoadedId = 0;
  bool _hasMoreMessages = true;
  bool _isInitialized = false;
  final Set<int> _processedIds = {}; // Track processed SMS IDs
  
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;

  Future<List<Conversation>> getConversations({bool loadMore = false}) async {
    // Check permission only on first load
    if (!_isInitialized) {
      var permission = await Permission.sms.status;
      if (!permission.isGranted) {
        permission = await Permission.sms.request();
        if (!permission.isGranted) return [];
      }
      _isInitialized = true;
    }

    // Return cached messages if not loading more
    if (!loadMore && _messageCache.isNotEmpty) {
      return _groupIntoConversations();
    }

    try {
      final messages = await _query.querySms(
        start: _lastLoadedId,
        count: BATCH_SIZE,
      );

      print('📱 SMS Service: Checking messages...');
      print('📱 Total messages found: ${messages.length}');

      // Process new messages
      for (var sms in messages) {
        // Skip if already processed
        if (sms.id != null && _processedIds.contains(sms.id)) {
          continue;
        }

        print('✨ NEW MESSAGE DETECTED:');
        print('   From: ${sms.sender}');
        print('   Content: ${sms.body?.substring(0, min(30, sms.body?.length ?? 0))}...');
        print('   Time: ${sms.date}');

        final sender = sms.sender ?? 'Unknown';
        final message = Message(
          id: sms.id?.hashCode ?? 0,
          sender: sender,
          content: sms.body ?? '',
          timestamp: sms.date ?? DateTime.now(),
          isRead: sms.read ?? false,
        );
        
        _messageCache.putIfAbsent(sender, () => []).add(message);
        if (sms.id != null) {
          _lastLoadedId = sms.id!;
          _processedIds.add(sms.id!);
        }
      }

      return _groupIntoConversations();
    } catch (e) {
      print('❌ Error loading messages: $e');
      return _groupIntoConversations(); // Return cached messages on error
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
      print('📬 Found ${messages.length} total messages');

      for (var sms in messages) {
        // Only process truly new messages
        if (sms.id != null && !_processedIds.contains(sms.id)) {
          print('✨ Found new message from: ${sms.sender}');
          final sender = sms.sender ?? 'Unknown';
          final message = Message(
            id: sms.id?.hashCode ?? 0,
            sender: sender,
            content: sms.body ?? '',
            timestamp: sms.date ?? DateTime.now(),
            isRead: sms.read ?? false,
          );
          
          _messageCache.putIfAbsent(sender, () => []).insert(0, message);
          _processedIds.add(sms.id!);
          hasNewMessages = true;
        }
      }

      // Only update if we actually found new messages
      if (hasNewMessages) {
        print('🔄 Updating with new messages');
        final conversations = _groupIntoConversations();
        _conversationsController.add(conversations);
      }
    } catch (e) {
      print('❌ Error refreshing conversations: $e');
    }
  }

  void dispose() {
    _conversationsController.close();
  }

  List<Conversation> _groupIntoConversations() {
    final conversations = _messageCache.entries.map((entry) => 
      Conversation(
        id: entry.key.hashCode,
        sender: entry.key,
        messages: entry.value,
      )
    ).toList();

    // Sort by most recent message
    conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    return conversations;
  }
}