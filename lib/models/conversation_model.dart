import 'package:scamba/models/message_model.dart';

class Conversation {
  final int id;
  final String sender;
  final List<Message> messages;
  final bool isFavorite;

  Conversation({
    required this.id,
    required this.sender,
    required this.messages,
    this.isFavorite = false,
  });

  /// ✅ Get the count of unread messages
  int get unreadCount => messages.where((msg) => !msg.isRead).length;

  /// ✅ Get the timestamp of the last message
  DateTime? get lastMessageTimestamp => messages.isNotEmpty ? messages.last.timestamp : null;

  /// ✅ Check if the conversation contains spam messages
  bool get hasSpam => messages.any((msg) => msg.isSpam);

  /// ✅ Create a copy of the conversation with updated messages
  Conversation copyWith({List<Message>? messages, int? unreadCount, bool? isFavorite}) {
    return Conversation(
      id: id,
      sender: sender,
      messages: messages ?? this.messages,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
