import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingleResultScreen extends StatefulWidget {
  final String studentId;
  final String assessmentType;

  const SingleResultScreen({
    Key? key,
    required this.studentId,
    required this.assessmentType,
  }) : super(key: key);

  @override
  _SingleResultScreenState createState() => _SingleResultScreenState();
}

class _SingleResultScreenState extends State<SingleResultScreen> {
  List<ExamResult> _examResults = [];
  bool _isLoading = true;
  bool _isMonthlyAssessment = false;

  @override
  void initState() {
    super.initState();
    _isMonthlyAssessment = widget.assessmentType.toLowerCase().contains('monthly');
    _fetchAssessmentData();
  }

  Future<void> _fetchAssessmentData() async {
    setState(() => _isLoading = true);
    final url = _isMonthlyAssessment
        ? 'http://193.203.162.232:5050/result/get_assessment_monthly?student_id=${widget.studentId}'
        : 'http://193.203.162.232:5050/result/get_assessment_else?student_id=${widget.studentId}&type=${widget.assessmentType}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _examResults = _parseAssessmentData(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load assessment data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  List<ExamResult> _parseAssessmentData(Map<String, dynamic> data) {
    final List<ExamResult> results = [];
    final assessments = data['assessments'] as Map<String, dynamic>;

    int examNumber = 1;
    assessments.forEach((key, value) {
      final List<SubjectAssessment> subjects = [];
      final assessmentsArray = value as List;

      for (var item in assessmentsArray) {
        final subjectName = item['subject_name']?.toString() ?? 'Unknown';
        final quiz1 = _isMonthlyAssessment ? (item['quiz_marks'] ?? 0.0).toDouble() : 0.0;
        final quiz2 = 0.0; // Placeholder for other quizzes
        final quiz3 = 0.0; // Placeholder for other quizzes
        final assessmentMarks = (item['assessment_marks'] ?? 0.0).toDouble();
        final assessmentTotal = (item['assessment_total'] ?? 0.0).toDouble();

        subjects.add(SubjectAssessment(
          subjectName: subjectName,
          quiz1: quiz1,
          quiz2: quiz2,
          quiz3: quiz3,
          assessmentMarks: assessmentMarks,
          assessmentTotal: assessmentTotal,
        ));
      }

      results.add(ExamResult(
        examName: 'Exam $examNumber',
        subjects: subjects,
      ));
      examNumber++;
    });

    return results;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.assessmentType.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade900,
                      Colors.indigo.shade800,
                      Colors.purple.shade900,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.assessment,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          )
              : _examResults.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No assessment data found',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: _fetchAssessmentData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final examResult = _examResults[index];
                return Column(
                  children: [
                    _buildExamHeader(examResult.examName),
                    _buildResultsTable(examResult),
                    SizedBox(height: 16),
                  ],
                );
              },
              childCount: _examResults.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamHeader(String examName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Card(
        color: Colors.blue.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              examName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable(ExamResult examResult) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _isMonthlyAssessment
                ? [
              DataColumn(label: Text('Subject', style: _headerTextStyle())),
              DataColumn(label: Text('Quiz 1', style: _headerTextStyle())),
              DataColumn(label: Text('Quiz 2', style: _headerTextStyle())),
              DataColumn(label: Text('Quiz 3', style: _headerTextStyle())),
              DataColumn(label: Text('Avg Quiz', style: _headerTextStyle())),
              DataColumn(label: Text('Total', style: _headerTextStyle())),
              DataColumn(label: Text('Marks', style: _headerTextStyle())),
              DataColumn(label: Text('Achieved', style: _headerTextStyle())),
            ]
                : [
              DataColumn(label: Text('Subject', style: _headerTextStyle())),
              DataColumn(label: Text('Total', style: _headerTextStyle())),
              DataColumn(label: Text('Marks', style: _headerTextStyle())),
              DataColumn(label: Text('Percentage', style: _headerTextStyle())),
            ],
            rows: examResult.subjects.map((subject) {
              final avgQuiz = (subject.quiz1 + subject.quiz2 + subject.quiz3) / 3;
              final totalAchieved = avgQuiz + subject.assessmentMarks;
              final percentage = subject.assessmentTotal > 0
                  ? (subject.assessmentMarks / subject.assessmentTotal) * 100
                  : 0;

              return DataRow(
                cells: _isMonthlyAssessment
                    ? [
                  DataCell(Text(subject.subjectName, style: _cellTextStyle())),
                  DataCell(Text(subject.quiz1.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(subject.quiz2.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(subject.quiz3.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(avgQuiz.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(subject.assessmentTotal.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(subject.assessmentMarks.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(
                    Container(
                      color: _getScoreColor(totalAchieved, subject.assessmentTotal),
                      padding: EdgeInsets.all(8),
                      child: Text(
                        totalAchieved.toStringAsFixed(1),
                        style: _cellTextStyle(),
                      ),
                    ),
                  ),
                ]
                    : [
                  DataCell(Text(subject.subjectName, style: _cellTextStyle())),
                  DataCell(Text(subject.assessmentTotal.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(Text(subject.assessmentMarks.toStringAsFixed(1), style: _cellTextStyle())),
                  DataCell(
                    Container(
                      color: _getScoreColor(subject.assessmentMarks, subject.assessmentTotal),
                      padding: EdgeInsets.all(8),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: _cellTextStyle(),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return TextStyle(
      color: Colors.blueAccent,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _cellTextStyle() {
    return TextStyle(
      color: Colors.white,
    );
  }

  Color _getScoreColor(double score, double total) {
    if (total == 0) return Colors.transparent;

    final percentage = (score / total) * 100;
    if (percentage >= 85) {
      return Colors.green.shade800.withOpacity(0.3);
    } else if (percentage >= 70) {
      return Colors.lightGreen.shade800.withOpacity(0.3);
    } else if (percentage >= 50) {
      return Colors.orange.shade800.withOpacity(0.3);
    } else {
      return Colors.red.shade800.withOpacity(0.3);
    }
  }
}

class ExamResult {
  final String examName;
  final List<SubjectAssessment> subjects;

  ExamResult({
    required this.examName,
    required this.subjects,
  });
}

class SubjectAssessment {
  final String subjectName;
  final double quiz1;
  final double quiz2;
  final double quiz3;
  final double assessmentMarks;
  final double assessmentTotal;

  SubjectAssessment({
    required this.subjectName,
    required this.quiz1,
    required this.quiz2,
    required this.quiz3,
    required this.assessmentMarks,
    required this.assessmentTotal,
  });
}