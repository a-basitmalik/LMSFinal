class ChatMessage {
  final int id;
  final int roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  bool isRead;
  List<String> readers;
  DateTime? readAt;  // Add readAt field to track when the message is read

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.readers = const [],
    this.readAt,  // Optional field, can be null if not yet read
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['message_id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      senderId: json['sender_rfid']?.toString() ?? 'unknown',
      senderName: json['sender_name']?.toString() ?? 'Unknown',
      content: json['message_text']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
      // Handle readAt field in JSON, if available
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']?.toString() ?? '') : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'message_id': id,
    'room_id': roomId,
    'sender_rfid': senderId,
    'sender_name': senderName,
    'message_text': content,
    'sent_at': timestamp.toIso8601String(),
    'is_read': isRead,
    'read_at': readAt?.toIso8601String(),  // Include readAt in JSON if available
  };

  // Optionally, you can create a method to mark the message as read and set the readAt time
  void markAsRead() {
    isRead = true;
    readAt = DateTime.now();  // Set the current time when the message is marked as read
  }
}
