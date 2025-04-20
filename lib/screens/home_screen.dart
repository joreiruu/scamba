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
  bool selectionMode = false;
  Set<int> selectedMessages = {};
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    
    // Increase refresh interval to reduce unnecessary updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
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

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel the timer when disposing
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
          appBar: AppBar(
            leading: selectionMode 
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        selectedMessages.clear();
                        selectionMode = false;
                      });
                    },
                  )
                : null,
            title: selectionMode 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start, // Align items to the left
                    children: [
                      Text(
                        "${selectedMessages.length} selected",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'SCAMBA',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
            centerTitle: true,
            backgroundColor: isDarkMode ? Color(0xFF23272A) : Colors.white,
            iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
            actions: selectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: _archiveSelected,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined),
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
                  _buildConversationList(allConversations), 
                  _buildConversationList(
                    allConversations.where((c) => c.messages.any((m) => m.isSpam)).toList(),
                  ),
                ],
              ),
        );
      }
    );
  }

  Widget _buildConversationList(List<model.Conversation> conversationList) {
    final filterProvider = Provider.of<FilterProvider>(context);
    final conversationProvider = Provider.of<ConversationProvider>(context);

    // Filter out both archived and deleted conversations
    final filteredConversations = conversationList.where((conv) => 
      !conversationProvider.archivedConversations.any((archived) => archived.id == conv.id) &&
      !conversationProvider.deletedConversations.any((deleted) => deleted.id == conv.id)
    ).toList();

    // Apply spam filtering
    final filteredList = (filterProvider.selectedTab == 'All Messages' && filterProvider.filterHamMessages)
        ? filteredConversations.where((conv) => 
            !conv.messages.any((message) => message.isSpam)
          ).toList()
        : filteredConversations;

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final conversation = filteredList[index];
        final lastMessage = conversation.messages.isNotEmpty
            ? conversation.messages.last
            : null;
        
        final isSelected = selectedMessages.contains(conversation.id);

        return Dismissible(
          key: ValueKey(conversation.id),
          background: _swipeBackground(Colors.green, Icons.archive_outlined, Alignment.centerLeft),
          secondaryBackground: _swipeBackground(Colors.red, Icons.delete_outlined, Alignment.centerRight),

          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              archiveSingleConversation(conversation);
            } else if (direction == DismissDirection.endToStart) {
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
                  _markMessageAsRead(conversation.messages.last, conversation.messages);
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
          },
          onDelete: (deleted) {
            final provider = Provider.of<ConversationProvider>(context, listen: false);
            for (final conversation in deleted) {
              provider.deleteConversation(conversation);
            }
          },
        ),
      ),
    );
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
          },
        ),
      ),
    );
  }
}