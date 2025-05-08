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
  Timer? _newMessageCheckTimer;

  // Add these keys for SharedPreferences
  static const String _archivedIdsKey = 'archived_conversation_ids';
  static const String _readMessageIdsKey = 'read_message_ids';
  static const String _deletedIdsKey = 'deleted_conversation_ids';

  // Add flags to track initial load
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Set<int> _persistentArchivedIds = {};
  final Set<int> _persistentDeletedIds = {};
  bool _isClassifying = false;

  ConversationProvider() {
    // Initial load and classification
    _initializeProvider();

    // Start periodic refresh
    _autoRefreshTimer = Timer.periodic(refreshInterval, (_) {
      _smsService.refreshConversations();
    });
  }

  Future<void> _handleNewConversations(List<Conversation> newConversations) async {
    final existingConvs = Map<int, Conversation>.fromEntries(
      _conversations.map((c) => MapEntry(c.id, c))
    );

    var updatedConvs = <Conversation>[];
    bool hasChanges = false;

    for (var conv in newConversations) {
      final existing = existingConvs[conv.id];
      if (existing != null) {
        final existingMsgIds = existing.messages.map((m) => m.id).toSet();
        final newMessages = conv.messages.where((m) => !existingMsgIds.contains(m.id)).toList();
        
        if (newMessages.isNotEmpty) {
          hasChanges = true;
          final allMessages = [...existing.messages, ...newMessages]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          updatedConvs.add(existing.copyWith(messages: allMessages));
        } else {
          updatedConvs.add(existing);
        }
      } else {
        hasChanges = true;
        updatedConvs.add(conv);
      }
    }

    if (hasChanges) {
      _preserveReadStatus(updatedConvs);
      _updateConversationLists(updatedConvs);
      await _classifyNewMessages(updatedConvs);
      notifyListeners();
    }
  }

  Future<void> _classifyNewMessages(List<Conversation> conversations) async {
    if (_isClassifying) return;
    _isClassifying = true;

    try {
      for (var conversation in conversations) {
        final unclassifiedMessages = conversation.messages
            .where((msg) => !msg.isClassified)
            .toList();

        for (var message in unclassifiedMessages) {
          try {
            final result = await _classifier.classifyMessage(message);
            if (!result.containsKey('error')) {
              message.isSpam = result['predicted_class'] == 1;
              message.spamConfidence = result['confidence'];
              message.isClassified = true;

              await _db.storeClassification(
                messageId: message.id.toString(),
                isSpam: message.isSpam,
                confidence: message.spamConfidence,
              );
              
              notifyListeners(); // Update UI after each classification
            }
          } catch (e) {
            print('Error classifying message: $e');
          }
        }
      }
    } finally {
      _isClassifying = false;
    }
  }

  Future<void> _initializeProvider() async {
    await _loadReadStatus();
    await _loadDeletedIds();
    await _loadReadStatus();

    // Get initial messages
    final initialConversations = await _smsService.getConversations();
    await loadConversations(initialConversations);

    // Listen for updates
    _subscription = _smsService.conversationsStream.listen((conversations) async {
      await _updateConversations(conversations);
    });
  }

  Future<void> _updateConversations(List<Conversation> newConversations) async {
    // Preserve existing states
    final existingMessages = Map<int, Message>.fromEntries(
      _conversations.expand((c) => c.messages).map((m) => MapEntry(m.id, m))
    );

    // Update conversations while preserving states
    _conversations = newConversations.map((conv) {
      return conv.copyWith(
        messages: conv.messages.map((msg) {
          final existing = existingMessages[msg.id];
          if (existing != null) {
            return msg.copyWith(
              isClassified: existing.isClassified,
              isSpam: existing.isSpam,
              spamConfidence: existing.spamConfidence,
              isRead: existing.isRead,
            );
          }
          return msg;
        }).toList(),
      );
    }).toList();

    // Immediately start classification for new messages
    final newMessages = _conversations
        .expand((conv) => conv.messages)
        .where((msg) => msg.isNew && !msg.isClassified)
        .toList();

    if (newMessages.isNotEmpty) {
      for (var message in newMessages) {
        try {
          final result = await _classifier.classifyMessage(message);
          if (!result.containsKey('error')) {
            message.isSpam = result['predicted_class'] == 1;
            message.spamConfidence = result['confidence'];
            message.isClassified = true;

            await _db.storeClassification(
              messageId: message.id.toString(),
              isSpam: message.isSpam,
              confidence: message.spamConfidence,
            );

            // Force UI update after each classification
            notifyListeners();
          }
        } catch (e) {
          print('Error classifying message: $e');
        }
      }
    }

    // Final UI update
    notifyListeners();
  }

  Future<void> _loadClassificationForMessage(Message message) async {
    final storedClassification = await _db.getClassification(message.id.toString());
    if (storedClassification != null) {
      message.isSpam = storedClassification['is_spam'] == 1;
      message.spamConfidence = storedClassification['confidence'];
      message.isClassified = true;
    }
  }

  void _updateConversationLists(List<Conversation> conversations) {
    final mainConversations = <Conversation>[];
    final archivedConvs = <Conversation>[];
    final deletedConvs = <Conversation>[];

    for (var conversation in conversations) {
      if (_persistentDeletedIds.contains(conversation.id)) {
        deletedConvs.add(conversation);
      } else if (_persistentArchivedIds.contains(conversation.id)) {
        archivedConvs.add(conversation);
      } else {
        mainConversations.add(conversation);
      }
    }

    _conversations = mainConversations;
    _archivedConversations = archivedConvs;
    _deletedConversations = deletedConvs;
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
    if (_isInitialized) return; // Prevent reloading if already initialized
    
    // Clear existing conversations to prevent duplication
    _conversations.clear();
    _archivedConversations.clear();
    _deletedConversations.clear();

    // Load saved states first
    await _loadArchivedIds();
    await _loadDeletedIds();
    await _loadReadStatus();

    // Process each conversation based on its state
    for (var conversation in newConversations) {
      if (_persistentDeletedIds.contains(conversation.id)) {
        _deletedConversations.add(conversation);
      } else if (_persistentArchivedIds.contains(conversation.id)) {
        _archivedConversations.add(conversation);
      } else {
        _conversations.add(conversation);
      }

      // Load stored classifications for each message
      for (var message in conversation.messages) {
        final storedClassification = await _db.getClassification(message.id.toString());
        if (storedClassification != null) {
          message.isSpam = storedClassification['is_spam'] == 1;
          message.spamConfidence = storedClassification['confidence'];
          message.isClassified = true;
        }
      }
    }

    notifyListeners();

    // Only classify unclassified messages
    classifyMessagesInBackground(newConversations);
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
      for (var conversation in conversations) {
        final unclassifiedMessages = conversation.messages
            .where((msg) => !msg.isClassified)
            .toList();

        for (var message in unclassifiedMessages) {
          final result = await _classifier.classifyMessage(message);
          if (!result.containsKey('error')) {
            message.isSpam = result['predicted_class'] == 1;
            message.spamConfidence = result['confidence'];
            message.isClassified = true;

            await _db.storeClassification(
              messageId: message.id.toString(),
              isSpam: message.isSpam,
              confidence: message.spamConfidence,
            );

            notifyListeners(); // Update UI after each classification
          }
        }
      }
    } finally {
      _isClassifying = false;
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

  void archiveConversation(Conversation conversation) {
    print('Archiving conversation: ${conversation.id}');
    if (!_persistentArchivedIds.contains(conversation.id)) {
      // First remove from main conversations to prevent duplication
      _conversations.removeWhere((conv) => conv.id == conversation.id);

      // Only add to archived if not already present
      if (!_archivedConversations.any((conv) => conv.id == conversation.id)) {
        _persistentArchivedIds.add(conversation.id);
        _archivedConversations.add(conversation);
      }

      _saveArchivedIds().then((_) {
        notifyListeners();
      });
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
    if (_persistentDeletedIds.contains(conversation.id)) {
      _deletedConversations.removeWhere((conv) => conv.id == conversation.id);
      _persistentDeletedIds.remove(conversation.id);

      // Check if conversation already exists to prevent duplicates
      if (!_conversations.any((conv) => conv.id == conversation.id)) {
        // Insert the conversation in the correct chronological position
        final insertIndex = _conversations.indexWhere(
          (conv) => conv.lastMessageTime.compareTo(conversation.lastMessageTime) < 0
        );

        if (insertIndex == -1) {
          _conversations.insert(0, conversation); // Add to beginning if newest
        } else {
          _conversations.insert(insertIndex, conversation);
        }
      }

      _saveDeletedIds();
      notifyListeners();
    }
  }

  void restoreArchivedConversation(Conversation conversation) {
    if (_persistentArchivedIds.contains(conversation.id)) {
      _persistentArchivedIds.remove(conversation.id);
      _archivedConversations.removeWhere((conv) => conv.id == conversation.id);

      // Check if conversation already exists to prevent duplicates
      if (!_conversations.any((conv) => conv.id == conversation.id)) {
        // Insert the conversation in the correct chronological position
        final insertIndex = _conversations.indexWhere(
          (conv) => conv.lastMessageTime.compareTo(conversation.lastMessageTime) < 0
        );

        if (insertIndex == -1) {
          _conversations.insert(0, conversation); // Add to beginning if newest
        } else {
          _conversations.insert(insertIndex, conversation);
        }
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
    // Remove old references to prevent duplicates
    _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
    _conversations.removeWhere((conv) => conv.id == conversation.id);

    // Insert the conversation in the correct chronological position
    final insertIndex = _conversations.indexWhere(
      (conv) => conv.lastMessageTime.compareTo(conversation.lastMessageTime) < 0
    );

    if (insertIndex == -1) {
      _conversations.insert(0, conversation); // Add to beginning if newest
    } else {
      _conversations.insert(insertIndex, conversation);
    }

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
  Future<void> markConversationAsRead(Conversation conversation) async {
    bool changed = false;
    for (var message in conversation.messages) {
      if (!message.isRead) {
        message.isRead = true;
        _messageReadStatus[message.id] = true;
        changed = true;
      }
    }

    if (changed) {
      await _saveReadStatus(); // Wait for save to complete
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
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
      await _saveReadStatus(); // Wait for save to complete
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
    
    // Check active conversations
    for (var i = 0; i < _conversations.length; i++) {
      final messageIndex = _conversations[i].messages.indexWhere((m) => m.id == message.id);
      if (messageIndex != -1) {
        newFavoriteStatus = !_conversations[i].messages[messageIndex].isFavorite;
        
        final updatedMessage = _conversations[i].messages[messageIndex].copyWith(
          isFavorite: newFavoriteStatus
        );
        
        final List<Message> updatedMessages = List.from(_conversations[i].messages);
        updatedMessages[messageIndex] = updatedMessage;
        
        _conversations[i] = _conversations[i].copyWith(messages: updatedMessages);
        updated = true;
        break;
      }
    }

    // Also check archived conversations
    if (!updated) {
      for (var i = 0; i < _archivedConversations.length; i++) {
        final messageIndex = _archivedConversations[i].messages.indexWhere((m) => m.id == message.id);
        if (messageIndex != -1) {
          newFavoriteStatus = !_archivedConversations[i].messages[messageIndex].isFavorite;
          
          final updatedMessage = _archivedConversations[i].messages[messageIndex].copyWith(
            isFavorite: newFavoriteStatus
          );
          
          final List<Message> updatedMessages = List.from(_archivedConversations[i].messages);
          updatedMessages[messageIndex] = updatedMessage;
          
          _archivedConversations[i] = _archivedConversations[i].copyWith(messages: updatedMessages);
          updated = true;
          break;
        }
      }
    }

    if (updated) {
      syncFavoriteConversations();
      notifyListeners();
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

  Future<void> refreshConversations() async {
    print('Manual refresh requested'); // Debug log
    await _smsService.refreshConversations();
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

  // For manual full refresh
  Future<void> forceFullRefresh() async {
    final conversations = await _smsService.getConversations(loadMore: false);
    await _updateConversations(conversations);
  }

  @override
  void dispose() {
    _newMessageCheckTimer?.cancel();
    _subscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}