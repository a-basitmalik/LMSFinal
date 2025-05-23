// models/subject_model.dart
class Subject {
  final String id;
  final String name;
  final String code;
  final String instructor;
  final String? description;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.instructor,
    this.description,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    // Add debug print to see raw JSON
    print('Parsing subject JSON: $json');

    return Subject(
      id: json['id']?.toString() ?? 'unknown_id',
      name: json['name']?.toString() ?? 'Unnamed Subject',
      code: json['code']?.toString() ?? 'NOCODE',
      instructor: json['instructor']?.toString() ?? 'Unknown Instructor',
      description: json['description']?.toString(),
    );
  }
}