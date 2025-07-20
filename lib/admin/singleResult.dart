import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
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
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor:AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.assessmentType.toUpperCase(),
                style: AdminTextStyles.sectionHeader.copyWith(
                  color: AdminColors.primaryText,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AdminColors.primaryAccent,
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
                      AdminColors.primaryAccent.withOpacity(0.7),
                      AdminColors.secondaryAccent.withOpacity(0.7),
                      AdminColors.infoAccent.withOpacity(0.7),
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
                      color: AdminColors.primaryText,
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
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
              ),
            ),
          )
              : _examResults.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 60,
                      color: AdminColors.disabledText),
                  SizedBox(height: 16),
                  Text(
                    'No assessment data found',
                    style:AdminTextStyles.cardSubtitle.copyWith(
                      color: AdminColors.disabledText,
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchAssessmentData,
                    child: Text(
                      'Retry',
                      style: AdminTextStyles.secondaryButton.copyWith(
                        color: AdminColors.primaryAccent,
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
                final examResult = _examResults[index];
                return Column(
                  children: [
                    _buildExamHeader(examResult.examName, colors, textStyles),
                    _buildResultsTable(examResult, colors, textStyles),
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

  Widget _buildExamHeader(String examName, AdminColors colors, AdminTextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        decoration: AdminColors.resultsColor.toGlassDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              examName,
              style: AdminTextStyles.sectionTitle(AdminColors.primaryText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable(ExamResult examResult, AdminColors colors, AdminTextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: AdminColors.glassDecoration(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            dataRowHeight: 48,
            headingRowHeight: 40,
            columns: _isMonthlyAssessment
                ? [
              DataColumn(
                  label: Text('Subject', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Quiz 1', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Quiz 2', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Quiz 3', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Avg Quiz', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Total', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Marks', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Achieved', style: _headerTextStyle(textStyles, colors))),
            ]
                : [
              DataColumn(
                  label: Text('Subject', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Total', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Marks', style: _headerTextStyle(textStyles, colors))),
              DataColumn(
                  label: Text('Percentage', style: _headerTextStyle(textStyles, colors))),
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
                  DataCell(Text(subject.subjectName,
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.quiz1.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.quiz2.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.quiz3.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(avgQuiz.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.assessmentTotal.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.assessmentMarks.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _getScoreColor(totalAchieved, subject.assessmentTotal)
                            .withOpacity(0.2),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          totalAchieved.toStringAsFixed(1),
                          style: _cellTextStyle(textStyles, colors),
                        ),
                      ),
                    ),
                  ),
                ]
                    : [
                  DataCell(Text(subject.subjectName,
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.assessmentTotal.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(Text(subject.assessmentMarks.toStringAsFixed(1),
                      style: _cellTextStyle(textStyles, colors))),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _getScoreColor(
                            subject.assessmentMarks, subject.assessmentTotal)
                            .withOpacity(0.2),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: _cellTextStyle(textStyles, colors),
                        ),
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

  TextStyle _headerTextStyle(AdminTextStyles textStyles, AdminColors colors) {
    return AdminTextStyles.cardTitle.copyWith(
      color: AdminColors.primaryAccent,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _cellTextStyle(AdminTextStyles textStyles, AdminColors colors) {
    return AdminTextStyles.cardSubtitle.copyWith(
      color: AdminColors.primaryText,
    );
  }

  Color _getScoreColor(double score, double total) {
    if (total == 0) return Colors.transparent;

    final percentage = (score / total) * 100;
    if (percentage >= 85) {
      return AdminColors.successAccent;
    } else if (percentage >= 70) {
      return AdminColors.warningAccent;
    } else if (percentage >= 50) {
      return AdminColors.infoAccent;
    } else {
      return AdminColors.dangerAccent;
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