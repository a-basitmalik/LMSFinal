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

class Subject {
  final int id;
  final String name;
  final String day;
  final String teacher;
  final int year;          // or String if you treat it like "1"

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
  String toString() => '$name ($id)';      // handy for debug
}


class DownloadReportsScreen extends StatefulWidget {
  final int campusID;
  final String campusName;

  const DownloadReportsScreen({
    Key? key,
    required this.campusID,
    required this.campusName,
  }) : super(key: key);

  @override
  _DownloadReportsScreenState createState() => _DownloadReportsScreenState();
}

class _DownloadReportsScreenState extends State<DownloadReportsScreen> {


/* ────────────────────────────  FIELDS  ──────────────────────────── */

  bool _isLoading        = false;   // for report‑generation spinners
  bool _isLoadingSubjects = false;  // for the subjects dropdown

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
    _fetchSubjects();  // 🔁 Start fetching subjects as soon as the screen opens
  }

/* ───────────────────────────  FETCH SUBJECTS  ─────────────────────────── */

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);

    try {
      final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
      final uri  = Uri.http(
        '$host:5050',
        '/ReportDownload/subjects',
        {'campusid': widget.campusID.toString()},
      );

      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as List;
        final subjects = raw
            .map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

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

/* ──────────────────────────  SUBJECT DROPDOWN  ────────────────────────── */

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<Subject>(
      value: _selectedSubject,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subject',
        border: OutlineInputBorder(),
      ),
      hint: _isLoadingSubjects
          ? const Text('Loading subjects...')
          : const Text('Select a subject'),
      items: _subjects.map((s) {
        return DropdownMenuItem<Subject>(
          value: s,
          child: Text('${s.name} (ID: ${s.id})'),
        );
      }).toList(),
      onChanged: (newSubj) => setState(() => _selectedSubject = newSubj),
      validator: (v) => v == null ? 'Please select a subject' : null,
    );
  }

/* ───────────────────────  GENERATE SUBJECT REPORT  ────────────────────── */

  Future<void> _generateSubjectReport() async {
    if (_selectedSubject == null || _yearController.text.isEmpty) {
      _showToast('Please select a subject and year');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:5050/ReportDownload/subject-report'),
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
        Uri.parse('http://127.0.0.1:5050/ReportDownload/assessment-report'),
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
        Uri.parse('http://127.0.0.1:5050/ReportDownload/all-monthlies-with-quizzes'),
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
        Uri.parse('http://127.0.0.1:5050/ReportDownload/all-subjects-assessments'),
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

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reports - ${widget.campusName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Subject Report'),
              Tab(text: 'Assessment Report'),
              Tab(text: 'Monthly with Quizzes'),
              Tab(text: 'All Subjects'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSubjectReportTab(),
            _buildAssessmentReportTab(),
            _buildMonthlyWithQuizzesTab(),
            _buildAllSubjectsReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate Subject Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateSubjectReport,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Generate Subject Report'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'This report will include all assessment types for the specified subject, including monthly assessments with quiz data.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate Assessment Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAssessmentType,
            decoration: const InputDecoration(
              labelText: 'Assessment Type',
              border: OutlineInputBorder(),
            ),
            items: _assessmentTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedAssessmentType = newValue;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateAssessmentReport,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Generate Assessment Report'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'This report will include all assessments of the selected type for the specified subject.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyWithQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate Monthly with Quizzes Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateMonthlyWithQuizzesReport,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Generate Monthly with Quizzes Report'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'This report will include all monthly assessments with their associated quiz data for all subjects in the campus.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSubjectsReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate All Subjects Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAssessmentType,
            decoration: const InputDecoration(
              labelText: 'Assessment Type',
              border: OutlineInputBorder(),
            ),
            items: _assessmentTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _selectedAssessmentType = value),
            validator: (value) =>
            value == null ? 'Select an assessment type' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateAllSubjectsReport,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Generate All Subjects Report'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'This report will include all assessments of the selected type '
                'for all subjects in the campus.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}