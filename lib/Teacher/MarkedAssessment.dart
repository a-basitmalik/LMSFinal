import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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

  final String baseUrl = 'http://192.168.18.185:5050/SubjectAssessment/api';
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
        SnackBar(content: Text('Error: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isQuiz ? 'Quiz Results' : 'Assessment Results',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _navigateToEditMarks,
            tooltip: 'Edit Marks',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: _markedStudents.isEmpty
            ? Center(
          child: Text(
            'No students marked yet',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        )
            : SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Assessment details header
              Container(
                padding: EdgeInsets.all(16),
                color: widget.subjectColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assessmentDetails['title'] ??
                          (widget.isQuiz ? 'Quiz ${_assessmentDetails['quiz_number']}' : 'Assessment'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Type: ${_assessmentDetails['assessment_type'] ?? 'Other'}',
                          style: GoogleFonts.poppins(),
                        ),
                        Text(
                          'Total Marks: ${_assessmentDetails['total_marks'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMM d, y').format(
                          HttpDate.parse(_assessmentDetails['created_at'])
                      )
                      }',
                      style: GoogleFonts.poppins(),
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

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(student['student_name'][0]),
                      ),
                      title: Text(
                        student['student_name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${student['StudentID'] ?? student['rfid']}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${marks.toStringAsFixed(1)}/${totalMarks.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
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
                              style: GoogleFonts.poppins(
                                fontSize: 12,
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

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.orangeAccent;
      default:
        return Colors.red;
    }
  }
}