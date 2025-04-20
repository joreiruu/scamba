import 'package:flutter/material.dart';
import '../models/conversation_model.dart' as model;
import '../models/message_model.dart';
import 'message_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';

class ArchivedScreen extends StatefulWidget {
  final List<model.Conversation> archivedConversations;
  final Function(List<model.Conversation>) onUpdate;
  final Function(List<model.Conversation>) onDelete;

  const ArchivedScreen({
    super.key,
    required this.archivedConversations,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ArchivedScreenState createState() => ArchivedScreenState();
}

class ArchivedScreenState extends State<ArchivedScreen> {
  bool selectionMode = false;
  Set<int> selectedConversations = {};

  void _toggleSelection(int id) {
    setState(() {
      if (selectedConversations.contains(id)) {
        selectedConversations.remove(id);
        if (selectedConversations.isEmpty) {
          selectionMode = false;
        }
      } else {
        selectedConversations.add(id);
        selectionMode = true;
      }
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(date);
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MM/dd/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived'),
        backgroundColor: isDarkMode ? null : const Color(0xFF85BBD9),
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.unarchive),
                  onPressed: () {
                    final provider = Provider.of<ConversationProvider>(context, listen: false);
                    for (final id in selectedConversations) {
                      final conversation = provider.archivedConversations
                          .firstWhere((conv) => conv.id == id);
                      provider.restoreArchivedConversation(conversation);
                    }
                    setState(() {
                      selectedConversations.clear();
                      selectionMode = false;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    final provider = Provider.of<ConversationProvider>(context, listen: false);
                    for (final id in selectedConversations) {
                      final conversation = provider.archivedConversations
                          .firstWhere((conv) => conv.id == id);
                      provider.deleteConversation(conversation);
                    }
                    setState(() {
                      selectedConversations.clear();
                      selectionMode = false;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: Consumer<ConversationProvider>(
        builder: (context, provider, child) {
          final archivedConversations = provider.archivedConversations;

          if (archivedConversations.isEmpty) {
            return Center(
              child: Text(
                'No archived conversations',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: archivedConversations.length,
            itemBuilder: (context, index) {
              final conversation = archivedConversations[index];
              final lastMessage = conversation.messages.isNotEmpty
                  ? conversation.messages.last
                  : null;
              
              return ListTile(
                selected: selectedConversations.contains(conversation.id),
                selectedTileColor: isDarkMode 
                    ? Colors.blueGrey.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.1),
                onLongPress: () => _toggleSelection(conversation.id),
                onTap: selectionMode
                    ? () => _toggleSelection(conversation.id)
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageDetailScreen(
                              conversation: conversation,
                            ),
                          ),
                        );
                      },
                leading: CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.blueGrey : const Color(0xFF85BBD9),
                  child: Text(
                    conversation.sender?[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                title: Text(
                  conversation.sender ?? "Unknown",
                  style: TextStyle(
                    fontWeight: lastMessage?.isRead == false ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMessage?.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(lastMessage?.timestamp ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    if (lastMessage?.isRead == false)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.lightBlueAccent : const Color(0xFF85BBD9),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}