import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'EnterMarks.dart';


class MarkedAssessmentsScreen extends StatefulWidget {
  final String assessmentId;
  final bool isQuiz;
  final Color subjectColor;

  const MarkedAssessmentsScreen({
    super.key,
    required this.assessmentId,
    required this.isQuiz,
    required this.subjectColor,
  });

  @override
  _MarkedAssessmentsScreenState createState() => _MarkedAssessmentsScreenState();
}

class _MarkedAssessmentsScreenState extends State<MarkedAssessmentsScreen> {
  List<Map<String, dynamic>> _markedStudents = [];
  Map<String, dynamic> _assessmentDetails = {};
  bool _isLoading = true;
  bool _isRefreshing = false;

  final String baseUrl = 'http://193.203.162.232:5050/SubjectAssessment/api';
  final String marksEndpoint = '/assessment-marks';

  @override
  void initState() {
    super.initState();
    _fetchMarkedAssessment();
  }

  Future<void> _fetchMarkedAssessment() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$marksEndpoint?assessment_id=${widget.assessmentId}&is_quiz=${widget.isQuiz}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _assessmentDetails = data['assessment_details'];
          _markedStudents = List<Map<String, dynamic>>.from(data['students']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load marked assessment');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: TeacherTextStyles.listItemTitle),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _fetchMarkedAssessment();
    setState(() => _isRefreshing = false);
  }

  void _navigateToEditMarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnterMarksScreen(
          assessmentId: widget.assessmentId,
          assessmentTitle: _assessmentDetails['title'] ??
              (widget.isQuiz ? 'Quiz ${_assessmentDetails['quiz_number']}' : 'Assessment'),
          assessmentType: _assessmentDetails['assessment_type'] ?? 'Other',
          subjectColor: widget.subjectColor,
          isQuiz: widget.isQuiz,
        ),
      ),
    ).then((_) => _refreshData());
  }

  String _calculateGrade(double marks, double totalMarks) {
    final percentage = (marks / totalMarks) * 100;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return TeacherColors.successAccent;
      case 'A':
        return TeacherColors.successAccent.withOpacity(0.8);
      case 'B':
        return TeacherColors.warningAccent.withOpacity(0.6);
      case 'C':
        return TeacherColors.warningAccent;
      case 'D':
        return TeacherColors.dangerAccent.withOpacity(0.8);
      default:
        return TeacherColors.dangerAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.isQuiz ? 'Quiz Results' : 'Assessment Results',
          style: TeacherTextStyles.className,
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: TeacherColors.primaryText),
            onPressed: _navigateToEditMarks,
            tooltip: 'Edit Marks',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: TeacherColors.primaryAccent,
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: TeacherColors.primaryAccent,
        backgroundColor: TeacherColors.primaryBackground,
        child: _markedStudents.isEmpty
            ? Center(
          child: Text(
            'No students marked yet',
            style: TeacherTextStyles.listItemTitle,
          ),
        )
            : SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Assessment details header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.subjectColor.withOpacity(0.2),
                      widget.subjectColor.withOpacity(0.1),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: TeacherColors.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assessmentDetails['title'] ??
                          (widget.isQuiz ? 'Quiz ${_assessmentDetails['quiz_number']}' : 'Assessment'),
                      style: TeacherTextStyles.assignmentTitle,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Type: ${_assessmentDetails['assessment_type'] ?? 'Other'}',
                          style: TeacherTextStyles.listItemSubtitle,
                        ),
                        Text(
                          'Total Marks: ${_assessmentDetails['total_marks'] ?? 'N/A'}',
                          style: TeacherTextStyles.listItemSubtitle,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMM d, y').format(
                          HttpDate.parse(_assessmentDetails['created_at'])
                      )}',
                      style: TeacherTextStyles.listItemSubtitle,
                    ),
                  ],
                ),
              ),

              // Students list with marks
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _markedStudents.length,
                itemBuilder: (context, index) {
                  final student = _markedStudents[index];
                  final totalMarks = _assessmentDetails['total_marks']?.toDouble() ?? 100.0;
                  final marks = student['marks_achieved']?.toDouble() ?? 0.0;
                  final grade = _calculateGrade(marks, totalMarks);

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: TeacherColors.glassDecoration(),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.subjectColor.withOpacity(0.2),
                        child: Text(
                          student['student_name'][0],
                          style: TeacherTextStyles.listItemTitle.copyWith(
                            color: TeacherColors.primaryText,
                          ),
                        ),
                      ),
                      title: Text(
                        student['student_name'],
                        style: TeacherTextStyles.listItemTitle,
                      ),
                      subtitle: Text(
                        'ID: ${student['StudentID'] ?? student['rfid']}',
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${marks.toStringAsFixed(1)}/${totalMarks.toStringAsFixed(0)}',
                            style: TeacherTextStyles.statValue.copyWith(
                              color: TeacherColors.primaryAccent,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getGradeColor(grade),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: TeacherTextStyles.cardSubtitle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getGradeColor(grade),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}