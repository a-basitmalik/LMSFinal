import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'CreateAssessment.dart';
import 'EnterMarks.dart';
import 'MarkedAssessment.dart';

class SubjectResultsScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectResultsScreen({super.key, required this.subject});

  @override
  _SubjectResultsScreenState createState() => _SubjectResultsScreenState();
}

class _SubjectResultsScreenState extends State<SubjectResultsScreen> {
  List<Map<String, dynamic>> assessments = [];
  List<Map<String, dynamic>> quizzes = [];
  bool isLoading = true;
  final String _apiUrl = 'http://193.203.162.232:5050/SubjectAssessment/api';

  @override
  void initState() {
    super.initState();
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/assessments?subject_id=${widget.subject['subject_id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          assessments = List<Map<String, dynamic>>.from(data['assessments']);
          quizzes = List<Map<String, dynamic>>.from(data['quizzes']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load assessments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading assessments: $e',
            style: TeacherTextStyles.cardSubtitle.copyWith(color: TeacherColors.dangerAccent),
          ),
          backgroundColor: TeacherColors.dangerAccent.withOpacity(0.2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = widget.subject['color'] ?? TeacherColors.primaryAccent;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TeacherColors.primaryBackground,
        appBar: AppBar(
          title: Text(
            '${widget.subject['name']} Assessments',
            style: TeacherTextStyles.className,
          ),
          backgroundColor: TeacherColors.primaryBackground,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: TeacherColors.primaryAccent,
            tabs: [
              Tab(child: Text('Generate Reports', style: TeacherTextStyles.primaryButton)),
              Tab(child: Text('Assessments', style: TeacherTextStyles.primaryButton)),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: TeacherColors.primaryAccent))
            : TabBarView(
          children: [
            _buildReportsTab(subjectColor),
            _buildAssessmentsTab(subjectColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(Color subjectColor) {
    final assessmentTypes = [
      'Monthly',
      'Send Up',
      'Mocks',
      'Other',
      'Test Session',
      'Weekly',
      'Half Book',
      'Full Book'
    ];
    String selectedType = assessmentTypes.first;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: TeacherColors.glassDecoration(),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Assessment Report',
                    style: TeacherTextStyles.sectionHeader,
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: TeacherColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Assessment Type',
                        labelStyle: TeacherTextStyles.cardSubtitle,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      dropdownColor: TeacherColors.secondaryBackground,
                      style: TeacherTextStyles.listItemTitle,
                      items: assessmentTypes
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _generateReport(selectedType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Generate Report',
                        style: TeacherTextStyles.primaryButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Report preview
          Container(
            decoration: TeacherColors.glassDecoration(),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Report Preview',
                    style: TeacherTextStyles.sectionHeader,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Monthly Assessment Report - July 2023',
                    style: TeacherTextStyles.listItemTitle,
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: TeacherColors.secondaryBackground.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) => subjectColor.withOpacity(0.2),
                      ),
                      columns: [
                        DataColumn(
                          label: Text('Student', style: TeacherTextStyles.cardTitle),
                        ),
                        DataColumn(
                          label: Text('Marks', style: TeacherTextStyles.cardTitle),
                        ),
                        DataColumn(
                          label: Text('Grade', style: TeacherTextStyles.cardTitle),
                        ),
                      ],
                      rows: [
                        DataRow(cells: [
                          DataCell(Text('Alice Johnson', style: TeacherTextStyles.listItemSubtitle)),
                          DataCell(Text('85/100', style: TeacherTextStyles.listItemSubtitle)),
                          DataCell(Text('A', style: TeacherTextStyles.listItemSubtitle)),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Bob Smith', style: TeacherTextStyles.listItemSubtitle)),
                          DataCell(Text('72/100', style: TeacherTextStyles.listItemSubtitle)),
                          DataCell(Text('B', style: TeacherTextStyles.listItemSubtitle)),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Report downloaded successfully',
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                            backgroundColor: TeacherColors.successAccent.withOpacity(0.2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                      ),
                      child: Text(
                        'Download Report',
                        style: TeacherTextStyles.secondaryButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating $type report...',
          style: TeacherTextStyles.cardSubtitle,
        ),
        backgroundColor: TeacherColors.infoAccent.withOpacity(0.2),
      ),
    );
    await Future.delayed(Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$type report generated successfully',
          style: TeacherTextStyles.cardSubtitle,
        ),
        backgroundColor: TeacherColors.successAccent.withOpacity(0.2),
      ),
    );
  }

  Widget _buildAssessmentsTab(Color subjectColor) {
    final allAssessments = [
      ...assessments.map((a) => {...a, 'is_quiz': false}),
      ...quizzes.map((q) => {...q, 'is_quiz': true}),
    ]..sort((a, b) => b['created_at'].compareTo(a['created_at']));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAssessmentScreen(
                      subjectId: widget.subject['subject_id'],
                      subjectColor: subjectColor,
                    ),
                  ),
                ).then((_) => _fetchAssessments());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: subjectColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Assessment',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: allAssessments.length,
            itemBuilder: (context, index) {
              final assessment = allAssessments[index];
              final isMarked = (assessment['is_marked'] == 1);
              final isQuiz = assessment['is_quiz'] ?? false;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: TeacherColors.glassDecoration(),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isQuiz ? Icons.quiz : Icons.assignment,
                      color: subjectColor,
                    ),
                  ),
                  title: Text(
                    isQuiz
                        ? 'Quiz ${assessment['quiz_number']}'
                        : assessment['title'].toString(),
                    style: TeacherTextStyles.cardTitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQuiz
                            ? 'Quiz for ${assessment['monthly_assessment_title']}'
                            : 'Type: ${assessment['assessment_type']}',
                        style: TeacherTextStyles.listItemSubtitle,
                      ),
                      Text(
                        'Date: ${DateFormat('MMM d, y').format(
                          DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
                              .parse(assessment['created_at'], true)
                              .toLocal(),
                        )}',
                        style: TeacherTextStyles.listItemSubtitle,
                      ),
                      if (isQuiz)
                        Text(
                          'Total Marks: ${assessment['total_marks'] ?? 15}',
                          style: TeacherTextStyles.listItemSubtitle,
                        ),
                    ],
                  ),
                  trailing: isMarked
                      ? Icon(Icons.check_circle, color: TeacherColors.successAccent)
                      : Icon(Icons.pending, color: TeacherColors.warningAccent),
                  onTap: () {
                    if (isMarked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkedAssessmentsScreen(
                            assessmentId: assessment[isQuiz ? 'quiz_id' : 'id'].toString(),
                            isQuiz: isQuiz,
                            subjectColor: subjectColor,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnterMarksScreen(
                            assessmentId: assessment[isQuiz ? 'quiz_id' : 'id'].toString(),
                            assessmentTitle: isQuiz
                                ? 'Quiz ${assessment['quiz_number']}'
                                : assessment['title'],
                            assessmentType: assessment['assessment_type'],
                            subjectColor: subjectColor,
                            isQuiz: isQuiz,
                          ),
                        ),
                      ).then((_) => _fetchAssessments());
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}