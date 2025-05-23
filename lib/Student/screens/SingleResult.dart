import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_design_system.dart';
import '../utils/theme.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isMonthlyAssessment = widget.assessmentType.toLowerCase().contains('monthly');
    _fetchAssessmentData();
  }

  Future<void> _fetchAssessmentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = _isMonthlyAssessment
          ? 'http://193.203.162.232:5050/result/get_assessment_monthly?student_id=${widget.studentId}'
          : 'http://193.203.162.232:5050/result/get_assessment_else?student_id=${widget.studentId}&type=${widget.assessmentType}';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('assessments')) {
          setState(() {
            _examResults = _parseAssessmentData(data);
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid data format: Missing assessments key');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}';
      });
    }
  }

  List<ExamResult> _parseAssessmentData(Map<String, dynamic> data) {
    final List<ExamResult> results = [];
    final assessments = data['assessments'] as Map<String, dynamic>? ?? {};

    assessments.forEach((examKey, examData) {
      final List<SubjectAssessment> subjects = [];

      // Handle both List and Map formats for examData
      if (examData is List) {
        for (var item in examData) {
          subjects.add(_parseSubjectData(item));
        }
      } else if (examData is Map) {
        examData.forEach((subjectKey, subjectData) {
          if (subjectData is Map) {
            subjects.add(_parseSubjectData(subjectData as Map<String, dynamic>));
          }
        });
      }

      if (subjects.isNotEmpty) {
        results.add(ExamResult(
          examName: examKey.replaceAll('_', ' ').toUpperCase(),
          subjects: subjects,
        ));
      }
    });

    return results;
  }

  SubjectAssessment _parseSubjectData(Map<String, dynamic> item) {
    return SubjectAssessment(
      subjectName: item['subject_name']?.toString() ?? 'Unknown',
      quiz1: _isMonthlyAssessment ? _parseDouble(item['quiz_marks']) : 0.0,
      quiz2: 0.0, // Placeholder for other quizzes if needed
      quiz3: 0.0, // Placeholder for other quizzes if needed
      assessmentMarks: _parseDouble(item['assessment_marks']),
      assessmentTotal: _parseDouble(item['assessment_total']),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppDesignSystem.appBar(context, widget.assessmentType),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAssessmentData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      )
          : _examResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No assessment data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAssessmentData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Refresh', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: AppDesignSystem.defaultPadding,
        itemCount: _examResults.length,
        itemBuilder: (context, index) {
          final examResult = _examResults[index];
          return _buildExamCard(examResult);
        },
      ),
    );
  }

  Widget _buildExamCard(ExamResult examResult) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              examResult.examName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowHeight: 48,
                headingRowHeight: 40,
                columns: _isMonthlyAssessment
                    ? [
                  DataColumn(label: _buildHeaderCell('Subject')),
                  DataColumn(label: _buildHeaderCell('Quiz 1')),
                  DataColumn(label: _buildHeaderCell('Quiz 2')),
                  DataColumn(label: _buildHeaderCell('Quiz 3')),
                  DataColumn(label: _buildHeaderCell('Avg Quiz')),
                  DataColumn(label: _buildHeaderCell('Total')),
                  DataColumn(label: _buildHeaderCell('Marks')),
                  DataColumn(label: _buildHeaderCell('Achieved')),
                ]
                    : [
                  DataColumn(label: _buildHeaderCell('Subject')),
                  DataColumn(label: _buildHeaderCell('Total')),
                  DataColumn(label: _buildHeaderCell('Marks')),
                  DataColumn(label: _buildHeaderCell('Percentage')),
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
                      _buildDataCell(subject.subjectName),
                      _buildDataCell(subject.quiz1.toStringAsFixed(1)),
                      _buildDataCell(subject.quiz2.toStringAsFixed(1)),
                      _buildDataCell(subject.quiz3.toStringAsFixed(1)),
                      _buildDataCell(avgQuiz.toStringAsFixed(1)),
                      _buildDataCell(subject.assessmentTotal.toStringAsFixed(1)),
                      _buildDataCell(subject.assessmentMarks.toStringAsFixed(1)),
                      _buildScoreCell(totalAchieved.toStringAsFixed(1),
                          totalAchieved, subject.assessmentTotal),
                    ]
                        : [
                      _buildDataCell(subject.subjectName),
                      _buildDataCell(subject.assessmentTotal.toStringAsFixed(1)),
                      _buildDataCell(subject.assessmentMarks.toStringAsFixed(1)),
                      _buildScoreCell('${percentage.toStringAsFixed(1)}%',
                          subject.assessmentMarks, subject.assessmentTotal),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  DataCell _buildDataCell(String text) {
    return DataCell(
      Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
        ),
      ),
    );
  }
  DataCell _buildScoreCell(String text, double achieved, double total) {
    final color = achieved >= (total * 0.5) ? Colors.green : Colors.red;
    return DataCell(
      Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Color _getScoreColor(double score, double total) {
    if (total == 0) return Colors.grey;

    final percentage = (score / total) * 100;
    if (percentage >= 85) {
      return AppColors.success;
    } else if (percentage >= 70) {
      return AppColors.info;
    } else if (percentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
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