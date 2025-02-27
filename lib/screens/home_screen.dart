import 'package:flutter/material.dart';
import '../widgets/hamburger_menu.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart' as model;
import 'message_detail_screen.dart';
import 'package:intl/intl.dart';

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
      sender: "Min",
      messages: [
        Message(id: 1, sender: "Min", content: "Andy where are you ngayon? i miss you", isRead: false, timestamp: DateTime.now().subtract(Duration(minutes: 5))),
        Message(id: 2, sender: "Min", content: "kakain po ba tayo sa labas later?", isRead: true, timestamp: DateTime.now().subtract(Duration(hours: 1))),
      ],
    ),
    model.Conversation(
      id: 2,
      sender: "Ma",
      messages: [
        Message(id: 3, sender: "Ma", content: "load mo daw ako noy", isRead: true, timestamp: DateTime.now().subtract(Duration(hours: 2))),
        Message(id: 4, sender: "Ma", content: "reg 50", isRead: false, timestamp: DateTime.now().subtract(Duration(days: 1))),
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
        title: Text(
  'SCAMBA',
  style: TextStyle(
    color: isDarkMode ? Colors.white : Colors.black, // Adapt to theme
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    fontFamily: 'Montserrat', // Custom font
  ),
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
          _buildConversationList(conversations),
          _buildMessageList(
            conversations.expand((c) => c.messages).where((m) => m.isSpam).toList(),
          ),
        ],
      ),
    );
  }

  ///////

  Widget _buildConversationList(List<model.Conversation> conversationList) {
    return ListView.builder(
      itemCount: conversationList.length,
      itemBuilder: (context, index) {
        final conversation = conversationList[index];
        final lastMessage = conversation.messages.isNotEmpty
            ? conversation.messages.last
            : null;

        return Dismissible(
          key: ValueKey(conversation.id),
          background: _swipeBackground(Colors.green, Icons.archive, Alignment.centerLeft),
          secondaryBackground: _swipeBackground(Colors.red, Icons.delete, Alignment.centerRight),
          onDismissed: (direction) {
            setState(() {
              conversations.removeAt(index);
            });
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(conversation.sender[0].toUpperCase()),
            ),
            title: Text(
              conversation.sender,
              style: TextStyle(fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: lastMessage != null
                ? Text(
                    lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text("No messages"),

                //////////  
             trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.end, // ✅ Ensures right alignment
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
        margin: const EdgeInsets.only(top: 5), // ✅ Adds spacing
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
   
 
            /////////////
            onTap: () {
              _markMessageAsRead(conversation.messages.last, conversation.messages);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageDetailScreen(conversation: conversation),
                ),
              );
            },
            onLongPress: () => _toggleSelection(conversation.id),
          ),
        );
      },
    );
  }

  /////////

  String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;

  if (difference == 0) {
    return DateFormat('h:mm a').format(date);  // ✅ Shows time if today
  } else if (difference < 7) {
    return DateFormat('EEE').format(date);  // ✅ Shows day (Mon, Tue)
  } else if (date.year == now.year) {
    return DateFormat('d MMM').format(date);  // ✅ Shows '26 Feb'
  } else {
    return DateFormat('dd/MM/yyyy').format(date);  // ✅ Shows full date
  }
}

  void _markMessageAsRead(Message message, List<Message> messages) {
  setState(() {
    for (var i = 0; i < conversations.length; i++) {
      if (conversations[i].sender == message.sender) {
        // ✅ Replace each message with an updated copy where isRead = true
        conversations[i] = conversations[i].copyWith(
          messages: conversations[i].messages.map((m) {
            return m.copyWith(isRead: true);
          }).toList(),
        );
        break;
      }
    }
  });
}

Widget _buildMessageList(List<Message> messages) {
  return ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      return ListTile(
        title: Text(message.content),
        subtitle: Text(message.timestamp.toString()),
        leading: Icon(message.isSpam ? Icons.warning : Icons.message),
      );
    },
  );
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
      conversations.removeWhere((conversation) => selectedMessages.contains(conversation.id));
      selectedMessages.clear();
      selectionMode = false;
    });
  }
}
