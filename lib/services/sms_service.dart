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
  Timer? _refreshTimer;
  DateTime? _lastCheckTime;
  bool _isLoading = false;

  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;

  Future<List<Conversation>> getConversations({bool loadMore = false}) async {
    if (_isLoading) return _groupIntoConversations();
    _isLoading = true;

    try {
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

      if (messages.isEmpty || messages.length < BATCH_SIZE) {
        _hasMoreMessages = false;
      }

      // Process new messages
      for (var sms in messages) {
        // Skip if already processed
        if (sms.id != null && _processedIds.contains(sms.id)) {
          continue;
        }

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
      print('Error loading messages: $e');
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

  Future<void> startMessageListener() async {
    // Set up periodic refresh every 30 seconds
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkNewMessages();
    });
  }

  Future<void> _checkNewMessages() async {
    try {
      print('Checking for new messages...'); // Debug log
      final now = DateTime.now();
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 20,
        start: 0,
      );

      print('Found ${messages.length} messages'); // Debug log

      final newMessages = messages.where((sms) => 
        _lastCheckTime == null || 
        (sms.date?.isAfter(_lastCheckTime!) ?? false)
      ).toList();

      print('New messages count: ${newMessages.length}'); // Debug log

      if (newMessages.isNotEmpty) {
        var updated = false;
        for (var sms in newMessages) {
          if (sms.id != null && !_processedIds.contains(sms.id)) {
            print('Processing new message from: ${sms.sender}'); // Debug log
            _processNewMessage(sms);
            updated = true;
          }
        }
        
        if (updated) {
          // Convert cache to conversations and emit
          final conversations = _groupIntoConversations();
          _conversationsController.add(conversations);
          print('Emitted ${conversations.length} conversations'); // Debug log
        }
      }

      _lastCheckTime = now;
    } catch (e) {
      print('Error checking new messages: $e');
    }
  }

  void _processNewMessage(SmsMessage sms) {
    if (sms.id != null) {
      _processedIds.add(sms.id!);
      
      final sender = sms.sender ?? 'Unknown';
      final message = Message(
        id: sms.id?.hashCode ?? 0,
        sender: sender,
        content: sms.body ?? '',
        timestamp: sms.date ?? DateTime.now(),
        isRead: false,
      );
      
      // Add to beginning of list to maintain newest-first order
      if (!_messageCache.containsKey(sender)) {
        _messageCache[sender] = [];
      }
      _messageCache[sender]!.insert(0, message);
      print('Added new message to cache for $sender'); // Debug log
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _conversationsController.close();
  }

  List<Conversation> _groupIntoConversations() {
    final conversations = _messageCache.entries.map((entry) {
      return Conversation(
        id: entry.key.hashCode,
        sender: entry.key,
        messages: List.from(entry.value), // Create a new list to prevent mutations
      );
    }).toList();

    // Sort conversations by most recent message
    conversations.sort((a, b) => 
      b.lastMessageTime.compareTo(a.lastMessageTime)
    );

    return conversations;
  }
}