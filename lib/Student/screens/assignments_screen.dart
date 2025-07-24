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
          gradient: AppColors.accentGradient(AppColors.primary),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadAssignments,
          child: FutureBuilder<List<Assignment>>(
            future: _assignmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final assignments = snapshot.data!;
                if (assignments.isEmpty) {
                  return Center(
                    child: Text(
                      'No assignments found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final dueSoon = assignments
                    .where((a) =>
                a.dueDate.difference(DateTime.now()).inDays <=
                    3 &&
                    a.status != 'graded' &&
                    a.status != 'submitted')
                    .toList();

                final graded = assignments
                    .where((a) => a.status == 'graded')
                    .toList();

                return ListView(
                  padding: AppTheme.defaultPadding,
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
            style: Theme.of(context).textTheme.sectionHeader,
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
      margin: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: () => _navigateToAssignmentDetail(assignment),
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject header with colored tag
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assignment.subjectName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.defaultSpacing),

              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.cardTitle,
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
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      assignment.timeLeft,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              const SizedBox(height: AppTheme.defaultSpacing),

              // Status indicator
              if (isSubmitted)
                Container(
                  padding: AppTheme.defaultPadding,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(AppTheme.defaultBorderRadius),
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
                                ? AppColors.warning
                                : AppColors.success,
                            size: AppTheme.defaultIconSize,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignment.status == 'graded'
                                ? 'GRADED (${assignment.grade}%)'
                                : 'SUBMITTED',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: assignment.status == 'graded'
                                  ? AppColors.warning
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
                        label: Text(
                          file.fileName,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        backgroundColor: AppColors.surface,
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
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      'Mathematics': AppColors.secondary,
      'Physics': AppColors.info,
      'Chemistry': AppColors.primaryLight,
      'Biology': AppColors.success,
      'English': AppColors.primary,
      'History': AppColors.warning,
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
          onStatusUpdate: (newStatus) =>
              _updateAssignmentStatus(assignment, newStatus),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateAssignmentStatus(
      Assignment assignment, String newStatus) async {
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
        SnackBar(
          content: Text(
            'Failed to update status: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}