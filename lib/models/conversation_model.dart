import 'package:scamba/models/message_model.dart';

class Conversation {
  final int id;
  final String sender;
  List<Message> messages;

  Conversation({
    required this.id,
    required this.sender,
    required List<Message> messages,
  }) : messages = messages..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort newest to oldest

  Message get latestMessage => messages.first; // Changed from last to first
  DateTime get lastMessageTime => messages.first.timestamp; // Changed from last to first
  int get unreadCount => messages.where((m) => !m.isRead).length;

  bool get hasSpamMessages => messages.any((msg) => msg.isSpam);
  
  Message? get lastSpamMessage {
    try {
      return messages.firstWhere((msg) => msg.isSpam);
    } catch (e) {
      return null;
    }
  }

  Conversation copyWith({
    int? id,
    String? sender,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      messages: messages ?? List<Message>.from(this.messages),
    );
  }
}
