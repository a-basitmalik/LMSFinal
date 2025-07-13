import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SubjectDetails.dart';

class SubjectsScreen extends StatefulWidget {
  final String teacherId;

  const SubjectsScreen({super.key, required this.teacherId});

  @override
  _SubjectsScreenState createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Map<String, dynamic>> subjects = [];
  bool isLoading = false;
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://192.168.18.185:5050/Teacher/api';

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.teacherId}/subjects'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subjects = data.map((item) {
            return {
              'subject_id': item['subject_id'] ?? 'NA',
              'name': item['subject_name'] ?? 'NA',
              'code': item['subject_code'] ?? 'NA',
              'color': _getColorForSubject(item['subject_id'] ?? 0),
              'icon': _getIconForSubject(item['subject_name'] ?? ''),
              'students': item['student_count'] ?? 0,
              'classes': _parseClasses(item['classes'] ?? ''),
              'schedule': _parseSchedule(item['schedule'] ?? []),
              'year': item['year'] ?? 'NA',
              'room': item['room'] ?? 'NA',
            };
          }).toList();
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

  Color _getColorForSubject(int subjectId) {
    final colors = [
      Color(0xFF4361EE),
      Color(0xFF7209B7),
      Color(0xFF4CC9F0),
      Color(0xFFF72585),
      Color(0xFF4895EF),
    ];
    return colors[subjectId % colors.length];
  }

  IconData _getIconForSubject(String subjectName) {
    if (subjectName.toLowerCase().contains('math')) {
      return Icons.calculate;
    } else if (subjectName.toLowerCase().contains('physics')) {
      return Icons.science;
    } else if (subjectName.toLowerCase().contains('computer')) {
      return Icons.computer;
    } else if (subjectName.toLowerCase().contains('chemistry')) {
      return Icons.science_outlined;
    } else if (subjectName.toLowerCase().contains('biology')) {
      return Icons.eco;
    } else {
      return Icons.school;
    }
  }

  List<String> _parseClasses(dynamic classesData) {
    if (classesData is String) {
      return [classesData];
    } else if (classesData is List) {
      return List<String>.from(classesData);
    }
    return ['NA'];
  }

  String _parseSchedule(dynamic scheduleData) {
    if (scheduleData is String) {
      return scheduleData;
    } else if (scheduleData is List && scheduleData.isNotEmpty) {
      return scheduleData.join(', ');
    }
    return 'Schedule not available';
  }

  void _navigateToSubjectDetail(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDashboardScreen(subject: subject,teacherId: widget.teacherId,),
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
      body: isLoading
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
          : subjects.isEmpty
          ? Center(
        child: Text(
          'No subjects assigned',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
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
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Grade ${subject['year']}',
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