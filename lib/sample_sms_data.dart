import '../models/conversation_model.dart' as model;
import '../models/message_model.dart';


List<model.Conversation> conversations = [
  // Existing Conversations
  model.Conversation(
    id: 1,
    sender: "Min",
    messages: [
      Message(
        id: 1,
        sender: "Min",
        content: "Andy where are you ngayon? I miss you",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      Message(
        id: 2,
        sender: "Min",
        content: "Kakain po ba tayo sa labas later?",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
      ),
    ],
  ),
  model.Conversation(
    id: 2,
    sender: "Ma",
    messages: [
      Message(
        id: 3,
        sender: "Ma",
        content: "Load mo daw ako noy",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Message(
        id: 4,
        sender: "Ma",
        content: "Reg 50",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    ],
  ),
  model.Conversation(
    id: 3,
    sender: "09251856231",
    messages: [
      Message(
        id: 5,
        sender: "09251856231",
        content: "Good pm po, pa claim an lang po ng parcel nyo here as LBC, for tracking number click here: https://lbcc.com",
        isRead: false,
        isSpam: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ],
  ),

  model.Conversation(
    id: 4,
    sender: "GLOBE",
    messages: [
      Message(
        id: 6,
        sender: "GLOBE",
        content: "Your data promo has been activated. Enjoy unlimited browsing!",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 10)),
      ),
      Message(
        id: 7,
        sender: "GLOBE",
        content: "Reminder: Recharge your account for more benefits.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 8)),
      ),
      Message(
        id: 8,
        sender: "GLOBE",
        content: "Visit our website for exclusive deals.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
    ],
  ),
  // Conversation from GCash with 1 unread message
  model.Conversation(
    id: 5,
    sender: "GCash",
    messages: [
      Message(
        id: 9,
        sender: "GCash",
        content: "Your payment was successful.",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
      ),
      Message(
        id: 10,
        sender: "GCash",
        content: "Reminder: Complete your KYC to enjoy more features.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
      ),
    ],
  ),
  // Conversation from BPI with 2 unread messages (one marked as spam)
  model.Conversation(
    id: 6,
    sender: "BPI",
    messages: [
      Message(
        id: 11,
        sender: "BPI",
        content: "Your account statement is ready.",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(days: 1, hours: 1)),
      ),
      Message(
        id: 12,
        sender: "BPI",
        content: "Fraud alert: Please verify recent transactions.",
        isRead: false,
        isSpam: false,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
      Message(
        id: 13,
        sender: "BPI",
        content: "Update your profile for improved security.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(hours: 23)),
      ),
    ],
  ),
  // Conversation from NDRRMC with 1 unread message
  model.Conversation(
    id: 7,
    sender: "NDRRMC",
    messages: [
      Message(
        id: 14,
        sender: "NDRRMC",
        content: "Please be advised: There is a weather update in your area.",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
      ),
      Message(
        id: 15,
        sender: "NDRRMC",
        content: "Evacuation centers are ready in your vicinity.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(hours: 4, minutes: 45)),
      ),
    ],
  ),

  
  // Conversation from a random sender "Juan" with 1 unread message
  model.Conversation(
    id: 8,
    sender: "Juan",
    messages: [
      Message(
        id: 16,
        sender: "Juan",
        content: "Hey, let's catch up later.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
    ],
  ),
  // Conversation from a random sender "Maria" with 2 unread messages (one spam)
  model.Conversation(
    id: 9,
    sender: "Maria",
    messages: [
      Message(
        id: 17,
        sender: "Maria",
        content: "Don't forget our meeting tomorrow.",
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 6)),
      ),
      Message(
        id: 18,
        sender: "Maria",
        content: "I sent you the documents, please check.",
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(hours: 5, minutes: 30)),
      ),
      Message(
        id: 19,
        sender: "Maria",
        content: "Reminder: Let's have lunch together.",
        isRead: false,
        isSpam: false,
        timestamp: DateTime.now().subtract(Duration(hours: 5, minutes: 15)),
      ),
    ],
  ),

  model.Conversation(
    id: 10,
    sender: "09774352091",
    messages: [
      Message(
        id: 20,
        sender: "09774352091",
        content: "Ma ako to naaksidente ako, pa gcash po 5000 asap sana sen dito 09763231231",
        isRead: false,
        isSpam: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
    ],
  ),
];