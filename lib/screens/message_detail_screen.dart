// screens/message_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';

class MessageDetailScreen extends StatefulWidget {
  final Message message;
  final Function(Message) onMessageRead;

  const MessageDetailScreen({super.key, required this.message, required this.onMessageRead});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markMessageAsRead();
  }

  void _markMessageAsRead() {
    if (!widget.message.isRead) {
      widget.onMessageRead(widget.message.copyWith(isRead: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Message Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${widget.message.sender}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(widget.message.content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}