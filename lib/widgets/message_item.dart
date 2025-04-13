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
  final Function(Message) onLongPress;
  
  const MessageItem({
    super.key,
    required this.message,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onMessageRead,
    required this.onLongPress,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return DateFormat('h:mm a').format(date);
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

    return GestureDetector(
      onLongPress: () => onLongPress(message),
      child: Stack(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: conversation.messages.isNotEmpty && conversation.messages.last.isSpam
                  ? Colors.transparent
                  : const Color(0xFF85BBD9),
              child: conversation.messages.isNotEmpty && conversation.messages.last.isSpam
                  ? ClipOval(
                      child: Image.asset(
                        'assets/warning_icon.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Text(
                      conversation.sender[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
            title: Text(
              message.sender,
              style: TextStyle(
                fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Row(
              children: [
                // Use Expanded to ensure text doesn't overflow when heart is present
                Expanded(
                  child: Text(
                    message.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // Add some space for the heart icon if it's a favorite
                if (message.isFavorite) SizedBox(width: 20)
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
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
                    margin: const EdgeInsets.only(top: 5),
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
            tileColor: isSelected ? Colors.blue.withAlpha(75) : null,
            onTap: () {
              if (!message.isRead) {
                onMessageRead(message);
              }
              onTap();
            },
          ),
          
          // Heart icon positioned at the right side of the subtitle text
          if (message.isFavorite)
            Positioned(
              bottom: 14, // Adjust this value to position vertically
              right: 75, // Adjust this value to position horizontally
              child: Icon(
                Icons.favorite,
                size: 16,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}