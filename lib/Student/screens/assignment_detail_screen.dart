import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import '../models/assignment_model.dart';
import '../utils/theme.dart';
import 'submit_assignment_screen.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;
  final Function(String) onSubmission;
  final Function(String) onStatusUpdate;
  final String studentRfid;

  const AssignmentDetailScreen({
    super.key,
    required this.studentRfid,
    required this.assignment,
    required this.onSubmission,
    required this.onStatusUpdate,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final assignment = widget.assignment;
    final subjectColor = _getSubjectColor(assignment.subject);
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assignment.title,
          style: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: subjectColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.defaultBorderRadius)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              subjectColor.withOpacity(0.05),
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: AppTheme.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and due date
              Row(
                children: [
                  Container(
                    padding: AppTheme.defaultPadding,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
                    ),
                    child: Text(
                      assignment.subject,
                      style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppTheme.defaultSpacing / 2),
                  Text(
                    'Due ${DateFormat('MMM d, y').format(assignment.dueDate)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: assignment.isOverdue ? AppColors.error : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.defaultSpacing),

              // Description
              Text(
                assignment.description,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTheme.defaultSpacing * 1.5),

              // Attachments
              if (assignment.attachments.isNotEmpty) ...[
                Text(
                  'Attachments:',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.defaultSpacing / 2),
                ...assignment.attachments.map(
                      (file) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.defaultSpacing / 2),
                    child: _buildAttachmentItem(file),
                  ),
                ),
                const SizedBox(height: AppTheme.defaultSpacing * 1.5),
              ],

              // Submission section
              if (!isSubmitted)
                _buildSubmissionForm(subjectColor)
              else
                _buildSubmissionStatus(assignment),

              // Warning if overdue
              if (assignment.isOverdue)
                _buildOverdueWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(Attachment file) {
    return InkWell(
      onTap: () => _openDocument(context, file.filePath),
      child: Container(
        padding: AppTheme.defaultPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        ),
        child: Row(
          children: [
            Icon(_getFileIcon(file.fileName), color: _getFileColor(file.fileName)),
            const SizedBox(width: AppTheme.defaultSpacing),
            Expanded(
              child: Text(
                file.fileName,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm(Color subjectColor) {
    return Column(
      children: [
        _buildFileSelector(),
        const SizedBox(height: AppTheme.defaultSpacing),
        _buildSubmitButton(subjectColor),
      ],
    );
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
        const SizedBox(height: AppTheme.defaultSpacing / 2),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: AppTheme.defaultPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.textSecondary),
                const SizedBox(width: AppTheme.defaultSpacing),
                Expanded(
                  child: Text(
                    _selectedFile?.path.split('/').last ?? 'No file selected',
                    style:  Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedFile != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textPrimary,
          ),
        )
            : const Icon(Icons.upload),
        label: Text(_isSubmitting ? 'SUBMITTING...' : 'SUBMIT ASSIGNMENT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: subjectColor,
          foregroundColor: AppColors.textPrimary,
          padding: AppTheme.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionStatus(Assignment assignment) {
    final isGraded = assignment.status == 'graded';

    return Container(
      padding: AppTheme.defaultPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGraded ? Icons.grade : Icons.check_circle,
                color: isGraded ? AppColors.warning : AppColors.success,
                size: 24,
              ),
              const SizedBox(width: AppTheme.defaultSpacing),
              Text(
                isGraded ? 'GRADED (${assignment.grade}%)' : 'SUBMITTED',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isGraded ? AppColors.warning : AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.defaultSpacing),
          Text(
            'Submitted on ${DateFormat('MMM d, y - h:mm a').format(assignment.submissionDate!)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.defaultSpacing / 2),
          _buildSubmittedFileItem(assignment.submissionFile!),
          if (assignment.teacherFeedback != null) ...[
            const SizedBox(height: AppTheme.defaultSpacing),
            Text(
              'Teacher Feedback:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.defaultSpacing / 2),
            Text(assignment.teacherFeedback!),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedFileItem(String filePath) {
    return InkWell(
      onTap: () => _openDocument(context, filePath),
      child: Container(
        padding: AppTheme.defaultPadding,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(filePath),
              color: _getFileColor(filePath),
            ),
            const SizedBox(width: AppTheme.defaultSpacing),
            Text(
              filePath.split('/').last,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueWarning() {
    return Container(
      padding: AppTheme.defaultPadding,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.error),
          const SizedBox(width: AppTheme.defaultSpacing),
          Expanded(
            child: Text(
              'This assignment is overdue. Late submissions may be penalized.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
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
        'student_rfid': widget.studentRfid, // Replace with actual RFID
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

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': AppColors.secondary,
      // 'Physics': AppColors.accentBlue,
      // 'Chemistry': AppColors.accentPink,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      // 'History': AppColors.accentAmber,
    };
    return colors[subject] ?? AppColors.primary;
  }

}