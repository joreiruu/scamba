class Message {
  final int id;
  final String sender;
  final String content;
  final bool isSpam;
  final bool isRead;
  final DateTime timestamp;
  final bool isSelected;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    this.isSpam = false,
    this.isRead = false,
    required this.timestamp,
    this.isSelected = false,
  });

  // ✅ Use copyWith to update fields safely
  Message copyWith({bool? isSpam, bool? isRead, bool? isSelected}) {
    return Message(
      id: id,
      sender: sender,
      content: content,
      isSpam: isSpam ?? this.isSpam,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
