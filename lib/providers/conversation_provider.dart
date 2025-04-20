import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/sms_service.dart';

class ConversationProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  final List<Conversation> _deletedConversations = [];
  List<Conversation> _archivedConversations = [];
  final List<Conversation> _favoriteConversations = [];
  final Map<String, DateTime> _deletedAtMap = {};
  final SmsService _smsService = SmsService();
  final Map<int, bool> _messageReadStatus = {};
  StreamSubscription? _subscription;

  static const refreshInterval = Duration(seconds: 5);
  Timer? _autoRefreshTimer;

  // Add these keys for SharedPreferences
  static const String _archivedIdsKey = 'archived_conversation_ids';
  static const String _readMessageIdsKey = 'read_message_ids';

  // Add a flag to track initial load
  bool _isInitialized = false;
  final Set<int> _persistentArchivedIds = {};

  ConversationProvider() {
    // Load saved states immediately
    Future(() async {
      await _loadArchivedIds();
      await _loadReadStatus();
      await refreshConversations();
      notifyListeners();
    });

    // Set up auto-refresh
    _autoRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      await refreshConversations();
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
  void loadConversations(List<Conversation> newConversations) {
    _preserveReadStatus(newConversations);
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
    _deletedAtMap[conversation.id.toString()] = DateTime.now();
    notifyListeners();
  }

  // Restore a deleted conversation
  void restoreDeletedConversation(Conversation conversation) {
    _deletedConversations.removeWhere((conv) => conv.id == conversation.id);
    _conversations.add(conversation);
    _deletedAtMap.remove(conversation.id.toString());
    notifyListeners();
  }

  // Restore an archived conversation
  void restoreArchivedConversation(Conversation conversation) {
    if (_persistentArchivedIds.contains(conversation.id)) {
      _persistentArchivedIds.remove(conversation.id);
      _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
      _conversations.add(conversation);
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

  Future<void> refreshConversations() async {
    try {
      // Only load saved states on first initialization
      if (!_isInitialized) {
        await _loadArchivedIds();
        await _loadReadStatus();
        _isInitialized = true;
      }

      final conversations = await _smsService.getConversations();
      if (conversations != null) {
        final newConversations = <Conversation>[];
        final newArchivedConversations = <Conversation>[];

        for (var conv in conversations) {
          // Apply existing read status
          for (var msg in conv.messages) {
            if (_messageReadStatus.containsKey(msg.id)) {
              msg.isRead = _messageReadStatus[msg.id]!;
            }
          }

          if (_persistentArchivedIds.contains(conv.id)) {
            newArchivedConversations.add(conv);
          } else {
            newConversations.add(conv);
          }
        }

        if (!_areListsEqual(_conversations, newConversations) ||
            !_areListsEqual(_archivedConversations, newArchivedConversations)) {
          _conversations = newConversations;
          _archivedConversations = newArchivedConversations;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error refreshing conversations: $e');
    }
  }

  // Helper method to compare lists
  bool _areListsEqual(List<Conversation> list1, List<Conversation> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Future<void> _saveArchivedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archivedIdsKey, jsonEncode(_persistentArchivedIds.toList()));
  }

  Future<void> _loadArchivedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String? archivedIdsJson = prefs.getString(_archivedIdsKey);
    if (archivedIdsJson != null) {
      final List<dynamic> archivedIds = jsonDecode(archivedIdsJson);
      // Filter conversations to archived and non-archived
      _archivedConversations = _conversations
          .where((conv) => archivedIds.contains(conv.id))
          .toList();
      _conversations = _conversations
          .where((conv) => !archivedIds.contains(conv.id))
          .toList();
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