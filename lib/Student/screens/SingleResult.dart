import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    final url = 'http://193.203.162.232:5050/result/get_assessments?student_id=${widget.studentId}&type=${widget.assessmentType}';

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
    final assessments = data['assessments'] as List;

    for (var assessmentGroup in assessments) {
      final sequence = assessmentGroup['sequence'] as int;
      final assessmentsList = assessmentGroup['assessments'] as List;

      // Group assessments by subject name
      final Map<String, List<Map<String, dynamic>>> subjectsMap = {};

      for (var assessment in assessmentsList) {
        final subjectName = assessment['subject_name'] as String;
        if (!subjectsMap.containsKey(subjectName)) {
          subjectsMap[subjectName] = [];
        }
        subjectsMap[subjectName]!.add(assessment);
      }

      final List<SubjectAssessment> subjects = [];

      subjectsMap.forEach((subjectName, assessments) {
        // Collect all quiz marks for this subject
        final quizMarks = assessments
            .map((a) => (a['quiz_marks'] ?? 0.0).toDouble())
            .where((mark) => mark > 0)
            .toList();

        // Get assessment marks and total (should be same for all entries of same subject)
        final assessmentMarks = assessments.first['assessment_marks']?.toDouble() ?? 0.0;
        final assessmentTotal = assessments.first['total_marks']?.toDouble() ?? 0.0;

        subjects.add(SubjectAssessment(
          subjectName: subjectName,
          quiz1: quizMarks.length > 0 ? quizMarks[0] : 0.0,
          quiz2: quizMarks.length > 1 ? quizMarks[1] : 0.0,
          quiz3: quizMarks.length > 2 ? quizMarks[2] : 0.0,
          assessmentMarks: assessmentMarks,
          assessmentTotal: assessmentTotal,
        ));
      });

      final examName = _isMonthlyAssessment
          ? 'Monthly ${sequence - 99}'
          : '${widget.assessmentType} ${sequence}';

      results.add(ExamResult(
        examName: examName,
        subjects: subjects,
        sequence: sequence,
      ));
    }

    // Sort results by sequence number
    results.sort((a, b) {
      if (_isMonthlyAssessment) {
        final aNum = int.parse(a.examName.replaceAll(RegExp(r'[^0-9]'), ''));
        final bNum = int.parse(b.examName.replaceAll(RegExp(r'[^0-9]'), ''));
        return aNum.compareTo(bNum);
      } else {
        return a.examName.compareTo(b.examName);
      }
    });

    return results;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TeacherTextStyles.cardSubtitle,
        ),
        backgroundColor: TeacherColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.assessmentType.toUpperCase(),
                style: TeacherTextStyles.sectionHeader.copyWith(
                  color: TeacherColors.primaryText,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: TeacherColors.primaryAccent,
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
                      TeacherColors.primaryAccent.withOpacity(0.7),
                      TeacherColors.secondaryAccent.withOpacity(0.7),
                      TeacherColors.infoAccent.withOpacity(0.7),
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
                      color: TeacherColors.primaryText,
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
                valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
              ),
            ),
          )
              : _examResults.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: TeacherColors.secondaryText,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No assessment data found',
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.secondaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchAssessmentData,
                    child: Text(
                      'Retry',
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: TeacherColors.primaryAccent,
                        fontWeight: FontWeight.bold,
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
                    _buildExamHeader(examResult.examName, colors, textStyles, examResult.sequence),
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

  Widget _buildExamHeader(String examName, TeacherColors colors, TeacherTextStyles textStyles, int sequence) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        decoration: TeacherColors.glassDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                examName,
                style: TeacherTextStyles.cardTitle,
              ),
              IconButton(
                icon: Icon(
                  Icons.download,
                  color: TeacherColors.primaryAccent,
                ),
                onPressed: () => _downloadReport(sequence),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReport(int sequence) async {
    try {
      setState(() => _isLoading = true);

      final url = _isMonthlyAssessment
          ? 'http://193.203.162.232:5050/result/generate_monthly_report?student_id=${widget.studentId}&sequence=$sequence'
          : 'http://193.203.162.232:5050/result/generate_sendup_report?student_id=${widget.studentId}&sequence=$sequence';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get download directory
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final fileName = _isMonthlyAssessment
            ? 'Monthly_Report_${widget.studentId}_$sequence.docx'
            : 'SendUp_Report_${widget.studentId}_$sequence.docx';
        final filePath = '${directory.path}/$fileName';

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        await OpenFile.open(filePath);

        Fluttertoast.showToast(
          msg: 'Report saved to $filePath',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: TeacherColors.successAccent,
          textColor: Colors.white,
        );
      } else {
        throw Exception('Failed to download report: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: TeacherColors.dangerAccent,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildResultsTable(ExamResult examResult, TeacherColors colors, TeacherTextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: TeacherColors.glassDecoration(),
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
                        borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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

  TextStyle _headerTextStyle(TeacherTextStyles textStyles, TeacherColors colors) {
    return TeacherTextStyles.cardSubtitle.copyWith(
      color: TeacherColors.primaryAccent,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _cellTextStyle(TeacherTextStyles textStyles, TeacherColors colors) {
    return TeacherTextStyles.cardSubtitle.copyWith(
      color: TeacherColors.primaryText,
    );
  }

  Color _getScoreColor(double score, double total) {
    if (total == 0) return Colors.transparent;

    final percentage = (score / total) * 100;
    if (percentage >= 85) {
      return TeacherColors.successAccent;
    } else if (percentage >= 70) {
      return TeacherColors.warningAccent;
    } else if (percentage >= 50) {
      return TeacherColors.infoAccent;
    } else {
      return TeacherColors.dangerAccent;
    }
  }
}

class ExamResult {
  final String examName;
  final int sequence;
  final List<SubjectAssessment> subjects;

  ExamResult({
    required this.examName,
    required this.sequence,
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