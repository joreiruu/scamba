import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Add this import for listEquals
import 'dart:async';
import '../widgets/hamburger_menu.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart' as model;
import 'message_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scamba/providers/filter_provider.dart';
import 'package:scamba/screens/about_screen.dart';
import 'archived_screen.dart';
import 'recently_deleted_screen.dart';
import 'package:scamba/providers/conversation_provider.dart';
import '../services/sms_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SmsService _smsService = SmsService();
  final ScrollController _scrollController = ScrollController();
  bool selectionMode = false;
  Set<int> selectedMessages = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialMessages(); // Only load messages once
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadInitialMessages() async {
    try {
      final provider = Provider.of<ConversationProvider>(context, listen: false);
      final loadedConversations = await _smsService.getConversations();
      if (loadedConversations != null) {
        provider.loadConversations(loadedConversations);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _scrollListener() {
    if (!_isLoadingMore && 
        _scrollController.position.pixels > 0 &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    
    try {
      final provider = Provider.of<ConversationProvider>(context, listen: false);
      final loadedConversations = await _smsService.getConversations(loadMore: true);
      if (loadedConversations != null && loadedConversations.isNotEmpty) {
        // Add new conversations without refreshing existing ones
        for (var newConv in loadedConversations) {
          if (!provider.conversations.any((c) => c.id == newConv.id)) {
            provider.conversations.add(newConv);
          }
        }
        // Only notify if new conversations were added
        provider.notifyListeners();
      }
    } catch (e) {
      print('Error loading more messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;
    
    return Consumer<ConversationProvider>(
      builder: (context, conversationProvider, child) {
        final allConversations = conversationProvider.conversations;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            leading: selectionMode 
                ? IconButton(
                    icon: const Icon(Icons.close_outlined), // Changed to outlined
                    onPressed: () {
                      setState(() {
                        selectedMessages.clear();
                        selectionMode = false;
                      });
                    },
                  )
                : null,
            title: selectionMode 
                ? Text(
                    "${selectedMessages.length} selected",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  )
                : Text(
                    'SCAMBA',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
            centerTitle: true,
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
            actions: selectionMode
                ? [
                    IconButton(
                      icon: Icon(Icons.archive_outlined,
                        color: isDarkMode ? Colors.white : Colors.black87),
                      onPressed: _archiveSelected,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outlined,
                        color: isDarkMode ? Colors.white : Colors.black87),
                      onPressed: _deleteSelected,
                    ),
                  ]
                : [
                    IconButton(
                      icon: Image.asset(
                        'assets/scamba_logo.png',
                        height: 30,
                        width: 30,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
            bottom: selectionMode 
                ? null 
                : TabBar(
                    controller: _tabController,
                    labelColor: isDarkMode ? Colors.white : Colors.black,
                    indicatorColor: Colors.red,
                    tabs: const [
                      Tab(text: "All Messages"),
                      Tab(text: "Spam"),
                    ],
                  ),
          ),
          drawer: selectionMode ? null : const HamburgerMenu(),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // All Messages tab with filtering
                  _buildConversationList(
                    allConversations,
                    isMainTab: true,
                  ), 
                  // Spam tab without filtering
                  _buildConversationList(
                    allConversations.where((c) => c.messages.any((m) => m.isSpam)).toList(),
                    isMainTab: false,
                  ),
                ],
              ),
        );
      }
    );
  }

  Widget _buildConversationList(List<model.Conversation> conversationList, {required bool isMainTab}) {
    final filterProvider = Provider.of<FilterProvider>(context);
    final conversationProvider = Provider.of<ConversationProvider>(context);

    // Filter conversations once
    final filteredConversations = conversationList.where((conv) => 
      !conversationProvider.archivedConversations.any((archived) => archived.id == conv.id) &&
      !conversationProvider.deletedConversations.any((deleted) => deleted.id == conv.id)
    ).toList();

    // For spam tab, filter spam messages within each conversation
    final List<model.Conversation> processedConversations;
    if (!isMainTab) {
      processedConversations = filteredConversations.map((conv) {
        return conv.copyWith(
          messages: conv.messages.where((msg) => msg.isSpam).toList()
        );
      }).where((conv) => conv.messages.isNotEmpty).toList();
    } else {
      if (filterProvider.filterHamMessages) {
        // For main tab with ham filter enabled
        processedConversations = filteredConversations.map((conv) {
          // Keep only ham messages for each conversation
          final hamMessages = conv.messages.where((msg) => !msg.isSpam).toList();
          return conv.copyWith(messages: hamMessages);
        }).where((conv) => conv.messages.isNotEmpty).toList(); // Only keep conversations with ham messages
      } else {
        processedConversations = filteredConversations;
      }
    }
    return ListView.builder(
      key: PageStorageKey(isMainTab ? 'main_tab' : 'spam_tab'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: processedConversations.length,
      cacheExtent: 100, // Cache more items
      itemBuilder: (context, index) {
        final conversation = processedConversations[index];
        // Cache the last message to avoid repeated access
        final lastMessage = conversation.messages.isNotEmpty ? 
          conversation.messages.first : null;
        final isSelected = selectedMessages.contains(conversation.id);

        return _buildConversationTile(
          conversation: conversation,
          lastMessage: lastMessage,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildConversationTile({
    required model.Conversation conversation,
    Message? lastMessage,
    required bool isSelected,
  }) {
    return Dismissible(
      key: ValueKey(conversation.id),
      background: _swipeBackground(Colors.green, Icons.archive_outlined, Alignment.centerLeft),
      secondaryBackground: _swipeBackground(Colors.red, Icons.delete_outlined, Alignment.centerRight),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          archiveSingleConversation(conversation);
        } else {
          deleteSingleConversation(conversation);
        }
      },
      child: Container(
        color: isSelected ? Colors.blue.withAlpha(26) : null,
        child: ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                backgroundColor: isSelected
                    ? Colors.blue
                    : conversation.hasSpamMessages // Use new getter
                        ? Colors.transparent
                        : const Color(0xFF85BBD9),
                child: isSelected
                    ? const Icon(Icons.check_outlined, color: Colors.white) // Changed to outlined
                    : conversation.hasSpamMessages // Use new getter
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
                  style: TextStyle(
                    fontWeight: !lastMessage.isRead ? FontWeight.bold : FontWeight.normal,
                  ),
                )
              : const Text("No messages"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessage != null)
                Text(
                  _formatDate(lastMessage.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              if (conversation.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            if (selectionMode) {
              _toggleSelection(conversation.id);
            } else {
              _markMessageAsRead(conversation.messages.first, conversation.messages);
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

  void _markMessageAsRead(Message message, List<Message> messages) {
    setState(() {
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].sender == message.sender) {
          messages[i] = messages[i].copyWith(
            isRead: true,
          );
          break;
        }
      }
    });
  }

  Widget _swipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }

  void _toggleSelection(int messageId) {
    setState(() {
      if (selectedMessages.contains(messageId)) {
        selectedMessages.remove(messageId);
      } else {
        selectedMessages.add(messageId);
      }
      selectionMode = selectedMessages.isNotEmpty;
    });
  }

  void _archiveSelected() {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    final selectedConversations = provider.conversations
        .where((conversation) => selectedMessages.contains(conversation.id))
        .toList();
    
    // Archive each selected conversation
    for (final conversation in selectedConversations) {
      provider.archiveConversation(conversation);
    }
    
    // Clear selection
    setState(() {
      selectedMessages.clear();
      selectionMode = false;
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Archived ${selectedConversations.length} conversation${selectedConversations.length != 1 ? 's' : ''}',
        ),
        backgroundColor: const Color(0xFF85BBD9),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final conversation in selectedConversations) {
              provider.restoreArchivedConversation(conversation);
            }
          },
        ),
      ),
    );
  }

  void _deleteSelected() {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    final selectedConversations = provider.conversations
        .where((conversation) => selectedMessages.contains(conversation.id))
        .toList();
    
    // Delete each selected conversation through the provider
    for (final conversation in selectedConversations) {
      provider.deleteConversation(conversation);
    }
    
    // Clear selection
    setState(() {
      selectedMessages.clear();
      selectionMode = false;
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted ${selectedConversations.length} conversation${selectedConversations.length != 1 ? 's' : ''}',
        ),
        backgroundColor: const Color(0xFF85BBD9),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final conversation in selectedConversations) {
              provider.restoreDeletedConversation(conversation);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void deleteSingleConversation(model.Conversation conversation) {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    provider.deleteConversation(conversation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation deleted'),
        backgroundColor: const Color(0xFF85BBD9),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            provider.restoreDeletedConversation(conversation);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void archiveSingleConversation(model.Conversation conversation) {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    provider.archiveConversation(conversation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation archived'),
        backgroundColor: const Color(0xFF85BBD9),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            provider.restoreArchivedConversation(conversation);
          },
        ),
      ),
    );
  }

  void openArchivedScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivedScreen(
          archivedConversations: Provider.of<ConversationProvider>(context, listen: false).archivedConversations,
          onUpdate: (unarchived) {
            final provider = Provider.of<ConversationProvider>(context, listen: false);
            for (final conversation in unarchived) {
              provider.restoreArchivedConversation(conversation);
            }
            // Force refresh after restoration
            provider.forceRefresh();
          },
          onDelete: (deleted) {
            final provider = Provider.of<ConversationProvider>(context, listen: false);
            for (final conversation in deleted) {
              provider.deleteConversation(conversation);
            }
          },
        ),
      ),
    ).then((_) {
      // Refresh when returning to home screen
      setState(() {});
      Provider.of<ConversationProvider>(context, listen: false).forceRefresh();
    });
  }

  void openDeletedScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecentlyDeletedScreen(
          deletedConversations: Provider.of<ConversationProvider>(context, listen: false).deletedConversations,
          onRestoreConversations: (restored) {
            final provider = Provider.of<ConversationProvider>(context, listen: false);
            for (final conversation in restored) {
              provider.restoreDeletedConversation(conversation);
            }
            // Force refresh after restoration
            provider.forceRefresh();
          },
        ),
      ),
    ).then((_) {
      // Refresh when returning to home screen
      setState(() {});
      Provider.of<ConversationProvider>(context, listen: false).forceRefresh();
    });
  }
}