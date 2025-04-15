class Message {
  final int id;
  final String sender;
  final String content;
  final bool isRead;
  final bool isSpam;
  final bool isFavorite;  // Add this property
  final double spamConfidence;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    this.isRead = false,
    this.isSpam = false,
    this.isFavorite = false,  // Add default value
    this.spamConfidence = 0.0,
    required this.timestamp,
  });

  Message copyWith({
    int? id,
    String? sender,
    String? content,
    bool? isRead,
    bool? isSpam,
    bool? isFavorite,  // Add to copyWith
    double? spamConfidence,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      isSpam: isSpam ?? this.isSpam,
      isFavorite: isFavorite ?? this.isFavorite,  // Include in new instance
      spamConfidence: spamConfidence ?? this.spamConfidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}