import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class DownloadReportsScreen extends StatefulWidget {
  final int campusID;
  final String campusName;
  final int initialTab;

  const DownloadReportsScreen({
    Key? key,
    required this.campusID,
    required this.campusName,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  _DownloadReportsScreenState createState() => _DownloadReportsScreenState();
}

class _DownloadReportsScreenState extends State<DownloadReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isLoadingSubjects = false;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  final TextEditingController _yearController = TextEditingController();
  String? _selectedAssessmentType;
  final List<String> _assessmentTypes = [
    'Monthly', 'Send Up', 'Mocks', 'Other', 'Test Session',
    'Weekly', 'Half Book', 'Full Book',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex: widget.initialTab
    );
    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final uri = Uri.http(
        '193.203.162.232:5050',
        '/ReportDownload/subjects',
        {'campusid': widget.campusID.toString()},
      );
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as List<dynamic>;
        final subjects = raw.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
        setState(() => _subjects = subjects);
      } else {
        _showToast('Error ${resp.statusCode}: ${resp.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  // Keep all your existing report generation methods (_generateSubjectReport, etc.)
  // They remain exactly the same as in your original code

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with Tabs
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueAccent.withOpacity(0.2),
                    Colors.cyanAccent.withOpacity(0.2),
                  ],
                ),
              ),
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      '${widget.campusName} Reports',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.cyanAccent,
                    labelColor: Colors.cyanAccent,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Subject'),
                      Tab(text: 'Assessment'),
                      Tab(text: 'Monthly + Quizzes'),
                      Tab(text: 'All Subjects'),
                    ],
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubjectReportTab(),
                  _buildAssessmentReportTab(),
                  _buildMonthlyWithQuizzesTab(),
                  _buildAllSubjectsReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subject Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          _buildYearField(),
          const SizedBox(height: 24),
          _buildGenerateButton(
            'Generate Subject Report',
            _generateSubjectReport,
          ),
          const SizedBox(height: 20),
          Text(
            'Includes all assessment types for the selected subject with quiz data',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assessment Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          _buildYearField(),
          const SizedBox(height: 16),
          _buildAssessmentTypeDropdown(),
          const SizedBox(height: 24),
          _buildGenerateButton(
            'Generate Assessment Report',
            _generateAssessmentReport,
          ),
          const SizedBox(height: 20),
          Text(
            'Includes all assessments of selected type for the specified subject',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyWithQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Monthly with Quizzes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildYearField(),
          const SizedBox(height: 24),
          _buildGenerateButton(
            'Generate Monthly with Quizzes',
            _generateMonthlyWithQuizzesReport,
          ),
          const SizedBox(height: 20),
          Text(
            'Includes all monthly assessments with quiz data for all subjects',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSubjectsReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'All Subjects Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildYearField(),
          const SizedBox(height: 16),
          _buildAssessmentTypeDropdown(),
          const SizedBox(height: 24),
          _buildGenerateButton(
            'Generate All Subjects Report',
            _generateAllSubjectsReport,
          ),
          const SizedBox(height: 20),
          Text(
            'Includes all assessments of selected type for all subjects',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<Subject>(
          value: _selectedSubject,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Subject',
            labelStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.grey[900],
          hint: _isLoadingSubjects
              ? const Text('Loading subjects...', style: TextStyle(color: Colors.white70))
              : const Text('Select a subject', style: TextStyle(color: Colors.white70)),
          items: _subjects.map((s) {
            return DropdownMenuItem<Subject>(
              value: s,
              child: Text('${s.name} (ID: ${s.id})', style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (newSubj) => setState(() => _selectedSubject = newSubj),
          validator: (v) => v == null ? 'Please select a subject' : null,
        ),
      ),
    );
  }

  Widget _buildYearField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: TextFormField(
        controller: _yearController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Year',
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildAssessmentTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: _selectedAssessmentType,
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.grey[900],
          decoration: const InputDecoration(
            labelText: 'Assessment Type',
            labelStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          items: _assessmentTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedAssessmentType = newValue),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.8),
            Colors.cyanAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Include all your report generation methods here

  Future<void> _generateSubjectReport() async {
    if (_selectedSubject == null || _yearController.text.isEmpty) {
      _showToast('Please select a subject and year');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resp = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/subject-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'subjectid': _selectedSubject!.id,
          'year': _yearController.text.trim(),
        }),
      );

      if (resp.statusCode == 200) {
        final fileName = 'subject_${_selectedSubject!.id}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([resp.bodyBytes]);
          final url  = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final dir =
              await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final path = '${dir.path}/$fileName';
          File(path).writeAsBytesSync(resp.bodyBytes);
          await OpenFile.open(path);
          _showToast('Saved to $path');
        }
      } else {
        _showToast('Error: ${resp.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _generateAssessmentReport() async {
    if (_selectedSubject == null ||
        _yearController.text.isEmpty ||
        _selectedAssessmentType == null) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/assessment-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'subjectid': _selectedSubject!.id,
          'year': _yearController.text,
          'assessment_type': _selectedAssessmentType,
        }),
      );

      if (response.statusCode == 200) {
        final fileName = 'assessment_${_selectedSubject!.id}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMonthlyWithQuizzesReport() async {
    if (_yearController.text.isEmpty) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/all-monthlies-with-quizzes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'year': _yearController.text,
        }),
      );

      if (response.statusCode == 200) {
        final fileName = 'monthly_quizzes_${widget.campusID}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAllSubjectsReport() async {
    if (_yearController.text.isEmpty || _selectedAssessmentType == null) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/all-subjects-assessments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'year': _yearController.text.trim(),
          'assessment_type': _selectedAssessmentType,
        }),
      );

      if (response.statusCode == 200) {
        final fileName =
            'all_subjects_${widget.campusID}_${_yearController.text}_${_selectedAssessmentType}.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir =
              await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _handleFileDownload(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Web implementation
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        // Clean up
        html.Url.revokeObjectUrl(url);
        _showToast('Download started! Check your downloads folder');
      } else {
        // Mobile implementation
        final directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(filePath);

        _showToast('File saved to: $filePath');
      }
    } catch (e) {
      _showToast('Error saving file: ${e.toString()}');
      debugPrint('File download error: $e');

      // Fallback for web if the download doesn't start automatically
      if (kIsWeb) {
        _showToast('If download didn\'t start, right-click and "Save as"');
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String day;
  final String teacher;
  final int year;

  Subject({
    required this.id,
    required this.name,
    required this.day,
    required this.teacher,
    required this.year,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['subject_id'] as int,
    name: json['subject_name'] as String,
    day: json['day'] as String,
    teacher: json['teacher_name'] as String,
    year: json['year'] as int,
  );

  @override
  String toString() => '$name ($id)';
}