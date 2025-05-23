import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EnterMarks.dart';

class MarkedAssessmentsScreen extends StatefulWidget {
  final String subjectCode;
  final Color subjectColor;

  const MarkedAssessmentsScreen({
    super.key,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  _MarkedAssessmentsScreenState createState() =>
      _MarkedAssessmentsScreenState();
}

class _MarkedAssessmentsScreenState extends State<MarkedAssessmentsScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  final String baseUrl = 'http://your-flask-server.com/api';
  final String assessmentsEndpoint = '/assessments';

  @override
  void initState() {
    super.initState();
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$assessmentsEndpoint?subject=${widget.subjectCode}&marked=true',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _assessments = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load assessments');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _navigateToEditMarks(String assessmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EnterMarksScreen(
              assessmentId: assessmentId,
              assessmentTitle:
                  _assessments.firstWhere(
                    (a) => a['id'] == assessmentId,
                  )['title'],
              totalMarks:
                  _assessments.firstWhere(
                    (a) => a['id'] == assessmentId,
                  )['total_marks'],
              subjectColor: widget.subjectColor,
            ),
      ),
    ).then((_) => _fetchAssessments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Marked Assessments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _assessments.isEmpty
              ? Center(
                child: Text(
                  'No marked assessments found',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _assessments.length,
                itemBuilder: (context, index) {
                  final assessment = _assessments[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateToEditMarks(assessment['id']),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  assessment['title'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    assessment['type'].toString().toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: widget.subjectColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Total Marks: ${assessment['total_marks']}',
                              style: GoogleFonts.poppins(),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${assessment['date']}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => _navigateToEditMarks(
                                        assessment['id'],
                                      ),
                                  child: Text(
                                    'Edit Marks',
                                    style: GoogleFonts.poppins(
                                      color: widget.subjectColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
