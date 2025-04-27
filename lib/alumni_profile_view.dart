import 'package:flutter/material.dart';

class AlumniProfileView extends StatelessWidget {
  final int selectedAlumniId;
  final String selectedAlumniName;

  AlumniProfileView({required this.selectedAlumniId, required this.selectedAlumniName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(selectedAlumniName)),
      body: Center(
        child: Text('Details for alumni: $selectedAlumniName'),
      ),
    );
  }
}
