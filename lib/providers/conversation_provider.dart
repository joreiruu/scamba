import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/sms_service.dart';
import '../services/spam_classifier_service.dart';
import '../services/database_helper.dart';

class ConversationProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Conversation> _deletedConversations = [];
  List<Conversation> _archivedConversations = [];
  final List<Conversation> _favoriteConversations = [];
  final Map<String, DateTime> _deletedAtMap = {};
  final SmsService _smsService = SmsService();
  final Map<int, bool> _messageReadStatus = {};
  final SpamClassifierService _classifier = SpamClassifierService();
  final DatabaseHelper _db = DatabaseHelper();
  final Set<String> _processedMessageIds = {}; // Track processed messages
  StreamSubscription? _subscription;

  static const refreshInterval = Duration(seconds: 5);
  Timer? _autoRefreshTimer;

  // Add these keys for SharedPreferences
  static const String _archivedIdsKey = 'archived_conversation_ids';
  static const String _readMessageIdsKey = 'read_message_ids';
  static const String _deletedIdsKey = 'deleted_conversation_ids';

  // Add flags to track initial load
  bool _isInitialized = false;
  final Set<int> _persistentArchivedIds = {};
  final Set<int> _persistentDeletedIds = {};
  bool _isClassifying = false;

  // Remove auto-refresh timer from constructor
  ConversationProvider() {
    // Only load saved states once
    Future(() async {
      await _loadArchivedIds();
      await _loadDeletedIds();
      await _loadReadStatus();
      notifyListeners();
    });

    // Listen to SMS updates
    _subscription = _smsService.conversationsStream.listen((conversations) {
      refreshConversations();
    });
  }

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Conversation> get deletedConversations => _deletedConversations;
  List<Conversation> get archivedConversations => _archivedConversations;
  List<Conversation> get favoriteConversations => _favoriteConversations;

  Map<String, DateTime> get deletedAtMap => _deletedAtMap;

  // In ConversationProvider class
  void initWithSampleData() {
    if (_conversations.isEmpty) {
      _conversations = conversations; // Assuming "conversations" is the variable from sample_sms_data.dart
      notifyListeners();
    }
  }

  // Initialize conversations
  Future<void> loadConversations(List<Conversation> newConversations) async {
    // Clear existing conversations to prevent duplication
    _conversations.clear();
    _archivedConversations.clear();

    // Load saved states
    await _loadArchivedIds();
    await _loadDeletedIds();
    await _loadReadStatus();

    // Load stored classifications for each message
    for (var conversation in newConversations) {
      for (var message in conversation.messages) {
        final storedClassification = await _db.getClassification(message.id.toString());
        if (storedClassification != null) {
          message.isSpam = storedClassification['is_spam'] == 1;
          message.spamConfidence = storedClassification['confidence'];
          message.isClassified = true;
        }
      }
    }

    _preserveReadStatus(newConversations);
    _conversations = newConversations;

    // Only classify unclassified messages
    classifyMessagesInBackground(newConversations);
    notifyListeners();
  }

  void _preserveReadStatus(List<Conversation> conversations) {
    // Get current archived IDs before updating anything
    final archivedIds = Set<int>.from(_archivedConversations.map((c) => c.id));

    // Save current read status before updating
    for (var conv in _conversations) {
      for (var msg in conv.messages) {
        _messageReadStatus[msg.id] = msg.isRead;
      }
    }

    // Filter out archived conversations from main list
    _conversations = conversations.where((conv) => !archivedIds.contains(conv.id)).toList();

    // Update archived conversations with fresh data
    _archivedConversations = conversations
        .where((conv) => archivedIds.contains(conv.id))
        .toList();

    // Apply saved read status to new messages
    for (var conv in conversations) {
      for (var msg in conv.messages) {
        if (_messageReadStatus.containsKey(msg.id)) {
          msg.isRead = _messageReadStatus[msg.id]!;
        }
      }
    }
  }

  Future<void> classifyMessagesInBackground(List<Conversation> conversations) async {
    if (_isClassifying) return;
    _isClassifying = true;

    try {
      // Sort conversations by most recent message first
      final sortedConversations = List<Conversation>.from(conversations)
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      for (var conversation in sortedConversations) {
        print('📱 Processing conversation from: ${conversation.sender}');
        
        // Get unclassified messages in this conversation, newest first
        final unclassifiedMessages = conversation.messages
            .where((msg) => !msg.isClassified)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (unclassifiedMessages.isEmpty) {
          print('✓ All messages from ${conversation.sender} are already classified');
          continue;
        }

        print('🔄 Classifying ${unclassifiedMessages.length} messages from ${conversation.sender}');
        
        // Process all messages in this conversation before moving to next
        for (var message in unclassifiedMessages) {
          print('  └─ Classifying message: "${message.content.substring(0, min(30, message.content.length))}..."');
          
          final result = await _classifier.classifyMessage(message);
          
          if (!result.containsKey('error')) {
            message.isSpam = result['predicted_class'] == 1;
            message.spamConfidence = result['confidence'];
            message.isClassified = true;

            // Store classification result
            await _db.storeClassification(
              messageId: message.id.toString(),
              isSpam: message.isSpam,
              confidence: message.spamConfidence,
            );
            
            print('     ✓ ${message.isSpam ? "SPAM" : "HAM"} (${message.spamConfidence.toStringAsFixed(2)}%)');
            notifyListeners(); // Update UI after each classification
          }
        }
        
        print('✅ Finished classifying conversation from: ${conversation.sender}\n');
      }
    } finally {
      _isClassifying = false;
      print('🏁 Classification process completed');
    }
  }

  // Add a new conversation
  void addConversation(Conversation conversation) {
    _conversations.add(conversation);
    notifyListeners();
  }

  // Update a conversation
  void updateConversation(Conversation updatedConversation) {
    final index = _conversations.indexWhere((conv) => conv.id == updatedConversation.id);
    if (index != -1) {
      _conversations[index] = updatedConversation;
      notifyListeners();
    }
  }

  // Archive a conversation
  void archiveConversation(Conversation conversation) {
    print('Archiving conversation: ${conversation.id}'); // Debug log
    if (!_persistentArchivedIds.contains(conversation.id)) {
      _persistentArchivedIds.add(conversation.id);
      _conversations.removeWhere((conv) => conv.id == conversation.id);
      _archivedConversations.add(conversation);
      _saveArchivedIds();
      notifyListeners();
    }
  }

  // Delete a conversation
  void deleteConversation(Conversation conversation) {
    _conversations.removeWhere((conv) => conv.id == conversation.id);
    _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
    _deletedConversations.add(conversation);
    _persistentDeletedIds.add(conversation.id);
    _saveDeletedIds();
    notifyListeners();
  }

  // Restore a deleted conversation
  void restoreDeletedConversation(Conversation conversation) {
    _deletedConversations.removeWhere((conv) => conv.id == conversation.id);
    _persistentDeletedIds.remove(conversation.id);
    
    // Insert the conversation in the correct chronological position
    int insertIndex = _conversations.indexWhere(
        (conv) => conv.lastMessageTime.isBefore(conversation.lastMessageTime)
    );
    
    if (insertIndex == -1) {
        // If no earlier message found, add to end
        _conversations.add(conversation);
    } else {
        // Insert at the correct position
        _conversations.insert(insertIndex, conversation);
    }
    
    _saveDeletedIds();
    notifyListeners();
  }

  // Restore an archived conversation
  void restoreArchivedConversation(Conversation conversation) {
    if (_persistentArchivedIds.contains(conversation.id)) {
        _persistentArchivedIds.remove(conversation.id);
        _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
        
        // Insert the conversation in the correct chronological position
        int insertIndex = _conversations.indexWhere(
            (conv) => conv.lastMessageTime.isBefore(conversation.lastMessageTime)
        );
        
        if (insertIndex == -1) {
            // If no earlier message found, add to end
            _conversations.add(conversation);
        } else {
            // Insert at the correct position
            _conversations.insert(insertIndex, conversation);
        }
        
        _saveArchivedIds();
        notifyListeners();
    }
  }

  // Permanently delete a conversation
  void permanentlyDeleteConversation(Conversation conversation) {
    _deletedConversations.removeWhere((conv) => conv.id == conversation.id);
    _deletedAtMap.remove(conversation.id.toString());
    notifyListeners();
  }

  // Undo Archive
  void unarchiveConversation(Conversation conversation) {
    _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
    _conversations.add(conversation);
    notifyListeners();
  }

  // Undo Delete
  void restoreConversation(Conversation conversation) {
    _deletedConversations.removeWhere((conv) => conv.id == conversation.id);
    _conversations.add(conversation);
    notifyListeners();
  }

  void toggleFavorite(Conversation conversation) {
    if (_favoriteConversations.contains(conversation)) {
      _favoriteConversations.remove(conversation);
    } else {
      _favoriteConversations.add(conversation);
    }
    notifyListeners();
  }

  // Force UI refresh without any data changes
  void forceRefresh() {
    notifyListeners();
  }

  // Mark all messages in a conversation as read
  void markConversationAsRead(Conversation conversation) {
    bool changed = false;
    for (var message in conversation.messages) {
      if (!message.isRead) {
        message.isRead = true;
        _messageReadStatus[message.id] = true;
        changed = true;
      }
    }

    if (changed) {
      _saveReadStatus().then((_) {
        print('Read status saved for conversation ${conversation.id}'); // Debug log
        notifyListeners();
      });
    }
  }

  void markAllAsRead() {
    bool anyChanges = false;

    // Mark messages as read in main conversations
    for (var conversation in _conversations) {
      for (var message in conversation.messages) {
        if (!message.isRead) {
          message.isRead = true;
          _messageReadStatus[message.id] = true;
          anyChanges = true;
        }
      }
    }

    // Also mark messages as read in archived conversations
    for (var conversation in _archivedConversations) {
      for (var message in conversation.messages) {
        if (!message.isRead) {
          message.isRead = true;
          _messageReadStatus[message.id] = true;
          anyChanges = true;
        }
      }
    }

    if (anyChanges) {
      _saveReadStatus(); // Save read status immediately
      notifyListeners();
    }
  }

  // Get unread count for a conversation
  int getUnreadCount(Conversation conversation) {
    return conversation.messages.where((msg) => !msg.isRead).length;
  }

  // Get deletion time for a conversation
  DateTime? getDeletionTime(int conversationId) {
    return _deletedAtMap[conversationId.toString()];
  }

  // Add a new message to a conversation
  void addMessageToConversation(int conversationId, Message message) {
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      List<Message> updatedMessages = List.from(_conversations[index].messages)..add(message);
      _conversations[index] = _conversations[index].copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

  void syncFavoriteConversations() {
    _favoriteConversations.clear();

    // Add conversations that contain favorited messages
    for (var conversation in _conversations) {
      if (conversation.messages.any((message) => message.isFavorite)) {
        if (!_favoriteConversations.contains(conversation)) {
          _favoriteConversations.add(conversation);
        }
      }
    }

    // Also check archived conversations
    for (var conversation in _archivedConversations) {
      if (conversation.messages.any((message) => message.isFavorite)) {
        if (!_favoriteConversations.contains(conversation)) {
          _favoriteConversations.add(conversation);
        }
      }
    }
  }

  void toggleMessageFavorite(Message message) {
    bool updated = false;
    bool newFavoriteStatus = false;

    // Check all conversations
    for (var i = 0; i < _conversations.length; i++) {
      final messageIndex = _conversations[i].messages.indexWhere((m) => m.id == message.id);
      if (messageIndex != -1) {
        // Toggle favorite status and save the new status
        newFavoriteStatus = !_conversations[i].messages[messageIndex].isFavorite;

        final updatedMessage = _conversations[i].messages[messageIndex].copyWith(
          isFavorite: newFavoriteStatus,
        );

        // Update the message in the conversation
        final List<Message> updatedMessages = List.from(_conversations[i].messages);
        updatedMessages[messageIndex] = updatedMessage;

        // Create updated conversation
        _conversations[i] = _conversations[i].copyWith(
          messages: updatedMessages,
        );

        updated = true;
        break;
      }
    }

    // Also check archived conversations
    if (!updated) {
      for (var i = 0; i < _archivedConversations.length; i++) {
        final messageIndex = _archivedConversations[i].messages.indexWhere((m) => m.id == message.id);
        if (messageIndex != -1) {
          // Toggle favorite status and save the new status
          newFavoriteStatus = !_archivedConversations[i].messages[messageIndex].isFavorite;

          final updatedMessage = _archivedConversations[i].messages[messageIndex].copyWith(
            isFavorite: newFavoriteStatus,
          );

          // Update the message in the conversation
          final List<Message> updatedMessages = List.from(_archivedConversations[i].messages);
          updatedMessages[messageIndex] = updatedMessage;

          // Create updated conversation
          _archivedConversations[i] = _archivedConversations[i].copyWith(
            messages: updatedMessages,
          );

          updated = true;
          break;
        }
      }
    }

    if (updated) {
      // Update favorite conversations list
      syncFavoriteConversations();

      // Immediate UI update
      notifyListeners();

      // Schedule delayed update to ensure UI refreshes when returning to screens
      Future.delayed(const Duration(milliseconds: 100), () {
        notifyListeners();
      });
    }
  }

  // Get all favorited messages
  List<Message> getFavoritedMessages() {
    List<Message> favoriteMessages = [];

    // Check active conversations
    for (var conversation in _conversations) {
      favoriteMessages.addAll(
        conversation.messages.where((message) => message.isFavorite)
      );
    }

    // Check archived conversations
    for (var conversation in _archivedConversations) {
      favoriteMessages.addAll(
        conversation.messages.where((message) => message.isFavorite)
      );
    }

    return favoriteMessages;
  }

  void refreshConversations() async {
    if (!_isInitialized) {
      await _loadArchivedIds();
      await _loadDeletedIds();
      await _loadReadStatus();
      _isInitialized = true;
    }
  }

  Future<void> _saveArchivedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedIdsList = _persistentArchivedIds.toList();
      await prefs.setString(_archivedIdsKey, jsonEncode(archivedIdsList));
      print('Saved archived IDs: $archivedIdsList'); // Debug log
    } catch (e) {
      print('Error saving archived IDs: $e');
    }
  }

  Future<void> _loadArchivedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? archivedIdsJson = prefs.getString(_archivedIdsKey);
      if (archivedIdsJson != null) {
        final List<dynamic> archivedIds = jsonDecode(archivedIdsJson);
        _persistentArchivedIds.clear();
        _persistentArchivedIds.addAll(archivedIds.cast<int>());
        print('Loaded archived IDs: $_persistentArchivedIds'); // Debug log
      }
    } catch (e) {
      print('Error loading archived IDs: $e');
    }
  }

  Future<void> _saveDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIdsList = _persistentDeletedIds.toList();
      await prefs.setString(_deletedIdsKey, jsonEncode(deletedIdsList));
      print('Saved deleted IDs: $deletedIdsList'); // Debug log
    } catch (e) {
      print('Error saving deleted IDs: $e');
    }
  }

  Future<void> _loadDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? deletedIdsJson = prefs.getString(_deletedIdsKey);
      print('Loaded read status: $deletedIdsJson'); // Debug log

      if (deletedIdsJson != null) {
        final List<dynamic> deletedIds = jsonDecode(deletedIdsJson);
        _persistentDeletedIds.clear();
        _persistentDeletedIds.addAll(deletedIds.cast<int>());
        print('Loaded deleted IDs: $_persistentDeletedIds'); // Debug log
      }
    } catch (e) {
      print('Error loading deleted IDs: $e');
    }
  }

  Future<void> _saveReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> statusMap = {};

      // Convert int keys to strings for JSON serialization
      _messageReadStatus.forEach((key, value) {
        statusMap[key.toString()] = value;
      });

      final String jsonString = jsonEncode(statusMap);
      await prefs.setString(_readMessageIdsKey, jsonString);
      print('Saved read status: $jsonString'); // Debug log
    } catch (e) {
      print('Error saving read status: $e');
    }
  }

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? readStatusJson = prefs.getString(_readMessageIdsKey);
      print('Loaded read status: $readStatusJson'); // Debug log

      if (readStatusJson != null) {
        final Map<String, dynamic> readStatus = jsonDecode(readStatusJson);
        _messageReadStatus.clear();

        // Convert string keys back to int
        readStatus.forEach((key, value) {
          _messageReadStatus[int.parse(key)] = value;
        });

        // Apply read status to all conversations
        _applyReadStatus(_conversations);
        _applyReadStatus(_archivedConversations);
      }
    } catch (e) {
      print('Error loading read status: $e');
    }
  }

  // Add helper method to apply read status
  void _applyReadStatus(List<Conversation> conversations) {
    for (var conv in conversations) {
      for (var msg in conv.messages) {
        if (_messageReadStatus.containsKey(msg.id)) {
          msg.isRead = _messageReadStatus[msg.id]!;
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}