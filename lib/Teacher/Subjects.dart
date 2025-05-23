import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SubjectDetails.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  _SubjectsScreenState createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  // Static data - will be replaced by API calls
  List<Map<String, dynamic>> subjects = [
    {
      'name': 'Mathematics',
      'code': 'MATH101',
      'color': Color(0xFF4361EE),
      'icon': Icons.calculate,
      'students': 45,
      'classes': ['10-A', '10-B'],
      'schedule': 'Mon/Wed 8:00-9:30',
    },
    {
      'name': 'Physics',
      'code': 'PHYS202',
      'color': Color(0xFF7209B7),
      'icon': Icons.science,
      'students': 32,
      'classes': ['11-A'],
      'schedule': 'Tue/Thu 10:00-11:30',
    },
    {
      'name': 'Computer Science',
      'code': 'COMP110',
      'color': Color(0xFF4CC9F0),
      'icon': Icons.computer,
      'students': 28,
      'classes': ['12-A', '12-B'],
      'schedule': 'Fri 1:00-3:00',
    },
    {
      'name': 'Chemistry',
      'code': 'CHEM201',
      'color': Color(0xFFF72585),
      'icon': Icons.science_outlined,
      'students': 36,
      'classes': ['11-B'],
      'schedule': 'Mon/Wed 2:00-3:30',
    },
    {
      'name': 'Biology',
      'code': 'BIO101',
      'color': Color(0xFF4895EF),
      'icon': Icons.eco,
      'students': 42,
      'classes': ['10-C'],
      'schedule': 'Tue/Thu 8:00-9:30',
    },
  ];

  bool isLoading = false;
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://your-flask-server.com/api';
  final String subjectsEndpoint = '/teacher/subjects';

  @override
  void initState() {
    super.initState();
    // Uncomment when backend is ready
    // _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl$subjectsEndpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subjects =
              data
                  .map(
                    (item) => {
                      'name': item['name'],
                      'code': item['code'],
                      'color': _parseColor(item['color']),
                      'icon': _parseIcon(item['icon']),
                      'students': item['students_count'],
                      'classes': List<String>.from(item['classes']),
                      'schedule': item['schedule'],
                    },
                  )
                  .toList();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load subjects (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Color(0xFF4361EE); // Default color
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science;
      case 'computer':
        return Icons.computer;
      case 'calculate':
        return Icons.calculate;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.school;
    }
  }

  void _navigateToSubjectDetail(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDashboardScreen(subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Subjects',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSubjects,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSubjects,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(context),
                    SizedBox(height: 24),

                    // Subjects List
                    _buildSubjectsList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final totalSubjects = subjects.length;
    final int totalStudents = subjects.fold<int>(
      0,
      (sum, subject) => sum + (subject['students'] as int),
    );
    final int totalClasses = subjects.fold<int>(
      0,
      (sum, subject) => sum + (subject['classes'] as List).length,
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(Icons.school, '$totalSubjects', 'Subjects'),
          _buildSummaryItem(Icons.people, '$totalStudents', 'Students'),
          _buildSummaryItem(Icons.class_, '$totalClasses', 'Classes'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToSubjectDetail(subject),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: subject['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(subject['icon'], color: subject['color']),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          subject['code'],
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: subject['color'].withOpacity(0.1),
                    label: Text(
                      '${subject['students']} students',
                      style: GoogleFonts.poppins(
                        color: subject['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    subject['schedule'],
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.class_, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    subject['classes'].join(', '),
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.7, // Replace with actual progress from API
                backgroundColor: subject['color'].withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(subject['color']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
