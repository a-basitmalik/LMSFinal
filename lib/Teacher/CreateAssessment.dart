import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateAssessmentScreen extends StatefulWidget {
  final String subjectCode;
  final Color subjectColor;

  const CreateAssessmentScreen({
    super.key,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  _CreateAssessmentScreenState createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends State<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();
  String _assessmentType = 'assignment';
  bool _isLoading = false;

  final String baseUrl = 'http://your-flask-server.com/api';
  final String createAssessmentEndpoint = '/assessments';

  Future<void> _createAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$createAssessmentEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject_code': widget.subjectCode,
          'title': _titleController.text,
          'type': _assessmentType,
          'total_marks': int.parse(_totalMarksController.text),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Return success
      } else {
        throw Exception('Failed to create assessment');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assessment Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Assessment Title',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assessmentType,
                decoration: InputDecoration(
                  labelText: 'Assessment Type',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'assignment',
                    child: Text('Assignment'),
                  ),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'exam', child: Text('Exam')),
                  DropdownMenuItem(value: 'project', child: Text('Project')),
                ],
                onChanged: (value) {
                  setState(() => _assessmentType = value!);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _totalMarksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Marks',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total marks';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Create Assessment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
