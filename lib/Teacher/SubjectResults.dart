import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'CreateAssessment.dart';
import 'EnterMarks.dart';
import 'MarkedAssessment.dart';
import 'package:flutter/animation.dart';

class SubjectResultsScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectResultsScreen({super.key, required this.subject});

  @override
  _SubjectResultsScreenState createState() => _SubjectResultsScreenState();
}

class _SubjectResultsScreenState extends State<SubjectResultsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> assessments = [];
  List<Map<String, dynamic>> quizzes = [];
  bool isLoading = true;
  final String _apiUrl = 'http://193.203.162.232:5050/SubjectAssessment/api';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _fetchAssessments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          _animationController.forward();
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            style: TeacherTextStyles.className.copyWith(
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TeacherColors.primaryBackground.withOpacity(0.9),
                  TeacherColors.primaryBackground.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: subjectColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: subjectColor,
            unselectedLabelColor: TeacherColors.primaryText.withOpacity(0.6),
            labelStyle: TeacherTextStyles.primaryButton,
            unselectedLabelStyle: TeacherTextStyles.primaryButton.copyWith(
              color: TeacherColors.primaryText.withOpacity(0.6),
            ),
            tabs: const [
              Tab(text: 'Generate Reports'),
              Tab(text: 'Assessments'),
            ],
          ),
        ),
        body: TabBarView(
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Report Generation Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: TeacherColors.secondaryBackground.withOpacity(0.6),
                border: Border.all(
                  color: subjectColor.withOpacity(0.2),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Assessment Report',
                          style: TeacherTextStyles.sectionHeader.copyWith(
                            color: subjectColor.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: TeacherColors.primaryBackground.withOpacity(0.4),
                            border: Border.all(
                              color: TeacherColors.cardBorder.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: 'Assessment Type',
                              labelStyle: TeacherTextStyles.cardSubtitle,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const SizedBox(height: 20),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                subjectColor.withOpacity(0.8),
                                subjectColor.withOpacity(0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _generateReport(selectedType),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Generate Report',
                                    style: TeacherTextStyles.primaryButton.copyWith(
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Report Preview Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: TeacherColors.secondaryBackground.withOpacity(0.6),
                border: Border.all(
                  color: subjectColor.withOpacity(0.2),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Report Preview',
                          style: TeacherTextStyles.sectionHeader.copyWith(
                            color: subjectColor.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Monthly Assessment Report - July 2023',
                          style: TeacherTextStyles.listItemTitle,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: TeacherColors.primaryBackground.withOpacity(0.4),
                            border: Border.all(
                              color: TeacherColors.cardBorder.withOpacity(0.3),
                            ),
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) => subjectColor.withOpacity(0.1),
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
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  subjectColor.withOpacity(0.7),
                                  subjectColor.withOpacity(0.5),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: subjectColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Report downloaded successfully',
                                        style: TeacherTextStyles.cardSubtitle,
                                      ),
                                      backgroundColor: TeacherColors.successAccent.withOpacity(0.2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.download,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Download Report',
                                        style: TeacherTextStyles.secondaryButton,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$type report generated successfully',
          style: TeacherTextStyles.cardSubtitle,
        ),
        backgroundColor: TeacherColors.successAccent.withOpacity(0.2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAssessmentsTab(Color subjectColor) {
    final allAssessments = [
      ...assessments.map((a) => {...a, 'is_quiz': false}),
      ...quizzes.map((q) => {...q, 'is_quiz': true}),
    ]..sort((a, b) => b['created_at'].compareTo(a['created_at']));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Create Assessment Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    subjectColor.withOpacity(0.8),
                    subjectColor.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: subjectColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Assessment',
                            style: TeacherTextStyles.primaryButton.copyWith(
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Assessments List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: allAssessments.length,
              itemBuilder: (context, index) {
                final assessment = allAssessments[index];
                final isMarked = (assessment['is_marked'] == 1);
                final isQuiz = assessment['is_quiz'] ?? false;

                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.1 * index,
                        1.0,
                        curve: Curves.easeOutQuart,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: TeacherColors.secondaryBackground.withOpacity(0.6),
                      border: Border.all(
                        color: subjectColor.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          subjectColor.withOpacity(0.3),
                                          subjectColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: subjectColor.withOpacity(0.5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: subjectColor.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isQuiz ? Icons.quiz : Icons.assignment,
                                      color: subjectColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isQuiz
                                              ? 'Quiz ${assessment['quiz_number']}'
                                              : assessment['title'].toString(),
                                          style: TeacherTextStyles.cardTitle,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isQuiz
                                              ? 'Quiz for ${assessment['monthly_assessment_title']}'
                                              : 'Type: ${assessment['assessment_type']}',
                                          style: TeacherTextStyles.listItemSubtitle.copyWith(
                                            color: TeacherColors.primaryText.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Date: ${DateFormat('MMM d, y').format(
                                            DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
                                                .parse(assessment['created_at'], true)
                                                .toLocal(),
                                          )}',
                                          style: TeacherTextStyles.listItemSubtitle.copyWith(
                                            color: TeacherColors.primaryText.withOpacity(0.7),
                                          ),
                                        ),
                                        if (isQuiz)
                                          Text(
                                            'Total Marks: ${assessment['total_marks'] ?? 15}',
                                            style: TeacherTextStyles.listItemSubtitle.copyWith(
                                              color: TeacherColors.primaryText.withOpacity(0.7),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isMarked ? Icons.check_circle : Icons.pending,
                                    color: isMarked
                                        ? TeacherColors.successAccent
                                        : TeacherColors.warningAccent,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
