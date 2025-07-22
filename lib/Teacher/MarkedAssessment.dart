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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          style: TeacherTextStyles.className.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subjectColor.withOpacity(0.9),
                widget.subjectColor.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.subjectColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, size: 28),
            onPressed: _navigateToEditMarks,
            tooltip: 'Edit Marks',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.subjectColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Results...',
              style: TeacherTextStyles.listItemTitle.copyWith(
                color: TeacherColors.primaryText.withOpacity(0.7),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: widget.subjectColor,
        backgroundColor: TeacherColors.primaryBackground,
        displacement: 40,
        strokeWidth: 3,
        child: CustomScrollView(
          slivers: [
            // Assessment details header
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.subjectColor.withOpacity(0.15),
                      widget.subjectColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.subjectColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _assessmentDetails['title'] ??
                                  (widget.isQuiz
                                      ? 'Quiz ${_assessmentDetails['quiz_number']}'
                                      : 'Assessment'),
                              style: TeacherTextStyles.assignmentTitle.copyWith(
                                fontSize: 22,
                                color: widget.subjectColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.subjectColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.subjectColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${_assessmentDetails['total_marks'] ?? 'N/A'} pts',
                              style: TeacherTextStyles.listItemTitle.copyWith(
                                color: widget.subjectColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: widget.subjectColor.withOpacity(0.7),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Type: ${_assessmentDetails['assessment_type'] ?? 'Other'}',
                            style: TeacherTextStyles.listItemSubtitle.copyWith(
                              color: TeacherColors.primaryText.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: widget.subjectColor.withOpacity(0.7),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Date: ${DateFormat('MMM d, y').format(
                                HttpDate.parse(_assessmentDetails['created_at']))}',
                            style: TeacherTextStyles.listItemSubtitle.copyWith(
                              color: TeacherColors.primaryText.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Students list header
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        'Students (${_markedStudents.length})',
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Marks',
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          fontSize: 16,
                          color: TeacherColors.primaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Students list with marks
            _markedStudents.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 60,
                      color: TeacherColors.primaryText.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No students marked yet',
                      style: TeacherTextStyles.listItemTitle.copyWith(
                        color: TeacherColors.primaryText.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _navigateToEditMarks,
                      child: Text(
                        'Enter Marks Now',
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          color: widget.subjectColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final student = _markedStudents[index];
                  final totalMarks =
                      _assessmentDetails['total_marks']?.toDouble() ?? 100.0;
                  final marks = student['marks_achieved']?.toDouble() ?? 0.0;
                  final grade = _calculateGrade(marks, totalMarks);

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TeacherColors.cardBackground.withOpacity(0.7),
                          TeacherColors.cardBackground.withOpacity(0.4),
                        ],
                      ),
                      border: Border.all(
                        color: TeacherColors.cardBorder.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.subjectColor.withOpacity(0.3),
                              widget.subjectColor.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(
                            color: widget.subjectColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            student['student_name'][0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.subjectColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        student['student_name'],
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${student['StudentID'] ?? student['rfid']}',
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${marks.toStringAsFixed(1)}/${totalMarks.toStringAsFixed(0)}',
                            style: TeacherTextStyles.statValue.copyWith(
                              color: widget.subjectColor,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getGradeColor(grade),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: TeacherTextStyles.cardSubtitle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getGradeColor(grade),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _markedStudents.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}