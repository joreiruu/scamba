import 'package:scamba/models/message_model.dart';

class Conversation {
  final int id;
  final String sender;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.sender,
    required this.messages,
  });

  int get unreadCount => messages.where((msg) => !msg.isRead).length;

  // ✅ Get the timestamp of the last message
  DateTime? get lastMessageTimestamp => messages.isNotEmpty ? messages.last.timestamp : null;

  // ✅ Added copyWith to allow safe updates
  Conversation copyWith({List<Message>? messages}) {
    return Conversation(
      id: id,
      sender: sender,
      messages: messages ?? this.messages,
    );
  }
}
