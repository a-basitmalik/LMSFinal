import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final Assignment assignment;

  const SubmitAssignmentScreen({super.key, required this.assignment});

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  String? _selectedFile;
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final subjectColor = _getSubjectColor(widget.assignment.subject);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit ${widget.assignment.title}',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: subjectColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient(subjectColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assignment info
              Card(
                elevation: 0,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignment.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Due ${DateFormat('MMM d, y').format(widget.assignment.dueDate)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: widget.assignment.isOverdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // File upload section
              Text(
                'Upload your work',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectFile,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.cloud_upload
                            : Icons.check_circle,
                        size: 48,
                        color: _selectedFile == null
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null
                            ? 'Tap to select file'
                            : 'File selected',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _selectedFile == null
                              ? AppColors.textSecondary
                              : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedFile!,
                          style: textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Supported formats: PDF, DOCX, PPTX, JPG, PNG',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Additional notes
              Text(
                'Additional notes (optional)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add any notes for your teacher...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: AppColors.disabledText,
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFile == null ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: subjectColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SUBMIT ASSIGNMENT',
                    style: textTheme.labelLarge?.copyWith(
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

  void _selectFile() {
    // In a real app, this would open a file picker
    setState(() {
      _selectedFile = 'my_assignment_${widget.assignment.id}.pdf';
    });
  }

  void _submitAssignment() {
    Navigator.pop(context, _selectedFile);
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': AppColors.secondary,
      'Physics': AppColors.info,
      'Chemistry': AppColors.facultyColor,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      'History': AppColors.resultsColor,
    };
    return colors[subject] ?? AppColors.primary;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}