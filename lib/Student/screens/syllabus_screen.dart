import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/theme.dart';

class SyllabusScreen extends StatelessWidget {
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      code: 'MATH101',
      icon: Icons.calculate,
      color: AppColors.secondary,
      pdfPath: 'assets/pdfs/math_syllabus.pdf',
      description: '',
    ),
    Subject(
      name: 'Physics',
      code: 'PHYS101',
      icon: Icons.science,
      color: AppColors.info,
      pdfPath: 'assets/pdfs/physics_syllabus.pdf',
      description: '',
    ),
    Subject(
      name: 'Chemistry',
      code: 'CHEM101',
      icon: Icons.science_outlined,
      color: AppColors.facultyColor,
      pdfPath: 'assets/pdfs/chemistry_syllabus.pdf',
      description: '',
    ),
    Subject(
      name: 'Biology',
      code: 'BIO101',
      icon: Icons.eco,
      color: AppColors.success,
      pdfPath: 'assets/pdfs/biology_syllabus.pdf',
      description: '',
    ),
    Subject(
      name: 'Computer Science',
      code: 'CS101',
      icon: Icons.computer,
      color: AppColors.primary,
      pdfPath: 'assets/pdfs/cs_syllabus.pdf',
      description: '',
    ),
    Subject(
      name: 'English',
      code: 'ENG101',
      icon: Icons.menu_book,
      color: AppColors.resultsColor,
      pdfPath: 'assets/pdfs/english_syllabus.pdf',
      description: '',
    ),
  ];

  SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Syllabus & Schedule',
          style: textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionHeader(
                context,
                'Available Subjects',
                actionText: 'Download All',
                onAction: () => _downloadAllPdfs(context),
              ),
              _buildSubjectGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context,
      String title, {
        String? actionText,
        VoidCallback? onAction,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            return _buildSubjectCard(context, subjects[index]);
          },
        );
      },
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPdfViewer(context, subject),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with color
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  subject.icon,
                  size: 24,
                  color: subject.color,
                ),
              ),
              const SizedBox(height: 12),

              // Subject name
              Text(
                subject.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // Description
              if (subject.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subject.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Code
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subject.code,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdfViewer(BuildContext context, Subject subject) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${subject.name} Syllabus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to view or download the syllabus?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            pdfPath: subject.pdfPath,
                            subjectName: subject.name,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadPdf(context, subject);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Download',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, Subject subject) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${subject.name}_syllabus.pdf';

      final data = await rootBundle.load(subject.pdfPath);
      final bytes = data.buffer.asUint8List();
      await File(filePath).writeAsBytes(bytes);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${subject.name} syllabus downloaded successfully!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _downloadAllPdfs(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();

      for (var subject in subjects) {
        final filePath = '${directory.path}/${subject.name}_syllabus.pdf';
        final data = await rootBundle.load(subject.pdfPath);
        final bytes = data.buffer.asUint8List();
        await File(filePath).writeAsBytes(bytes);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All syllabi downloaded successfully!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download all: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  final String subjectName;

  const PdfViewerScreen({
    required this.pdfPath,
    required this.subjectName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$subjectName Syllabus',
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.download,
              color: AppColors.primary,
            ),
            onPressed: () {
              // Implement download functionality here
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 100,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              'PDF Viewer Placeholder',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              'Path: $pdfPath',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class Subject {
  final String name;
  final String code;
  final IconData icon;
  final Color color;
  final String pdfPath;
  final String description;

  Subject({
    required this.name,
    required this.code,
    required this.icon,
    required this.color,
    required this.pdfPath,
    required this.description,
  });
}