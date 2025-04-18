import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ConversationProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  final List<Conversation> _deletedConversations = [];
  final List<Conversation> _archivedConversations = [];
  final List<Conversation> _favoriteConversations = [];
  final Map<String, DateTime> _deletedAtMap = {};
                                                                                                                                                                                                                                                                                                                              
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
    _conversations = newConversations;
    notifyListeners();
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
    _conversations.removeWhere((conv) => conv.id == conversation.id);
    _archivedConversations.add(conversation);
    notifyListeners();
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
    _archivedConversations.removeWhere((conv) => conv.id == conversation.id);
    _conversations.add(conversation);
    notifyListeners();
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
    final index = _conversations.indexWhere((conv) => conv.id == conversation.id);
    if (index != -1) {
      List<Message> updatedMessages = _conversations[index]
          .messages
          .map((message) => message.copyWith(isRead: true))
          .toList();

      _conversations[index] = _conversations[index].copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

// In your ConversationProvider class
void markAllAsRead() {
  bool anyChanges = false;
  
  // Loop through all conversations
  for (var i = 0; i < _conversations.length; i++) {
    // Check if there are any unread messages in this conversation
    bool hasUnreadMessages = _conversations[i].messages.any((msg) => !msg.isRead);
    
    if (hasUnreadMessages) {
      // Create new list of all read messages
      List<Message> updatedMessages = _conversations[i].messages.map((message) => 
        message.isRead ? message : message.copyWith(isRead: true)
      ).toList();
      
      // Update the conversation with all read messages
      _conversations[i] = _conversations[i].copyWith(messages: updatedMessages);
      anyChanges = true;
    }
  }
  
  // Only notify if changes were made
  if (anyChanges) {
    notifyListeners();
  }
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

  // In conversation_provider.dart
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
}