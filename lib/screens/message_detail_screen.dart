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

   // Add a method to handle message selection/deselection
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
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  
  final RelativeRect position = RelativeRect.fromLTRB(
    overlay.size.width - 180,
    kToolbarHeight + 20,
    0,
    0
  );

  showMenu(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    items: [
      PopupMenuItem(
        child: const Row(
          children: [
            SizedBox(width: 4),
            Text('Delete'),
          ],
        ),
        onTap: () {
  final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);

  conversationProvider.deleteConversation(widget.conversation);

  setState(() {}); // Force UI refresh
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) Navigator.of(context).pop();
  });
},


      ),
      PopupMenuItem(
        child: const Row(
          children: [
            SizedBox(width: 4),
            Text('Archive'),
          ],
        ),
        onTap: () {
  // Store provider reference before entering async gap
  final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
  final navigator = Navigator.of(context); // Store navigator reference

  conversationProvider.archiveConversation(widget.conversation);

  // Ensure widget is still mounted before calling navigator
  if (mounted) {
    navigator.pop();
  }
},

      ),
    ],
  );
}

void _toggleFavoriteAndExitSelection(Message message) {
  // Toggle favorite status using provider
  Provider.of<ConversationProvider>(context, listen: false)
      .toggleMessageFavorite(message);
      
  // Exit selection mode
  setState(() {
    selectedMessages.clear();
    isSelectionMode = false;
  });
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
      appBar: isSelectionMode 
    ? AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                final message = widget.conversation.messages[index];
                final bool isSentByUser = message.sender == "You";
                final double spamConfidence = _generateSpamConfidence();
                final bool isMessageSelected = selectedMessages.contains(message);

                return // Replace the message rendering part in your ListView.builder with this code
// Place this code in your ListView.builder itemBuilder callback
GestureDetector(
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
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: isMessageSelected 
                      ? Color.fromRGBO(33, 150, 243, 0.3)
                      : (message.isSpam ? spamBgColor : hamBgColor),
                  borderRadius: BorderRadius.circular(12),
                  border: isMessageSelected 
                      ? Border.all(color: Colors.blue, width: 2) 
                      : null,
                ),
                padding: EdgeInsets.only(
                  left: 12.0, 
                  top: 12.0, 
                  right: 12.0,
                  // Add extra padding at the bottom if favorited to make room for the icon
                  bottom: (message.isFavorite && !isSelectionMode) ? 22.0 : 12.0,
                ),      
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: message.isSpam ? spamTextColor : hamTextColor,
                    fontSize: 16,
                  ),
                ),
              ),
              
              // Position heart precisely in the bottom right with proper padding
              if (message.isFavorite && !isSelectionMode)
                Positioned(
                  right: 8,  // Position from right edge of the bubble
                  bottom: 4, // Position from bottom edge of the bubble
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
      
      if (message.isSpam)
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
                  widthFactor: spamConfidence,
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
                '${(spamConfidence * 100).toStringAsFixed(0)}% Spam',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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