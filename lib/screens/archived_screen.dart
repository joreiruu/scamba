import 'package:flutter/material.dart';
import '../models/conversation_model.dart' as model;
import 'message_detail_screen.dart';
import 'package:intl/intl.dart';

class ArchivedScreen extends StatefulWidget {
  final List<model.Conversation> archivedConversations;
  final Function(List<model.Conversation>) onUpdate;
  final Function(List<model.Conversation>) onDelete; // NEW: Callback for deletion

  const ArchivedScreen({
    super.key,
    required this.archivedConversations,
    required this.onUpdate,
    required this.onDelete, // NEW: Pass delete handler from parent
  });

  @override
  ArchivedScreenState createState() => ArchivedScreenState();
}

class ArchivedScreenState extends State<ArchivedScreen> {
  Set<int> selectedConversations = {};
  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
  leading: IconButton(
    icon: Icon(selectionMode ? Icons.close : Icons.arrow_back),
    onPressed: () {
      if (selectionMode) {
        setState(() {
          selectedConversations.clear();
          selectionMode = false;
        });
      } else {
        Navigator.pop(context);
      }
    },
  ),
  title: selectionMode
      ? Row(
          children: [
            Text(
              "${selectedConversations.length} selected",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        )
      : const Text('Archived'),
  centerTitle: false,
  backgroundColor: isDarkMode ? const Color(0xFF23272A) : Colors.white,
  iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
  actions: selectionMode
      ? [
          IconButton(
            icon: const Icon(Icons.unarchive_outlined),
            onPressed: _unarchiveSelected,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: _deleteSelected,
          ),
        ]
      : [],
),


      body: widget.archivedConversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No archived messages',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: widget.archivedConversations.length,
              itemBuilder: (context, index) {
                final conversation = widget.archivedConversations[index];
                final lastMessage = conversation.messages.isNotEmpty
                    ? conversation.messages.last
                    : null;
                final isSelected = selectedConversations.contains(conversation.id);

                return Container(
                  color: isSelected ? Colors.blue.withAlpha(26) : null,
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.blue
                              : conversation.messages.isNotEmpty && conversation.messages.last.isSpam
                                  ? Colors.transparent
                                  : const Color(0xFF85BBD9),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : conversation.messages.isNotEmpty && conversation.messages.last.isSpam
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
                      ],
                    ),
                    title: Text(
                      conversation.sender,
                      style: TextStyle(
                        fontWeight: lastMessage != null && !lastMessage.isRead
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: lastMessage != null
                        ? Text(
                            lastMessage.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text("No messages"),
                    trailing: Text(
                      lastMessage != null ? _formatDate(lastMessage.timestamp) : "",
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      if (selectionMode) {
                        _toggleSelection(conversation.id);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageDetailScreen(conversation: conversation),
                          ),
                        );
                      }
                    },
                    onLongPress: () => _toggleSelection(conversation.id),
                  ),
                );
              },
            ),
    );
  }

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

  void _toggleSelection(int conversationId) {
    setState(() {
      if (selectedConversations.contains(conversationId)) {
        selectedConversations.remove(conversationId);
      } else {
        selectedConversations.add(conversationId);
      }
      selectionMode = selectedConversations.isNotEmpty;
    });
  }

  void _unarchiveSelected() {
    final List<model.Conversation> toUnarchive = widget.archivedConversations
        .where((conversation) => selectedConversations.contains(conversation.id))
        .toList();
    
    setState(() {
      widget.archivedConversations.removeWhere(
          (conversation) => selectedConversations.contains(conversation.id));
      selectedConversations.clear();
      selectionMode = false;
    });
    
    // Call the callback to update the parent state
    widget.onUpdate(toUnarchive);
  }

  void _deleteSelected() {
  final List<model.Conversation> toDelete = widget.archivedConversations
      .where((conversation) => selectedConversations.contains(conversation.id))
      .toList();

  setState(() {
    widget.archivedConversations.removeWhere(
      (conversation) => selectedConversations.contains(conversation.id),
    );
    selectedConversations.clear();
    selectionMode = false;
  });

  widget.onDelete(toDelete); // Notify parent to handle deleted messages
}

}