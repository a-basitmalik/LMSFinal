import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';

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
      // Replace with actual API call
      // final fetched = await ComplaintService.getComplaintsForSubject(widget.subjectId);
      // setState(() {
      //   complaints = fetched;
      //   isLoading = false;
      // });

      // Mock data
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        complaints = [
          {
            'id': '1',
            'student_name': 'John Doe',
            'student_rfid': '123',
            'title': 'Disruptive behavior',
            'description': 'Student was talking loudly during class',
            'created_at': '2023-05-15T10:30:00Z',
            'status': 'pending',
          },
          {
            'id': '2',
            'student_name': 'Jane Smith',
            'student_rfid': '456',
            'title': 'Late submission',
            'description': 'Student submitted assignment 3 days late',
            'created_at': '2023-05-10T14:15:00Z',
            'status': 'resolved',
          },
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load complaints';
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return Container(
          decoration: TeacherColors.glassDecoration(
            borderRadius: 12,
            borderColor: _getStatusColor(complaint['status']),
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
                        color: _getStatusColor(complaint['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(complaint['status']).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        complaint['status'].toString().toUpperCase(),
                        style: TeacherTextStyles.secondaryButton.copyWith(
                          color: _getStatusColor(complaint['status']),
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
    );
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
    // Implement your date formatting here
    return dateTime; // Return formatted date
  }
}