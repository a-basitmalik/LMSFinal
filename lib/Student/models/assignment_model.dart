class Assignment {
  final int id;
  final int subjectId;
  final String subjectName;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime postedDate;
  late final String status;
  final List<Attachment> attachments; // List of Attachment objects
  final String? submissionFile;
  late final DateTime? submissionDate;
  final double? grade;
  final String? teacherFeedback;
  String subject;

  Assignment({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.postedDate,
    required this.status,
    this.attachments = const [],
    this.submissionFile,
    this.submissionDate,
    this.grade,
    this.teacherFeedback,
    this.subject = "Computer",
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    // Parsing attachments into a list of Attachment objects
    var attachmentsJson = json['attachments'] as List<dynamic>?;
    List<Attachment> attachmentsList = attachmentsJson != null
        ? attachmentsJson.map((att) => Attachment.fromJson(att)).toList()
        : [];

    return Assignment(
      id: json['assignment_id'],
      subjectId: json['subject_id'],
      subjectName: json['subject_name'] ?? 'Unknown',
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      postedDate: DateTime.parse(json['posted_date']),
      status: json['status'],
      attachments: attachmentsList, // Updated attachments
      submissionFile: json['submission_file'],
      submissionDate: json['submission_date'] != null
          ? DateTime.parse(json['submission_date'])
          : null,
      grade: json['grade']?.toDouble(),
      teacherFeedback: json['teacher_feedback'],
    );
  }

  bool get isOverdue =>
      status != 'graded' &&
          status != 'submitted' &&
          dueDate.isBefore(DateTime.now());

  String get timeLeft {
    if (status == 'graded' || status == 'submitted') {
      return 'COMPLETED';
    }

    final difference = dueDate.difference(DateTime.now());
    if (difference.isNegative) {
      return 'OVERDUE';
    } else if (difference.inDays > 0) {
      return 'Due in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Due in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    }
    return 'Due soon';
  }
}

class Attachment {
  final int attachmentId;
  final String fileName;
  final String filePath;

  Attachment({
    required this.attachmentId,
    required this.fileName,
    required this.filePath,
  });

  // Factory method to create Attachment from JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      attachmentId: json['attachment_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
    );
  }
}
