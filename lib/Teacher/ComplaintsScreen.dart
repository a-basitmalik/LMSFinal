import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';

class ComplaintsScreen extends StatefulWidget {
  final int subjectId;

  const ComplaintsScreen({super.key, required this.subjectId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/student/api/subject/${widget.subjectId}/complaints'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          complaints = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load complaints: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load complaints: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Student Complaints',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddComplaintDialog(),
        child: const Icon(Icons.add),
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
              onPressed: _fetchComplaints,
              child: Text('Retry', style: TeacherTextStyles.primaryButton),
            ),
          ],
        ),
      );
    }

    if (complaints.isEmpty) {
      return Center(
        child: Text(
          'No complaints yet',
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: TeacherColors.secondaryText,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: complaints.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return Container(
            decoration: TeacherColors.glassDecoration(
              borderRadius: 12,
              borderColor: _getStatusColor(complaint['status'] ?? 'pending'),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          complaint['title'],
                          style: TeacherTextStyles.assignmentTitle.copyWith(
                            color: TeacherColors.primaryText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(complaint['status'] ?? 'pending').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(complaint['status'] ?? 'pending').withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          (complaint['status'] ?? 'pending').toString().toUpperCase(),
                          style: TeacherTextStyles.secondaryButton.copyWith(
                            color: _getStatusColor(complaint['status'] ?? 'pending'),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${complaint['student_name']} (${complaint['student_rfid']})',
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    complaint['description'],
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      fontSize: 15,
                      color: TeacherColors.primaryText.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: TeacherColors.secondaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _formatDateTime(complaint['created_at']),
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          color: TeacherColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddComplaintDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController rfidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Complaint', style: TeacherTextStyles.sectionHeader),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rfidController,
                decoration: InputDecoration(
                  labelText: 'Student RFID',
                  hintText: 'Enter student RFID',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter complaint title',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter complaint details',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _submitComplaint(
                    rfidController.text,
                    titleController.text,
                    descriptionController.text,
                    widget.subjectId.toString(),
                  );
                  Navigator.pop(context);
                  _fetchComplaints(); // Refresh the list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitComplaint(
      String rfid,
      String title,
      String description,
      String subjectId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('http://your-server-address/student/complaints/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rfid': rfid,
          'title': title,
          'description': description,
          'complaint_by': 'teacher',
          'subject_id': subjectId,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to submit complaint');
      }
    } catch (e) {
      throw Exception('Failed to submit complaint: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TeacherColors.warningAccent;
      case 'resolved':
        return TeacherColors.successAccent;
      default:
        return TeacherColors.secondaryText;
    }
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