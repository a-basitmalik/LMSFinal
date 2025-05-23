// lib/screens/assignment_detail_screen.dart
import 'dart:io';

import 'package:newapp/Student/models/student_model.dart';
import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../utils/theme.dart';
import 'submit_assignment_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;
  final Function(String) onSubmission;
  final Function(String) onStatusUpdate;
  final String StudentRfid;

  const AssignmentDetailScreen({
    super.key,
    required this.StudentRfid,
    required this.assignment,
    required this.onSubmission,
    required this.onStatusUpdate, required String studentRfid,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool _isSubmitting = false;
  File? _selectedFile;
  late final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final subjectColor = _getSubjectColor(assignment.subject);
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment.title),
        backgroundColor: subjectColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [subjectColor.withOpacity(0.05), AppColors.background],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and due date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      assignment.subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${DateFormat('MMM d, y').format(assignment.dueDate)}',
                    style: TextStyle(
                      color: assignment.isOverdue ? AppColors.error : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                assignment.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Attachments
              if (assignment.attachments.isNotEmpty) ...[
                Text(
                  'Attachments:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...assignment.attachments.map(
                      (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _openDocument(context, file.filePath),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(_getFileIcon(file.fileName), color: _getFileColor(file.fileName)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.fileName,
                                style: const TextStyle(decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submission section
              if (!isSubmitted) ...[
                _buildFileSelector(),
                const SizedBox(height: 16),
                _buildSubmitButton(subjectColor),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            assignment.status == 'graded' ? Icons.grade : Icons.check_circle,
                            color: assignment.status == 'graded' ? AppColors.accentAmber : AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            assignment.status == 'graded'
                                ? 'GRADED (${assignment.grade}%)'
                                : 'SUBMITTED',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: assignment.status == 'graded'
                                  ? AppColors.accentAmber
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Submitted on ${DateFormat('MMM d, y - h:mm a').format(assignment.submissionDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file),
                            const SizedBox(width: 8),
                            Text(
                              assignment.submissionFile!,
                              style: const TextStyle(decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                      if (assignment.teacherFeedback != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Teacher Feedback:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(assignment.teacherFeedback!),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Warning if overdue
              if (assignment.isOverdue)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This assignment is overdue. Late submissions may be penalized.',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    try {
      if (url.endsWith('.pdf')) {
        await _openPdfInApp(context, url);
      } else {
        await _openInExternalApp(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open document: ${e.toString()}')),
      );
    }
  }

  Future<void> _openPdfInApp(BuildContext context, String pdfUrl) async {
    if (pdfUrl.startsWith('http')) {
      // For network PDFs
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading PDF...')),
        );

        await Dio().download(pdfUrl, filePath);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('PDF Viewer')),
              body: PDFView(
                filePath: filePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
              ),
            ),
          ),
        );
      } catch (e) {
        throw Exception('Failed to download PDF: $e');
      }
    } else {
      // For local PDF files
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('PDF Viewer')),
            body: PDFView(
              filePath: pdfUrl,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openInExternalApp(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return Icons.description;
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) return Icons.table_chart;
    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) return Icons.slideshow;
    if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileName) {
    if (fileName.endsWith('.pdf')) return Colors.red;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return Colors.blue;
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) return Colors.green;
    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) return Colors.orange;
    return Colors.grey;
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


  Widget _buildFileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select file to submit:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFile?.path.split('/').last ?? 'No file selected',
                    style: TextStyle(
                      color: _selectedFile != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color subjectColor) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _isSubmitting || _selectedFile == null ? null : _submitAssignment,
        icon: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.upload),
        label: Text(_isSubmitting ? 'SUBMITTING...' : 'SUBMIT ASSIGNMENT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: subjectColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.assignment.status == 'graded'
                    ? Icons.grade
                    : Icons.check_circle,
                color: widget.assignment.status == 'graded'
                    ? AppColors.accentAmber
                    : AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.assignment.status == 'graded'
                    ? 'GRADED (${widget.assignment.grade}%)'
                    : 'SUBMITTED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.assignment.status == 'graded'
                      ? AppColors.accentAmber
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Submitted on ${DateFormat('MMM d, y - h:mm a').format(widget.assignment.submissionDate!)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openDocument(context, widget.assignment.submissionFile!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(widget.assignment.submissionFile!),
                    color: _getFileColor(widget.assignment.submissionFile!),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.assignment.submissionFile!.split('/').last,
                    style: const TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
          if (widget.assignment.teacherFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              'Teacher Feedback:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.assignment.teacherFeedback!),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFile == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Create multipart request
      var formData = FormData.fromMap({
        'student_rfid': widget.StudentRfid, // Replace with actual RFID
        'assignment_id': widget.assignment.id,
        'file_name': _selectedFile!.path.split('/').last,
        'file': await MultipartFile.fromFile(
          _selectedFile!.path,
          filename: _selectedFile!.path.split('/').last,
        ),
      });

      // Send request
      final response = await Dio().post(
        'http://193.203.162.232:5050/assignments/submit',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201) {
        widget.onStatusUpdate('submitted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

}