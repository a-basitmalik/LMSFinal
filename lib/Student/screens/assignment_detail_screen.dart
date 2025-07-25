import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import '../../Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';

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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final assignment = widget.assignment;
    final subjectColor = _getSubjectColor(assignment.subjectName);
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: subjectColor.withOpacity(0.1),
        elevation: 0,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
        title: Text(
          assignment.title,
          style: TeacherTextStyles.cardTitle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject and due date
            Row(
              children: [
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
                const Spacer(),
                Icon(Icons.calendar_today,
                    size: 16,
                    color: TeacherColors.secondaryText
                ),
                const SizedBox(width: 8),
                Text(
                  'Due ${DateFormat('MMM d, y').format(assignment.dueDate)}',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: assignment.isOverdue
                        ? TeacherColors.dangerAccent
                        : TeacherColors.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              assignment.description,
              style: TeacherTextStyles.cardSubtitle,
            ),
            const SizedBox(height: 24),

            // Attachments
            if (assignment.attachments.isNotEmpty) ...[
              Text(
                'Attachments:',
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              ...assignment.attachments.map(
                    (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAttachmentItem(file),
                ),
              ),
              const SizedBox(height: 24),
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
    );
  }

  Widget _buildAttachmentItem(Attachment file) {
    return InkWell(
      onTap: () => _openDocument(context, file.filePath),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TeacherColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TeacherColors.cardBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(file.fileName),
              color: _getFileColor(file.fileName),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.fileName,
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  decoration: TextDecoration.underline,
                ),
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
        const SizedBox(height: 16),
        _buildSubmitButton(subjectColor),
      ],
    );
  }

  Widget _buildFileSelector() {
    final textStyles = context.teacherTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select file to submit:',
          style: TeacherTextStyles.sectionHeader,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TeacherColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TeacherColors.cardBorder.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  color: TeacherColors.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFile?.path.split('/').last ?? 'No file selected',
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: _selectedFile != null
                          ? TeacherColors.primaryText
                          : TeacherColors.secondaryText,
                    ),
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: TeacherColors.secondaryText,
                      size: 20,
                    ),
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
    final textStyles = context.teacherTextStyles;

    return Center(
      child: ElevatedButton(
        onPressed: _isSubmitting || _selectedFile == null ? null : _submitAssignment,
        style: ElevatedButton.styleFrom(
          backgroundColor: subjectColor.withOpacity(0.1),
          foregroundColor: subjectColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: subjectColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSubmitting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                ),
              )
            else
              Icon(
                Icons.upload,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              _isSubmitting ? 'SUBMITTING...' : 'SUBMIT ASSIGNMENT',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatus(Assignment assignment) {
    final textStyles = context.teacherTextStyles;
    final isGraded = assignment.status == 'graded';
    final statusColor = isGraded ? TeacherColors.warningAccent : TeacherColors.successAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGraded ? Icons.grade : Icons.check_circle,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isGraded ? 'GRADED (${assignment.grade}%)' : 'SUBMITTED',
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Submitted on ${DateFormat('MMM d, y - h:mm a').format(assignment.submissionDate!)}',
            style: TeacherTextStyles.cardSubtitle,
          ),
          const SizedBox(height: 8),
          _buildSubmittedFileItem(assignment.submissionFile!),
          if (assignment.teacherFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              'Teacher Feedback:',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              assignment.teacherFeedback!,
              style: TeacherTextStyles.cardSubtitle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedFileItem(String filePath) {
    return InkWell(
      onTap: () => _openDocument(context, filePath),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TeacherColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TeacherColors.cardBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(filePath),
              color: _getFileColor(filePath),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              filePath.split('/').last,
              style: TeacherTextStyles.cardSubtitle.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueWarning() {
    final textStyles = context.teacherTextStyles;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeacherColors.dangerAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TeacherColors.dangerAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: TeacherColors.dangerAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This assignment is overdue. Late submissions may be penalized.',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: TeacherColors.dangerAccent,
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
        SnackBar(
          content: Text(
            'Failed to open document: ${e.toString()}',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
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
          SnackBar(
            content: Text(
              'Downloading PDF...',
              style: TeacherTextStyles.cardSubtitle,
            ),
            backgroundColor: TeacherColors.primaryAccent,
          ),
        );

        await Dio().download(pdfUrl, filePath);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: TeacherColors.primaryBackground,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: TeacherColors.primaryText),
                title: Text(
                  'PDF Viewer',
                  style: TeacherTextStyles.cardTitle,
                ),
              ),
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
            backgroundColor: TeacherColors.primaryBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: TeacherColors.primaryText),
              title: Text(
                'PDF Viewer',
                style: TeacherTextStyles.cardTitle,
              ),
            ),
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
    if (fileName.endsWith('.pdf')) return TeacherColors.dangerAccent;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return TeacherColors.infoAccent;
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) return TeacherColors.successAccent;
    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) return TeacherColors.warningAccent;
    return TeacherColors.secondaryText;
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
        SnackBar(
          content: Text(
            'Error selecting file: $e',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFile == null) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmission(_selectedFile!.path);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting assignment: $e',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
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
}