import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class SubjectAssignmentsScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectAssignmentsScreen({super.key, required this.subject});

  @override
  _SubjectAssignmentsScreenState createState() => _SubjectAssignmentsScreenState();
}

class _SubjectAssignmentsScreenState extends State<SubjectAssignmentsScreen> {
  List<dynamic> assignments = [];
  bool isLoading = true;
  String errorMessage = '';
  final String _baseUrl = 'http://193.203.162.232:5050/SubjectAssignment/api';
  bool _showAssignmentDialog = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  DateTime? _dueDate;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subjects/${widget.subject['subject_id']}/assignments'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          assignments = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load assignments: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading assignments: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subjects/${widget.subject['subject_id']}/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'due_date': _dueDate?.toIso8601String(),
          'total_points': int.tryParse(_pointsController.text) ?? 100,
          'attachments': _attachments,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment created successfully')),
        );
        setState(() {
          _showAssignmentDialog = false;
          _titleController.clear();
          _descriptionController.clear();
          _pointsController.clear();
          _dueDate = null;
          _attachments = [];
        });
        await _fetchAssignments();
      } else {
        throw Exception('Failed to create assignment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create assignment: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 23, minute: 59),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildAssignmentDialog() {
    return AlertDialog(
      title: Text('Create New Assignment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _pointsController,
                decoration: InputDecoration(labelText: 'Total Points'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Points are required' : null,
              ),
              SizedBox(height: 12),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate!)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDueDate,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _showAssignmentDialog = false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _createAssignment,
                    child: Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.assignment_add),
          backgroundColor: Colors.blue,
          label: 'New Assignment',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => setState(() => _showAssignmentDialog = true),
        ),
        SpeedDialChild(
          child: Icon(Icons.refresh),
          backgroundColor: Colors.green,
          label: 'Refresh',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: _fetchAssignments,
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(dynamic assignment, ThemeData theme, Color subjectColor) {
    final dueDate = DateTime.parse(assignment['due_date']);
    final formattedDate = DateFormat('MMM d, y').format(dueDate);
    final timeLeft = dueDate.difference(DateTime.now());
    final progress = assignment['submitted'] / assignment['total'];
    final isActive = assignment['status'] == 'active';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToSubmissions(assignment),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(
                    isActive ? 'ACTIVE' : 'COMPLETED',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.blueGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                assignment['title'],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                assignment['description'],
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Due $formattedDate',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  Spacer(),
                  Text(
                    isActive
                        ? '${timeLeft.inDays}d left'
                        : 'Completed',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? (timeLeft.inDays < 3 ? Colors.red : Colors.green)
                          : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submissions: ${assignment['submitted']}/${assignment['total']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: subjectColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                  ),
                ],
              ),
              if (assignment['attachments'] != null && assignment['attachments'].isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    ...(assignment['attachments'] as List).map<Widget>(
                          (file) => Chip(
                        label: Text(
                          file['file_name'],
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToSubmissions(assignment),
                  child: Text(
                    'VIEW SUBMISSIONS',
                    style: GoogleFonts.poppins(
                      color: subjectColor,
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

  void _navigateToSubmissions(dynamic assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentSubmissionsScreen(
          assignment: assignment,
          subjectColor: widget.subject['color'] ?? Theme.of(context).primaryColor,
          baseUrl: _baseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Assignments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : assignments.isEmpty
              ? Center(
            child: Text(
              'No assignments yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchAssignments,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) => _buildAssignmentCard(
                assignments[index],
                theme,
                subjectColor,
              ),
            ),
          ),
          if (_showAssignmentDialog) _buildAssignmentDialog(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}

class AssignmentSubmissionsScreen extends StatefulWidget {
  final dynamic assignment;
  final Color subjectColor;
  final String baseUrl;

  const AssignmentSubmissionsScreen({
    Key? key,
    required this.assignment,
    required this.subjectColor,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _AssignmentSubmissionsScreenState createState() => _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState extends State<AssignmentSubmissionsScreen> {
  List<dynamic> submissions = [];
  List<dynamic> nonSubmitters = [];
  bool isLoading = true;
  String errorMessage = '';
  int _currentTabIndex = 0;
  Map<int, TextEditingController> _gradeControllers = {};
  Map<int, TextEditingController> _feedbackControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _fetchSubmissions(),
        _fetchNonSubmitters(),
      ]);

      setState(() {
        submissions = results[0];
        nonSubmitters = results[1];

        // Initialize controllers
        for (var sub in submissions) {
          _gradeControllers[sub['submission_id']] = TextEditingController(
            text: sub['grade']?.toString() ?? '',
          );
          _feedbackControllers[sub['submission_id']] = TextEditingController(
            text: sub['feedback'] ?? '',
          );
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchSubmissions() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/assignments/${widget.assignment['id']}/submissions'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading submissions: ${e.toString()}');
    }
  }

  Future<List<dynamic>> _fetchNonSubmitters() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/assignments/${widget.assignment['id']}/non-submitters'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load non-submitters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading non-submitters: ${e.toString()}');
    }
  }

  Future<void> _gradeSubmission(int submissionId) async {
    final grade = int.tryParse(_gradeControllers[submissionId]!.text);
    if (grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid grade')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/submissions/$submissionId/grade'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'grade': grade,
          'feedback': _feedbackControllers[submissionId]!.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission graded successfully')),
        );
        await _loadData();
      } else {
        throw Exception('Failed to grade submission: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to grade submission: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendReminder(String studentRfid) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/assignments/${widget.assignment['id']}/reminders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'student_rfid': studentRfid}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder sent successfully')),
        );
      } else {
        throw Exception('Failed to send reminder: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reminder: ${e.toString()}')),
      );
    }
  }

  Widget _buildSubmissionCard(dynamic submission, ThemeData theme) {
    final isSubmitted = submission['status'] == 'submitted' || submission['status'] == 'graded';
    final submittedAt = submission['submission_date'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(submission['submission_date']))
        : 'Not submitted';
    final isGraded = submission['status'] == 'graded';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  submission['student_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    isGraded ? 'GRADED' : 'SUBMITTED',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: isGraded ? Colors.green : Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 4),
                Text(
                  submittedAt,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _viewSubmissionFile(submission),
                  child: Text(
                    submission['file_name'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: widget.subjectColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            if (isGraded) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.grade, size: 14, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Grade: ${submission['grade']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Feedback: ${submission['feedback']}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ],
            if (isSubmitted && !isGraded) ...[
              SizedBox(height: 12),
              TextFormField(
                controller: _gradeControllers[submission['submission_id']],
                decoration: InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _feedbackControllers[submission['submission_id']],
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _gradeSubmission(submission['submission_id']),
                  child: Text(
                    'Submit Grade',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNonSubmitterCard(dynamic student, ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  student['student_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    'NOT SUBMITTED',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 4),
                Text(
                  student['email'] ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => _sendReminder(student['RFID']),
                child: Text(
                  'Send Reminder',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.assignment['title'],
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: widget.subjectColor,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Submissions (${submissions.length})'),
              Tab(text: 'Not Submitted (${nonSubmitters.length})'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : TabBarView(
          children: [
            // Submissions Tab
            RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) => _buildSubmissionCard(
                  submissions[index],
                  theme,
                ),
              ),
            ),
            // Non-submitters Tab
            RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: nonSubmitters.length,
                itemBuilder: (context, index) => _buildNonSubmitterCard(
                  nonSubmitters[index],
                  theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewSubmissionFile(dynamic submission) async {
    try {
      final filePath = submission['file_path']; // From your API
      const String baseUrl = 'http://193.203.162.232:5050/'; // Replace with your real base URL

      if (filePath == null || filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File path not available')),
        );
        return;
      }

      // Construct full file URL
      final fileUrl = '$baseUrl$filePath';

      print('🔗 File URL: $fileUrl'); // For debugging

      // Open the file
      final result = await OpenFile.open(fileUrl);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: ${e.toString()}')),
      );
    }
  }

  Future<void> _openPdf(String fileUrl, String fileName) async {
    try {
      // Open the file directly from the URL
      final result = await OpenFile.open(fileUrl);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _gradeControllers.forEach((_, controller) => controller.dispose());
    _feedbackControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}