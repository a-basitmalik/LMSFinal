import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';
import '../utils/app_design_system.dart';
import '../utils/theme.dart';
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
    return Scaffold(
      appBar: AppDesignSystem.appBar(context, 'My Assignments'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.05), AppColors.background],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : RefreshIndicator(
          onRefresh: _loadAssignments,
          child: FutureBuilder<List<Assignment>>(
            future: _assignmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final assignments = snapshot.data!;
                if (assignments.isEmpty) {
                  return const Center(
                    child: Text('No assignments found.'),
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
                      _buildSectionHeader('Due Soon', dueSoon),
                    if (graded.isNotEmpty)
                      _buildSectionHeader('Recently Graded', graded),
                    _buildSectionHeader('All Assignments', assignments),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        ...assignments.map((assignment) => _buildAssignmentCard(assignment)),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final subjectColor = _getSubjectColor(assignment.subjectName);
    final isSubmitted =
        assignment.status == 'submitted' || assignment.status == 'graded';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToAssignmentDetail(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject header with colored tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assignment.subjectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (assignment.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      assignment.timeLeft,
                      style: TextStyle(
                        color: assignment.dueDate
                            .difference(DateTime.now())
                            .inDays <
                            3
                            ? AppColors.warning
                            : AppColors.textSecondary,
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Status indicator
              if (isSubmitted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
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
                                ? AppColors.accentAmber
                                : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignment.status == 'graded'
                                ? 'GRADED (${assignment.grade}%)'
                                : 'SUBMITTED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: assignment.status == 'graded'
                                  ? AppColors.accentAmber
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (assignment.teacherFeedback != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feedback: ${assignment.teacherFeedback}',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                      color: AppColors.textSecondary,
                    ),
                    ...assignment.attachments.map(
                          (file) => Chip(
                        label: Text(file.fileName, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToAssignmentDetail(assignment),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    isSubmitted ? 'VIEW DETAILS' : 'VIEW & SUBMIT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
      'Mathematics': AppColors.secondary,
      'Physics': AppColors.accentBlue,
      'Chemistry': AppColors.accentPink,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      'History': AppColors.accentAmber,
    };
    return colors[subject] ?? AppColors.primary;
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailScreen(
          assignment: assignment,
          studentRfid: widget.studentRfid,
          onSubmission: (file) => _handleSubmission(assignment, file),
          onStatusUpdate: (newStatus) => _updateAssignmentStatus(assignment, newStatus), StudentRfid: '',
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
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateAssignmentStatus(Assignment assignment, String newStatus) async {
    try {
      // 1. Update locally in your state
      setState(() {
        assignment.status = newStatus;
        if (newStatus == 'submitted') {
          assignment.submissionDate = DateTime.now();
        }
      });

      // 2. Call API to update status on server
      await _apiService.updateAssignmentStatus(
        assignmentId: assignment.id,
        status: newStatus,
      );

      // 3. Refresh assignments list
      _loadAssignments();
    } catch (e) {
      // Revert local change if API call fails
      setState(() {
        assignment.status = assignment.status; // Revert to previous status
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
}