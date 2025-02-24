import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(Message) onMessageRead;

  const MessageItem({
    super.key,
    required this.message,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onMessageRead,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) {
      return "Today";
    } else if (difference < 7) {
      return DateFormat('EEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('d MMM').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasUnreadMessages = !message.isRead;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: message.isSpam ? Colors.red : Colors.blue,
        child: Text(
          message.sender[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        message.sender,
        style: TextStyle(
          fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        message.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDate(message.timestamp),
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (hasUnreadMessages)
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      tileColor: isSelected ? Colors.blue.withAlpha(75) : null,
      onTap: () {
        if (!message.isRead) {
          onMessageRead(message); // ✅ Ensure it updates read status correctly
        }
        onTap();
      },
    );
  }
}
