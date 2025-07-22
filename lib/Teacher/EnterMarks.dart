import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';
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

  final String baseUrl = 'http://193.203.162.232:5050/SubjectAssessment/api';
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
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
          SnackBar(
            content: Text('Marks submitted successfully!'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to submit marks: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
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
          SnackBar(
            content: Text('Please enter marks for all students'),
            backgroundColor: TeacherColors.warningAccent,
          ),
        );
        return false;
      }
      final marks = double.tryParse(controller.text);
      if (marks == null || marks < 0 || marks > _totalMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid marks for ${student['student_name']}'),
            backgroundColor: TeacherColors.warningAccent,
          ),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Enter Marks: ${widget.assessmentTitle}',
          style: TeacherTextStyles.sectionHeader.copyWith(color: TeacherColors.primaryText),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: TeacherColors.primaryAccent,
        ),
      )
          : Column(
        children: [
          // Header with assessment info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.subjectColor.toGlassDecoration().gradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isQuiz ? 'Quiz' : 'Assessment',
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.subjectColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.subjectColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.assessmentType.toUpperCase(),
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          color: widget.subjectColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Marks: $_totalMarks',
                      style: TeacherTextStyles.cardTitle,
                    ),
                    Text(
                      'Students: ${_students.length}',
                      style: TeacherTextStyles.cardTitle,
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
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: TeacherColors.glassDecoration(
                    borderColor: widget.subjectColor.withOpacity(0.3),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Student avatar with first letter
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: widget.subjectColor
                                .toGlassDecoration()
                                .gradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              student['student_name'][0],
                              style: TeacherTextStyles.cardTitle,
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
                                style: TeacherTextStyles.listItemTitle,
                              ),
                              Text(
                                'ID: ${student['StudentID'] ?? student['rfid']}',
                                style: TeacherTextStyles.listItemSubtitle,
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
                            style: TeacherTextStyles.listItemTitle,
                            decoration: InputDecoration(
                              labelText: 'Marks',
                              labelStyle: TeacherTextStyles.listItemSubtitle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: widget.subjectColor,
                                ),
                              ),
                              suffixText: '/$_totalMarks',
                              suffixStyle: TeacherTextStyles.listItemSubtitle,
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
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: TeacherColors.primaryText,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Submit Marks',
                  style: TeacherTextStyles.primaryButton,
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