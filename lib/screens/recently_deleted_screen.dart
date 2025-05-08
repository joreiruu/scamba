import 'package:flutter/material.dart';
import '../models/conversation_model.dart' as model;
import 'message_detail_screen.dart';
import 'package:intl/intl.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  final List<model.Conversation> deletedConversations;
  final Function(List<model.Conversation>) onRestoreConversations;

  const RecentlyDeletedScreen({
    super.key,
    required this.deletedConversations,
    required this.onRestoreConversations,
  });

  @override
  RecentlyDeletedScreenState createState() => RecentlyDeletedScreenState();
}

class RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  Set<int> selectedItems = {};
  bool selectionMode = false;
  final Map<int, DateTime> deletedAtMap = {}; // Track deletion timestamps

  @override
  void initState() {
    super.initState();
    // Initialize deletion dates for existing conversations
    // This assumes deleted conversations were just deleted now if no timestamp exists
    for (var conversation in widget.deletedConversations) {
      if (!deletedAtMap.containsKey(conversation.id)) {
        deletedAtMap[conversation.id] = DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
  leading: IconButton(
    icon: Icon(selectionMode ? Icons.close_outlined : Icons.arrow_back_outlined),
    onPressed: () {
      if (selectionMode) {
        setState(() {
          selectedItems.clear();
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
              "${selectedItems.length} selected",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.restore_outlined),
              onPressed: _restoreSelected,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              onPressed: _permanentlyDeleteSelected,
            ),
          ],
        )
      : const Text('Recently Deleted'),
  centerTitle: false,
  backgroundColor: isDarkMode ? const Color(0xFF23272A) : Colors.white,
  iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
  actions: [],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        'Items will be permanently deleted after 30 days',
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    ),
  ),
),

      body: _buildConversationsList(),
    );
  }

  Widget _buildConversationsList() {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    if (widget.deletedConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline, // Already outlined
              size: 64,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No deleted conversations',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.deletedConversations.length,
      itemBuilder: (context, index) {
        final conversation = widget.deletedConversations[index];
        final lastMessage = conversation.messages.isNotEmpty
            ? conversation.messages.last
            : null;
        final isSelected = selectedItems.contains(conversation.id);

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
                      ? const Icon(Icons.check_outlined, color: Colors.white)
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
            title: Text(conversation.sender),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                lastMessage != null
                    ? Text(
                        lastMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text("No messages"),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMessage != null ? _formatDate(lastMessage.timestamp) : "",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeRemainingText(conversation.id),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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

  String _getTimeRemainingText(int conversationId) {
    final deletedDate = deletedAtMap[conversationId] ?? DateTime.now();
    final daysLeft = 30 - DateTime.now().difference(deletedDate).inDays;
    
    if (daysLeft <= 1) {
      return '1 day left';
    } else {
      return '$daysLeft days left';
    }
  }

  void _toggleSelection(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
      selectionMode = selectedItems.isNotEmpty;
    });
  }

  void _restoreSelected() {
    final List<model.Conversation> toRestore = widget.deletedConversations
        .where((conversation) => selectedItems.contains(conversation.id))
        .toList();
    
    setState(() {
      widget.deletedConversations.removeWhere(
          (conversation) => selectedItems.contains(conversation.id));
      selectedItems.clear();
      selectionMode = false;
    });
    
    widget.onRestoreConversations(toRestore);
  }

  void _permanentlyDeleteSelected() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to permanently delete the selected conversations? This action cannot be undone.'),
        actions: [
          TextButton(
  onPressed: () => Navigator.pop(context), // Cancel
  style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF85BBD9), // Set text color
  ),
  child: const Text('Cancel'),
),

          TextButton(
            onPressed: () {
              setState(() {
                widget.deletedConversations.removeWhere(
                  (conversation) => selectedItems.contains(conversation.id),
                );
                selectedItems.clear();
                selectionMode = false;
              });
              Navigator.pop(context); // Close dialog
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}

}