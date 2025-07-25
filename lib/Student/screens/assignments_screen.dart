import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final String studentRfid;

  const AssignmentsScreen({
    super.key,
    required this.studentRfid,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  late ApiService _apiService;
  late Future<List<Assignment>> _assignmentsFuture;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _assignmentsFuture = _apiService.getAssignments(widget.studentRfid);
      await _assignmentsFuture;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load assignments. Please try again.';
        _isLoading = false;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY ASSIGNMENTS',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: TeacherColors.dangerAccent,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAssignments,
        backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
        color: TeacherColors.primaryAccent,
        child: FutureBuilder<List<Assignment>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final assignments = snapshot.data!;
              if (assignments.isEmpty) {
                return Center(
                  child: Container(
                    decoration: TeacherColors.glassDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No assignments found',
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                  ),
                );
              }

              final dueSoon = assignments
                  .where((a) =>
              a.dueDate.difference(DateTime.now()).inDays <= 3 &&
                  a.status != 'graded' &&
                  a.status != 'submitted')
                  .toList();

              final graded = assignments
                  .where((a) => a.status == 'graded')
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (dueSoon.isNotEmpty)
                    _buildSectionHeader('DUE SOON', dueSoon),
                  if (graded.isNotEmpty)
                    _buildSectionHeader('RECENTLY GRADED', graded),
                  _buildSectionHeader('ALL ASSIGNMENTS', assignments),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, List<Assignment> assignments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: TeacherTextStyles.sectionHeader,
          ),
        ),
        ...assignments.map((assignment) => _buildAssignmentCard(assignment)),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final subjectColor = _getSubjectColor(assignment.subjectName);
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToAssignmentDetail(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject header with colored tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: subjectColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  assignment.subjectName,
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: subjectColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: TeacherTextStyles.cardTitle,
                    ),
                  ),
                  if (assignment.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TeacherColors.dangerAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TeacherColors.dangerAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          color: TeacherColors.dangerAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      assignment.timeLeft,
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: assignment.dueDate.difference(DateTime.now()).inDays < 3
                            ? TeacherColors.warningAccent
                            : TeacherColors.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TeacherTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 12),

              // Status indicator
              if (isSubmitted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeacherColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TeacherColors.primaryAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            assignment.status == 'graded'
                                ? Icons.grade
                                : Icons.check_circle,
                            color: assignment.status == 'graded'
                                ? TeacherColors.warningAccent
                                : TeacherColors.successAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignment.status == 'graded'
                                ? 'GRADED (${assignment.grade}%)'
                                : 'SUBMITTED',
                            style: TeacherTextStyles.cardSubtitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: assignment.status == 'graded'
                                  ? TeacherColors.warningAccent
                                  : TeacherColors.successAccent,
                            ),
                          ),
                        ],
                      ),
                      if (assignment.teacherFeedback != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feedback: ${assignment.teacherFeedback}',
                          style: TeacherTextStyles.cardSubtitle,
                        ),
                      ],
                    ],
                  ),
                )
              else if (assignment.attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: TeacherColors.secondaryText,
                    ),
                    ...assignment.attachments.map(
                          (file) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TeacherColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TeacherColors.cardBorder.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          file.fileName,
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _navigateToAssignmentDetail(assignment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.primaryAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: TeacherColors.primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    isSubmitted ? 'VIEW DETAILS' : 'VIEW & SUBMIT',
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': TeacherColors.primaryAccent,
      'Physics': TeacherColors.secondaryAccent,
      'Chemistry': TeacherColors.infoAccent,
      'Biology': TeacherColors.successAccent,
      'English': TeacherColors.warningAccent,
      'History': TeacherColors.dangerAccent,
    };
    return colors[subject] ?? TeacherColors.primaryAccent;
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailScreen(
          assignment: assignment,
          studentRfid: widget.studentRfid,
          onSubmission: (file) => _handleSubmission(assignment, file),
          onStatusUpdate: (newStatus) => _updateAssignmentStatus(assignment, newStatus),
        ),
      ),
    );
  }

  Future<void> _handleSubmission(Assignment assignment, String file) async {
    try {
      final updatedAssignment = await _apiService.submitAssignment(
        assignmentId: assignment.id,
        fileName: 'submission_${assignment.id}.pdf',
        filePath: file,
        studentRfid: widget.studentRfid,
      );

      setState(() {
        _assignmentsFuture = _apiService.getAssignments(widget.studentRfid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assignment submitted successfully!',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.successAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit: ${e.toString()}',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _updateAssignmentStatus(Assignment assignment, String newStatus) async {
    try {
      setState(() {
        assignment.status = newStatus;
        if (newStatus == 'submitted') {
          assignment.submissionDate = DateTime.now();
        }
      });

      await _apiService.updateAssignmentStatus(
        assignmentId: assignment.id,
        status: newStatus,
      );

      _loadAssignments();
    } catch (e) {
      setState(() {
        assignment.status = assignment.status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: $e',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }
}