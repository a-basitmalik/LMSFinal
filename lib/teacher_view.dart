import 'package:flutter/material.dart';

class TeacherView extends StatelessWidget {
  final int selectedTeacherId;
  final String selectedTeacherName;

  TeacherView({required this.selectedTeacherId, required this.selectedTeacherName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(selectedTeacherName)),
      body: Center(
        child: Text('Details for teacher: $selectedTeacherName'),
      ),
    );
  }
}
