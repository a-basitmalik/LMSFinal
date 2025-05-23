class Query {
  final String id;
  final String subject;
  final String question;
  final String? answer;
  final DateTime timestamp;
  final bool isResolved;

  Query({
    required this.id,
    required this.subject,
    required this.question,
    this.answer,
    required this.timestamp,
    this.isResolved = false,
  });

  // Getter for relative time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  // Factory constructor for JSON deserialization
  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
      id: json['id'].toString(),
      subject: json['subject'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isResolved: json['isResolved'] ?? false,
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
    };
  }
}
