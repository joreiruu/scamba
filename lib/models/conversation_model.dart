import 'package:scamba/models/message_model.dart';

class Conversation {
  final int id;
  final String sender;
  List<Message> messages;

  Conversation({
    required this.id,
    required this.sender,
    required List<Message> messages,
  }) : messages = messages..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Keep oldest to newest for processing

  Message get latestMessage => messages.last;
  DateTime get lastMessageTime => messages.last.timestamp;
  int get unreadCount => messages.where((m) => !m.isRead).length;

  // This getter maintains UI design - messages display from bottom to top
  List<Message> get orderedMessages => messages.reversed.toList();

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
