// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import '../models/student_model.dart';

class AuthService {
  // Mock user data
  Student? _currentStudent;

  // Mock sign in
  Future<Student?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (email.isNotEmpty && password.isNotEmpty) {
      _currentStudent = Student(
        id: 'mock-user-id',
        name: 'Mock User',
        email: email,
        phone: '+1234567890',
        profileImage: null,
      );
      return _currentStudent;
    }
    return null;
  }

  // Mock registration
  Future<Student?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    _currentStudent = Student(
      id: 'mock-user-id',
      name: name,
      email: email,
      phone: '+1234567890',
      profileImage: null,
    );
    return _currentStudent;
  }

  // Mock sign out
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentStudent = null;
  }

  // Mock password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Password reset email sent to $email (mock)');
  }

  // Get current user
  Student? getCurrentStudent() {
    return _currentStudent;
  }

  // Mock auth state stream
  Stream<Student?> get user {
    return Stream.value(_currentStudent);
  }

  // Mock profile update
  Future<void> updateStudentProfile(Student student) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentStudent = student;
    debugPrint('Profile updated (mock): ${student.name}');
  }
}
