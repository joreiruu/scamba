import 'package:flutter/material.dart';
import '../widgets/hamburger_menu.dart';
import '../widgets/message_item.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart' as model;
import 'message_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<int> selectedMessages = {}; 
  bool selectionMode = false; 

  List<model.Conversation> conversations = [
    model.Conversation(
      id: 1,
      sender: "Alice",
      messages: [
        Message(id: 1, sender: "Alice", content: "Hello! How are you?", isRead: false, timestamp: DateTime.now().subtract(Duration(minutes: 5))),
        Message(id: 2, sender: "Alice", content: "Are you free later?", isRead: true, timestamp: DateTime.now().subtract(Duration(hours: 1))),
      ],
    ),
    model.Conversation(
      id: 2,
      sender: "Bob",
      messages: [
        Message(id: 3, sender: "Bob", content: "Did you see the news?", isRead: true, timestamp: DateTime.now().subtract(Duration(hours: 2))),
        Message(id: 4, sender: "Bob", content: "Let's meet up later!", isRead: false, timestamp: DateTime.now().subtract(Duration(days: 1))),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SCAMBA',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.archive),
                  onPressed: _archiveSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.red),
                  onPressed: () {}, 
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: "All Messages"),
            Tab(text: "Spam"),
          ],
        ),
      ),
      drawer: const HamburgerMenu(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(
            conversations.expand((c) => c.messages).toList(),
          ),
          _buildMessageList(
            conversations.expand((c) => c.messages).where((m) => m.isSpam).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messageList) {
    return ListView.builder(
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        final message = messageList[index];
        bool isSelected = selectedMessages.contains(message.id);
        final conversation = conversations.firstWhere(
          (c) => c.messages.contains(message),
          orElse: () => model.Conversation(id: -1, sender: "", messages: []),
        );

        return Dismissible(
          key: Key(message.id.toString()),
          background: _swipeBackground(Colors.blue, Icons.archive, Alignment.centerLeft),
          secondaryBackground: _swipeBackground(Colors.red, Icons.delete, Alignment.centerRight),
          onDismissed: (direction) {
            setState(() {
              if (direction == DismissDirection.endToStart) {
                conversation.messages.removeWhere((m) => m.id == message.id);
              }
            });
          },
          child: GestureDetector(
            onLongPress: () => _toggleSelection(message.id),
            child: MessageItem(
              message: message,
              conversation: conversation,
              isSelected: isSelected,
              onTap: () {
  if (selectionMode) {
    _toggleSelection(message.id);
  } else {
    Navigator.push(
     context,
     MaterialPageRoute(
      builder: (context) => MessageDetailScreen(
        message: message,
        onMessageRead: (msg) => _markMessageAsRead(msg, conversation),  // Add this line
        ),
      ),
    );
  }
},
              onMessageRead: (Message msg) {
                _markMessageAsRead(msg, conversation);
              },
            ),
          ),
        );
      },
    );
  }

  void _markMessageAsRead(Message message, model.Conversation conversation) {
    setState(() {
      Message updatedMessage = message.copyWith(isRead: true);
      conversations = conversations.map((c) {
        if (c.id == conversation.id) {
          return model.Conversation(
            id: c.id,
            sender: c.sender,
            messages: c.messages.map((m) => m.id == message.id ? updatedMessage : m).toList(),
          );
        }
        return c;
      }).toList();
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
    setState(() {
      selectedMessages.clear();
      selectionMode = false;
    });
  }

  void _deleteSelected() {
    setState(() {
      for (var conversation in conversations) {
        conversation.messages.removeWhere((m) => selectedMessages.contains(m.id));
      }
      selectedMessages.clear();
      selectionMode = false;
    });
  }
}
