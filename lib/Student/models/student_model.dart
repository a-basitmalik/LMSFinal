// lib/models/student_model.dart
class Student {
  String id;
  String name;
  String email;
  String? phone;
  String? profileImage;
  String? department;
  String? enrollmentNumber;
  DateTime? dateOfBirth;
  List<String>? enrolledCourses;

  Student({
    this.id = '',
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.department,
    this.enrollmentNumber,
    this.dateOfBirth,
    this.enrolledCourses,
  });

  // Factory constructor to create a Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      department: json['department'],
      enrollmentNumber: json['enrollmentNumber'],
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'])
              : null,
      enrolledCourses:
          json['enrolledCourses'] != null
              ? List<String>.from(json['enrolledCourses'])
              : null,
    );
  }

  // Method to convert Student to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'department': department,
      'enrollmentNumber': enrollmentNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'enrolledCourses': enrolledCourses,
    };
  }

  // Copy with method for easy updates
  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? department,
    String? enrollmentNumber,
    DateTime? dateOfBirth,
    List<String>? enrolledCourses,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      department: department ?? this.department,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }

  // Empty student factory
  factory Student.empty() {
    return Student(id: '', name: '', email: '');
  }

  // Method to update profile information
  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) {
    if (name != null) this.name = name;
    if (email != null) this.email = email;
    if (phone != null) this.phone = phone;
    if (profileImage != null) this.profileImage = profileImage;
  }
}
