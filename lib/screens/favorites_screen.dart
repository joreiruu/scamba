import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/message_item.dart';
import '../screens/message_detail_screen.dart'; // Make sure this import exists
import '../models/message_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversationProvider = Provider.of<ConversationProvider>(context);
    final favoriteMessages = conversationProvider.getFavoritedMessages();
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: isDarkMode ? const Color(0xFF23272A) : Colors.white,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: favoriteMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite messages',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favoriteMessages.length,
              itemBuilder: (context, index) {
                final message = favoriteMessages[index];

                // Find the conversation that contains this message
                final conversation = _findConversationForMessage(
                  conversationProvider,
                  message,
                );

                if (conversation == null) {
                  return const SizedBox.shrink(); // Skip if conversation not found
                }

                return MessageItem(
                  message: message,
                  conversation: conversation,
                  isSelected: false,
                  onTap: () {
  final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MessageDetailScreen(
        conversation: conversation,
      ),
    ),
  ).then((_) {
    conversationProvider.forceRefresh();
  });
},

                  onMessageRead: (msg) {},
                  onLongPress: (msg) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove from Favorites?'),
      content: const Text('Do you want to remove this message from your favorites?'),
      actions: [
        TextButton(
  onPressed: () => Navigator.of(ctx).pop(),
  style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF85BBD9), // Light blue for Cancel
  ),
  child: const Text('Cancel'),
),
TextButton(
  onPressed: () {
    Provider.of<ConversationProvider>(context, listen: false)
        .toggleMessageFavorite(msg);
    Navigator.of(ctx).pop();
  },
  style: TextButton.styleFrom(
    foregroundColor: Colors.red, // Red for Remove
  ),
  child: const Text('Remove'),
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

  // Helper method to find the conversation containing a message
  _findConversationForMessage(ConversationProvider provider, Message message) {
    for (var conversation in provider.conversations) {
      if (conversation.messages.any((m) => m.id == message.id)) {
        return conversation;
      }
    }
    for (var conversation in provider.archivedConversations) {
      if (conversation.messages.any((m) => m.id == message.id)) {
        return conversation;
      }
    }
    return null;
  }
}
