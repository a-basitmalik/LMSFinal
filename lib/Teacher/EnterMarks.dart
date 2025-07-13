import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EnterMarksScreen extends StatefulWidget {
  final String assessmentId;
  final String assessmentTitle;
  final String assessmentType;
  final Color subjectColor;
  final bool isQuiz;

  const EnterMarksScreen({
    super.key,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.assessmentType,
    required this.subjectColor,
    required this.isQuiz,
  });

  @override
  _EnterMarksScreenState createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  List<Map<String, dynamic>> _students = [];
  final Map<String, TextEditingController> _markControllers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _totalMarks = 0;

  final String baseUrl = 'http://192.168.18.185:5050/SubjectAssessment/api';
  final String studentsEndpoint = '/assessment-students';
  final String submitMarksEndpoint = '/submit-marks';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$studentsEndpoint?assessment_id=${widget.assessmentId}&is_quiz=${widget.isQuiz}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalMarks = widget.isQuiz ? 15 : data['total_marks'] ?? 0;
          _students = List<Map<String, dynamic>>.from(data['students']);
          for (var student in _students) {
            _markControllers[student['rfid'].toString()] = TextEditingController(
              text: student['marks_achieved']?.toString() ?? '',
            );
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitMarks() async {
    if (!_validateMarks()) return;

    setState(() => _isSubmitting = true);

    try {
      final marks = _students.map((student) {
        return {
          'rfid': student['rfid'],
          'marks_achieved': double.tryParse(
              _markControllers[student['rfid'].toString()]!.text) ??
              0,
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl$submitMarksEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assessment_id': widget.assessmentId,
          'marks': marks,
          'is_quiz': widget.isQuiz,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marks submitted successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to submit marks: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  bool _validateMarks() {
    for (var student in _students) {
      final controller = _markControllers[student['rfid'].toString()];
      if (controller == null || controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter marks for all students')),
        );
        return false;
      }
      final marks = double.tryParse(controller.text);
      if (marks == null || marks < 0 || marks > _totalMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid marks for ${student['student_name']}')),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enter Marks: ${widget.assessmentTitle}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header with assessment info
          Container(
            padding: EdgeInsets.all(16),
            color: widget.subjectColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isQuiz ? 'Quiz' : 'Assessment',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    Chip(
                      label: Text(
                        widget.assessmentType.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: widget.subjectColor,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Marks: $_totalMarks',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Students: ${_students.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student list with marks input
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Student avatar with first letter
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.subjectColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              student['student_name'][0],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),

                        // Student details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['student_name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${student['StudentID'] ?? student['rfid']}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Marks input field
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _markControllers[student['rfid'].toString()],
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Marks',
                              border: OutlineInputBorder(),
                              suffixText: '/$_totalMarks',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final mark = double.tryParse(value);
                              if (mark == null || mark < 0 || mark > _totalMarks) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.subjectColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Submit Marks',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}