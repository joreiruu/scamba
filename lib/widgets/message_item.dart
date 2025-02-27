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
    return DateFormat('h:mm a').format(date);  // Shows time if today
  } else if (difference < 7) {
    return DateFormat('EEE').format(date);  // Shows day (Mon, Tue)
  } else if (date.year == now.year) {
    return DateFormat('d MMM').format(date);  // Shows '26 Feb'
  } else {
    return DateFormat('dd/MM/yyyy').format(date);  // Shows full date
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

      ////////
      
      trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.end, // ✅ Ensures right alignment
  children: [
    Text(
      _formatDate(message.timestamp),
      style: TextStyle(
        fontSize: 12,
        fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
      ),
    ),
    if (!message.isRead)
      Container(
        margin: const EdgeInsets.only(top: 5), // ✅ Adds spacing
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          conversation.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
  ],
),

   
      ////////
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
