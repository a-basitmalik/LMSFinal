import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';

class CallHistoryScreen extends StatefulWidget {
  final int subjectId;

  const CallHistoryScreen({super.key, required this.subjectId});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> callLogs = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, bool> expandedStudents = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjectStudents();
  }

  Future<void> _fetchSubjectStudents() async {
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/student/api/subject/${widget.subjectId}/students'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load students: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCallLogs(String rfid) async {
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/student/call_logs?rfid=$rfid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          callLogs = List<Map<String, dynamic>>.from(data['call_logs']);
        });
      } else {
        throw Exception('Failed to load call logs: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load call logs: ${e.toString()}')),
      );
    }
  }

  Future<void> _addCallLog(String rfid) async {
    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/student/call_logs/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rfid': rfid,
          'caller_type': 'teacher',
          'subject_id': widget.subjectId,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to log call');
      }
    } catch (e) {
      print('Error logging call: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  void _toggleStudentExpansion(String rfid) {
    setState(() {
      expandedStudents[rfid] = !(expandedStudents[rfid] ?? false);
      if (expandedStudents[rfid] == true) {
        _fetchCallLogs(rfid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Call History',
          style: TeacherTextStyles.sectionHeader.copyWith(
            fontSize: 20,
            color: TeacherColors.primaryText,
          ),
        ),
        backgroundColor: TeacherColors.secondaryBackground,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage, style: TextStyle(color: TeacherColors.dangerAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubjectStudents,
              child: Text('Retry', style: TeacherTextStyles.primaryButton),
            ),
          ],
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students in this subject',
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: TeacherColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final isExpanded = expandedStudents[student['rfid']] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: TeacherColors.glassDecoration(
            borderRadius: 16,
            borderColor: TeacherColors.infoAccent.withOpacity(0.3), // Matching announcement console
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TeacherColors.studentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: TeacherColors.studentColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['student_name'] ?? 'Unknown Student',
                            style: TeacherTextStyles.assignmentTitle,
                          ),
                          Text(
                            'RFID: ${student['rfid']}',
                            style: TeacherTextStyles.cardSubtitle,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.phone, color: TeacherColors.infoAccent),
                          onPressed: () async {
                            if (student['phone_number'] != null) {
                              await _addCallLog(student['rfid']);
                              await _makePhoneCall(student['phone_number']);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('No phone number available')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: TeacherColors.secondaryText,
                          ),
                          onPressed: () => _toggleStudentExpansion(student['rfid']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildCallLogs(student['rfid']),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallLogs(String rfid) {
    if (callLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No call history for this student',
          style: TeacherTextStyles.cardSubtitle,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: TeacherColors.infoAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TeacherColors.infoAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call History:',
            style: TeacherTextStyles.cardSubtitle.copyWith(
              fontWeight: FontWeight.bold,
              color: TeacherColors.infoAccent,
            ),
          ),
          const SizedBox(height: 8),
          ...callLogs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.phone, size: 16, color: TeacherColors.infoAccent),
                const SizedBox(width: 8),
                Text(
                  'Called by ${log['caller_type']}',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.primaryText.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(log['created_at']),
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.secondaryText,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}