import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
        SnackBar(content: Text('Error loading assessments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.subject['name']} Assessments',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: subjectColor,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(child: Text('Generate Reports', style: GoogleFonts.poppins())),
              Tab(child: Text('Assessments', style: GoogleFonts.poppins())),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildReportsTab(theme, subjectColor),
            _buildAssessmentsTab(theme, subjectColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(ThemeData theme, Color subjectColor) {
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
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Assessment Report',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Assessment Type',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Placeholder for generated report preview
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Report Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Monthly Assessment Report - July 2023',
                    style: GoogleFonts.poppins(),
                  ),
                  SizedBox(height: 10),
                  DataTable(
                    columns: [
                      DataColumn(label: Text('Student')),
                      DataColumn(label: Text('Marks')),
                      DataColumn(label: Text('Grade')),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('Alice Johnson')),
                        DataCell(Text('85/100')),
                        DataCell(Text('A')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Bob Smith')),
                        DataCell(Text('72/100')),
                        DataCell(Text('B')),
                      ]),
                    ],
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Report downloaded successfully')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                      ),
                      child: Text('Download Report'),
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
    // In a real app, this would call your API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating $type report...')),
    );
    await Future.delayed(Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type report generated successfully')),
    );
  }

  Widget _buildAssessmentsTab(ThemeData theme, Color subjectColor) {
    // Combine assessments and quizzes
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    isQuiz
                        ? 'Quiz ${assessment['quiz_number']}'
                        : assessment['title'].toString(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQuiz
                            ? 'Quiz for ${assessment['monthly_assessment_title']}'
                            : 'Type: ${assessment['assessment_type']}',
                      ),
                      Text(
                        'Date: ${DateFormat('MMM d, y').format(
                          DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
                              .parse(assessment['created_at'], true)
                              .toLocal(),
                        )
                        }',
                      ),
                      if (isQuiz)
                        Text('Total Marks: ${assessment['total_marks'] ?? 15}'),
                    ],
                  ),
                  trailing: isMarked
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.pending, color: Colors.orange),
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