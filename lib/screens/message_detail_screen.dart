import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/conversation_model.dart' as model;

class MessageDetailScreen extends StatefulWidget {
  final model.Conversation conversation;

  const MessageDetailScreen({super.key, required this.conversation});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // Run after the first frame is built
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _markAllMessagesAsRead();
    });
  }

  void _markAllMessagesAsRead() {
    setState(() {
      for (int i = 0; i < widget.conversation.messages.length; i++) {
        if (!widget.conversation.messages[i].isRead) {
          widget.conversation.messages[i] = widget.conversation.messages[i].copyWith(isRead: true);
        }
      }
    });
  }

  // 🎨 Generate a consistent color based on the sender's name
  Color _generateColor(String sender) {
    final random = Random(sender.hashCode);
    return Color.fromRGBO(
      100 + random.nextInt(156), // Red (100–255)
      100 + random.nextInt(156), // Green (100–255)
      100 + random.nextInt(156), // Blue (100–255)
      1, // Full opacity
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderColor = _generateColor(widget.conversation.sender);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: senderColor, // 🔹 Consistent sender color
              child: Text(
                widget.conversation.sender[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.conversation.sender, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.conversation.messages.length,
          itemBuilder: (context, index) {
            final message = widget.conversation.messages[index];
            final bool isSentByUser = message.sender == "You"; // Modify as needed

            return Align(
              alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: message.isSpam
                      ? Colors.red.withAlpha((0.1 * 255).toInt())
                      : senderColor.withAlpha((0.1 * 255).toInt()), // 🔹 Use sender's color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.content, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5), // Add spacing before timestamp
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
