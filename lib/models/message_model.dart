class Message {
  final int id;
  final String sender;
  final String content;
  final bool isSpam;
  final double spamLikelihood;
  final bool isRead;
  final DateTime timestamp;
  final bool isSelected;
  final bool isFavorite; // Added favorite property

  Message({
    required this.id,
    required this.sender,
    required this.content,
    this.isSpam = false,
    this.spamLikelihood = 0.0,
    this.isRead = false,
    required this.timestamp,
    this.isSelected = false,
    this.isFavorite = false, // Default to not favorited
  });

  /// Use copyWith to update fields safely
  Message copyWith({
    bool? isSpam, 
    double? spamLikelihood, 
    bool? isRead, 
    bool? isSelected,
    bool? isFavorite, // Added isFavorite parameter
  }) {
    return Message(
      id: id,
      sender: sender,
      content: content,
      isSpam: isSpam ?? this.isSpam,
      spamLikelihood: spamLikelihood ?? this.spamLikelihood,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite, // Pass through isFavorite
    );
  }
}