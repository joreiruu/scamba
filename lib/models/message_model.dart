class Message {
  final int id;
  final String sender;
  final String content;
  final DateTime timestamp;
  bool isRead;
  bool isSpam;
  bool isFavorite;
  double spamConfidence;
  bool isClassified;  // Add this field

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isSpam = false,
    this.isFavorite = false,
    this.spamConfidence = -1,
    this.isClassified = false,  // Initialize as unclassified
  });

  Message copyWith({
    bool? isSpam,
    double? spamConfidence,
    bool? isRead,
    bool? isFavorite,
    bool? isClassified,
  }) {
    return Message(
      id: id,
      sender: sender,
      content: content,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      isSpam: isSpam ?? this.isSpam,
      isFavorite: isFavorite ?? this.isFavorite,
      spamConfidence: spamConfidence ?? this.spamConfidence,
      isClassified: isClassified ?? this.isClassified,
    );
  }
}