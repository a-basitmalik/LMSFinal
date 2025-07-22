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
          style: TeacherTextStyles.sectionHeader.copyWith(
            color: TeacherColors.primaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subjectColor,
                widget.subjectColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TeacherColors.primaryBackground.withOpacity(0.97),
              TeacherColors.primaryBackground.withOpacity(0.95),
            ],
          ),
        ),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: widget.subjectColor,
            strokeWidth: 3,
          ),
        )
            : Column(
          children: [
            // Assessment Info Card
            _buildAssessmentInfoCard(),

            // Student List Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt,
                    color: widget.subjectColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Student Marks',
                    style: TeacherTextStyles.sectionHeader.copyWith(
                      fontSize: 22,
                      color: widget.subjectColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_students.length} Students',
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      color: TeacherColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Student list with marks input
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                itemCount: _students.length,
                separatorBuilder: (context, index) => const SizedBox(
                    height: 12),
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return _buildStudentMarkCard(student);
                },
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.subjectColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMarks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: TeacherColors.primaryText,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        Icon(
                          Icons.save,
                          color: TeacherColors.primaryText,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Submit Marks',
                          style: TeacherTextStyles.primaryButton.copyWith(
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentInfoCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.2),
            widget.subjectColor.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isQuiz ? 'Quiz' : 'Assessment',
                  style: TeacherTextStyles.listItemSubtitle.copyWith(
                    color: TeacherColors.secondaryText.withOpacity(0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.subjectColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.subjectColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    widget.assessmentType.toUpperCase(),
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: widget.subjectColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.score,
                  value: '$_totalMarks',
                  label: 'Total Marks',
                ),
                _buildInfoItem(
                  icon: Icons.people,
                  value: '${_students.length}',
                  label: 'Students',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      {required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          color: widget.subjectColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TeacherTextStyles.cardTitle.copyWith(
                color: TeacherColors.primaryText,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TeacherTextStyles.listItemSubtitle.copyWith(
                color: TeacherColors.secondaryText.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentMarkCard(Map<String, dynamic> student) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: TeacherColors.secondaryBackground.withOpacity(0.4),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Student Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.subjectColor.withOpacity(0.3),
                    widget.subjectColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  student['student_name'][0].toUpperCase(),
                  style: TeacherTextStyles.cardTitle.copyWith(
                    color: widget.subjectColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['student_name'],
                    style: TeacherTextStyles.listItemTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${student['StudentID'] ?? student['rfid']}',
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Marks Input
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _markControllers[student['rfid'].toString()],
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                style: TeacherTextStyles.listItemTitle.copyWith(
                  color: TeacherColors.primaryText,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: TeacherColors.primaryBackground.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.subjectColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  suffixText: '/$_totalMarks',
                  suffixStyle: TeacherTextStyles.listItemSubtitle.copyWith(
                    fontSize: 10,
                  ),
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
  }

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}