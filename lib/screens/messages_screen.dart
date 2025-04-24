import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sms_service.dart';
import '../services/spam_classifier_service.dart';
import '../models/conversation_model.dart';
import '../providers/conversation_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SmsService _smsService = SmsService();
  final SpamClassifierService _classifier = SpamClassifierService();
  List<Conversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ConversationProvider>(context, listen: false).forceRefresh();
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _smsService.getConversations();
      
      // Classify each message
      for (var conversation in conversations) {
        for (var message in conversation.messages) {
          final result = await _classifier.classifyMessage(message); // Pass the message object instead of message.content
          
          if (!result.containsKey('error')) {
            final isSpam = result['predicted_class'] == 1;
            final confidence = result['confidence'];
            
            // Update message with spam classification
            message = message.copyWith(
              isSpam: isSpam,
              spamConfidence: confidence,
              isClassified: true, // Mark as classified
            );
          }
        }
      }

      setState(() => _conversations = conversations);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _conversations.length,
            itemBuilder: (context, index) {
              final conversation = _conversations[index];
              final lastMessage = conversation.messages.last;
              final isSpam = lastMessage.spamConfidence >= 50.0;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSpam ? Colors.red : Colors.green,
                  child: Text(
                    isSpam ? 'S' : 'H',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(conversation.sender)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSpam 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSpam 
                          ? 'SPAM (${lastMessage.spamConfidence.toStringAsFixed(1)}%)'
                          : 'HAM (${lastMessage.spamConfidence.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: isSpam ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  lastMessage.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTimestamp(lastMessage.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}