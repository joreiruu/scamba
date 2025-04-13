import 'package:flutter/material.dart';
import '../models/message_model.dart';

class SelectionBar extends StatelessWidget {
  final List<Message> selectedMessages;
  final VoidCallback onCopy;
  final VoidCallback onCancel;
  final Function(Message) onToggleFavorite;

  const SelectionBar({
    super.key,
    required this.selectedMessages,
    required this.onCopy,
    required this.onCancel,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Check if all selected messages are favorited
    bool isSelectedFavorite = selectedMessages.isNotEmpty &&
        selectedMessages.every((msg) => msg.isFavorite);

    return Container(
      height: 56,
      color: isDarkMode ? Color(0xFF23272A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
          const SizedBox(width: 8),
          Text(
            '${selectedMessages.length} selected',
            style: const TextStyle(
              fontWeight: FontWeight.normal,

            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(isSelectedFavorite ? Icons.favorite : Icons.favorite_border),
            color: isSelectedFavorite ? Colors.red : null,
            onPressed: () {
              if (selectedMessages.length == 1) {
                final message = selectedMessages.first;
                final willBeFavorited = !message.isFavorite;

                // Toggle favorite status
                onToggleFavorite(message);

                // Show snackbar
               ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      willBeFavorited
          ? 'Message added to favorites'
          : 'Message removed from favorites',
    ),
    duration: const Duration(seconds: 2),
    backgroundColor: Color(0xFF85BBD9), // Added background color
  ),
);


                // Cancel selection mode to hide the selection bar
                onCancel();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}