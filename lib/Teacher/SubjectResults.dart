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
  List<Map<String, dynamic>> results = [];
  List<Map<String, dynamic>> assessments = [];
  bool isLoading = true;
  final String _apiUrl = 'https://your-api-endpoint.com/results';

  @override
  void initState() {
    super.initState();
    _loadDummyData(); // Replace with _fetchResults() when API is ready
  }

  Future<void> _fetchResults() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?subject=${widget.subject['code']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          results = List<Map<String, dynamic>>.from(data['results']);
          assessments = List<Map<String, dynamic>>.from(data['assessments']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load results');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading results: $e')));
    }
  }

  void _loadDummyData() {
    setState(() {
      results = [
        {
          'student_id': '101',
          'student_name': 'Alice Johnson',
          'assignment_1': 85,
          'assignment_2': 90,
          'midterm': 78,
          'final_exam': 0,
          'total': 253,
        },
        {
          'student_id': '102',
          'student_name': 'Bob Smith',
          'assignment_1': 72,
          'assignment_2': 68,
          'midterm': 65,
          'final_exam': 0,
          'total': 205,
        },
        {
          'student_id': '103',
          'student_name': 'Charlie Brown',
          'assignment_1': 95,
          'assignment_2': 88,
          'midterm': 92,
          'final_exam': 0,
          'total': 275,
        },
      ];

      assessments = [
        {
          'id': '1',
          'title': 'Assignment 1',
          'type': 'assignment',
          'total_marks': 100,
          'date': '2023-06-10',
          'is_marked': true,
        },
        {
          'id': '2',
          'title': 'Assignment 2',
          'type': 'assignment',
          'total_marks': 100,
          'date': '2023-06-24',
          'is_marked': true,
        },
        {
          'id': '3',
          'title': 'Midterm Exam',
          'type': 'exam',
          'total_marks': 100,
          'date': '2023-07-08',
          'is_marked': true,
        },
        {
          'id': '4',
          'title': 'Final Exam',
          'type': 'exam',
          'total_marks': 100,
          'date': '2023-07-30',
          'is_marked': false,
        },
      ];
      isLoading = false;
    });
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
            '${widget.subject['name']} Results',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: subjectColor,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(child: Text('Student Results', style: GoogleFonts.poppins())),
              Tab(child: Text('Assessments', style: GoogleFonts.poppins())),
            ],
          ),
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [
                    _buildResultsTab(theme, subjectColor),
                    _buildAssessmentsTab(theme, subjectColor),
                  ],
                ),
      ),
    );
  }

  Widget _buildResultsTab(ThemeData theme, Color subjectColor) {
    final markedAssessments =
        assessments.where((a) => a['is_marked'] == true).toList();
    final averageScore =
        results.isEmpty
            ? 0
            : results.map((r) => r['total']).reduce((a, b) => a + b) /
                results.length;
    final topStudent =
        results.isEmpty
            ? null
            : results.reduce((a, b) => a['total'] > b['total'] ? a : b);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                  'Students',
                  results.length.toString(),
                  Icons.people,
                  subjectColor,
                ),
                _buildSummaryCard(
                  'Avg Score',
                  averageScore.toStringAsFixed(1),
                  Icons.bar_chart,
                  subjectColor,
                ),
                _buildSummaryCard(
                  'Top Student',
                  topStudent?['student_name'] ?? '-',
                  Icons.star,
                  subjectColor,
                ),
              ],
            ),
          ),

          // Results Table
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DataTable(
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: Text(
                    'Student',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
                ...markedAssessments.map((assessment) {
                  return DataColumn(
                    label: Text(
                      assessment['title'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ],
              rows:
                  results.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            student['student_name'],
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        ...markedAssessments.map((assessment) {
                          final key = assessment['title']
                              .toLowerCase()
                              .replaceAll(' ', '_');
                          return DataCell(
                            Text(
                              student[key]?.toString() ?? '-',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              SizedBox(height: 8),
              Text(title, style: GoogleFonts.poppins(fontSize: 12)),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeIndicator(int total, Color subjectColor) {
    String grade;
    Color color;
    IconData icon;

    if (total >= 280) {
      grade = 'A+';
      color = Colors.green;
      icon = Icons.sentiment_very_satisfied;
    } else if (total >= 250) {
      grade = 'A';
      color = Colors.green;
      icon = Icons.sentiment_satisfied;
    } else if (total >= 220) {
      grade = 'B+';
      color = Colors.lightGreen;
      icon = Icons.sentiment_neutral;
    } else if (total >= 190) {
      grade = 'B';
      color = Colors.lightGreen;
      icon = Icons.sentiment_neutral;
    } else if (total >= 160) {
      grade = 'C+';
      color = Colors.orange;
      icon = Icons.sentiment_dissatisfied;
    } else if (total >= 130) {
      grade = 'C';
      color = Colors.orange;
      icon = Icons.sentiment_dissatisfied;
    } else {
      grade = 'D';
      color = Colors.red;
      icon = Icons.sentiment_very_dissatisfied;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            grade,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentsTab(ThemeData theme, Color subjectColor) {
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
                    builder:
                        (context) => CreateAssessmentScreen(
                          subjectCode: widget.subject['code'],
                          subjectColor: subjectColor,
                        ),
                  ),
                ).then((_) => _fetchResults());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: subjectColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Announcement',
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
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              final assessment = assessments[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    assessment['title'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${assessment['type']}'),
                      Text('Date: ${assessment['date']}'),
                    ],
                  ),
                  trailing: Icon(
                    assessment['is_marked']
                        ? Icons.check_circle
                        : Icons.pending,
                    color:
                        assessment['is_marked'] ? Colors.green : Colors.orange,
                  ),
                  onTap: () {
                    if (assessment['is_marked']) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MarkedAssessmentsScreen(
                                subjectCode: widget.subject['code'],
                                subjectColor: subjectColor,
                              ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EnterMarksScreen(
                                assessmentId: assessment['id'],
                                assessmentTitle: assessment['title'],
                                totalMarks: assessment['total_marks'],
                                subjectColor: subjectColor,
                              ),
                        ),
                      ).then((_) => _fetchResults());
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
