import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'; // Add for clipboard functionality
import '../models/conversation_model.dart' as model;
import '../models/message_model.dart'; // Import Message model
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/selection_bar.dart'; // Import the selection bar
import 'package:flutter_linkify/flutter_linkify.dart'; // Import for linkify functionality
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs

class MessageDetailScreen extends StatefulWidget {
  final model.Conversation conversation;

  const MessageDetailScreen({super.key, required this.conversation});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final Random _random = Random();
  List<Message> selectedMessages = []; // Track selected messages
  bool isSelectionMode = false; // Track if in selection mode

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

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today, show only time
      return DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${DateFormat('h:mm a').format(timestamp)}';
    } else if (now.difference(timestamp).inDays < 7) {
      // Within last week
      return '${DateFormat('EEEE').format(timestamp)} ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      // Older messages
      return DateFormat('MMM d, y h:mm a').format(timestamp);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _markAllMessagesAsRead();
    });
  }

  void _handleLongPress(Message message) {
    setState(() {
      isSelectionMode = true;
      if (!selectedMessages.contains(message)) {
        selectedMessages.add(message);
      }
    });
  }

  void _toggleMessageSelection(Message message) {
    setState(() {
      if (selectedMessages.contains(message)) {
        selectedMessages.remove(message);
        if (selectedMessages.isEmpty) {
          isSelectionMode = false; // Exit selection mode if no messages selected
        }
      } else {
        selectedMessages.add(message);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      selectedMessages.clear();
      isSelectionMode = false;
    });
  }

  void _copySelectedMessages() {
    final String textToCopy = selectedMessages
        .map((message) => message.content)
        .join('\n\n');
    Clipboard.setData(ClipboardData(text: textToCopy));
    
    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Color(0xFF85BBD9), // Custom background color
      ),
    );
    
    _cancelSelection(); // Exit selection mode after copying
  }

  void _markAllMessagesAsRead() {
    // Use the provider to mark conversation as read
    Provider.of<ConversationProvider>(context, listen: false)
        .markConversationAsRead(widget.conversation);
  }

  double _generateSpamConfidence() {
    return _random.nextDouble() * 0.8;
  }

  void _showMoreOptions(BuildContext context) {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    final isArchived = provider.archivedConversations
        .any((conv) => conv.id == widget.conversation.id);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isArchived ? Icons.unarchive : Icons.archive,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                if (isArchived) {
                  provider.restoreArchivedConversation(widget.conversation);
                } else {
                  provider.archiveConversation(widget.conversation);
                }
                Navigator.pop(context); // Close bottom sheet
                Navigator.pop(context); // Return to previous screen

                // Show snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isArchived ? 'Conversation unarchived' : 'Conversation archived'),
                    backgroundColor: const Color(0xFF85BBD9),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        if (isArchived) {
                          provider.archiveConversation(widget.conversation);
                        } else {
                          provider.restoreArchivedConversation(widget.conversation);
                        }
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _showDeleteConfirmation(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This can be undone from Recently Deleted.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              final provider = Provider.of<ConversationProvider>(context, listen: false);
              provider.deleteConversation(widget.conversation);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
              
              // Show snackbar with undo option
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Conversation deleted'),
                  backgroundColor: const Color(0xFF85BBD9),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      provider.restoreDeletedConversation(widget.conversation);
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleFavoriteAndExitSelection(Message message) {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    provider.toggleMessageFavorite(message);

    // Show snackbar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isFavorite ? 'Removed from favorites' : 'Added to favorites',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF85BBD9),
      ),
    );
    
    setState(() {
      selectedMessages.clear();
      isSelectionMode = false;
    });
  }

  Color _getMessageColor(Message message, bool isDarkMode, bool isSelected) {
    if (isSelected) {
      return Color.fromRGBO(33, 150, 243, 0.3);
    }
    
    if (message.isFavorite) {
      return isDarkMode ? Colors.pink[900]! : Colors.pink[50]!;
    }
    
    if (!message.isClassified) {
      return isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    }
    
    return message.isSpam 
        ? (isDarkMode ? Colors.red[900]! : Colors.red[100]!)
        : (isDarkMode ? Colors.blue[900]! : Colors.blue[50]!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Message Bubble Colors
    final Color spamBgColor = isDarkMode ? Colors.red[900]! : Colors.red[100]!;
    final Color spamTextColor = isDarkMode ? Colors.white : Colors.red[900]!;
    final Color hamBgColor = isDarkMode ? Colors.blueGrey[800]! : Colors.blue[100]!;
    final Color hamTextColor = isDarkMode ? Colors.white : Colors.blue[900]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isSelectionMode 
    ? AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: SelectionBar(
          selectedMessages: selectedMessages,
          onCopy: _copySelectedMessages,
          onCancel: _cancelSelection,
          onToggleFavorite: _toggleFavoriteAndExitSelection,
        ),
      )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: Colors.white, // This will make it pure white
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.conversation.messages.isNotEmpty &&
                            widget.conversation.messages.last.isSpam
                        ? Colors.transparent
                        : const Color(0xFF85BBD9),
                    child: widget.conversation.messages.isNotEmpty &&
                            widget.conversation.messages.last.isSpam
                        ? ClipOval(
                            child: Image.asset(
                              'assets/warning_icon.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Text(
                            widget.conversation.sender[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.conversation.sender, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _formatDate(widget.conversation.messages.first.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true, // Add this to make the list start from bottom
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                final message = widget.conversation.messages[index];
                final bool isSentByUser = message.sender == "You";
                final bool isMessageSelected = selectedMessages.contains(message);

                return GestureDetector(
                  onLongPress: () => _handleLongPress(message),
                  onTap: isSelectionMode ? () => _toggleMessageSelection(message) : null,
                  child: Column(
                    crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getMessageColor(message, isDarkMode, isMessageSelected),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMessageSelected 
                                      ? Border.all(color: Colors.blue, width: 2) 
                                      : null,
                                ),
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableLinkify(
                                      text: message.content,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                      onOpen: (link) async {
                                        try {
                                          await launchUrl(Uri.parse(link.url));
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Could not open link: ${link.url}'),
                                                backgroundColor: const Color(0xFF85BBD9),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      linkStyle: TextStyle(
                                        color: isDarkMode ? Colors.lightBlue : Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatMessageTime(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (message.isFavorite && !isSelectionMode)
                                Positioned(
                                  right: 8,
                                  bottom: 4,
                                  child: Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Colors.red[400],
                                  ),
                                ),
                            ],
                          );
                        }
                      ),
                      
                      if (message.isClassified && message.isSpam)  // Only show for spam
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Colors.blue[200],
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: message.spamConfidence / 100,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${message.spamConfidence.toStringAsFixed(0)}% Spam',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!message.isClassified)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Waiting...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildMessageInputArea(theme, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_sharp, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}