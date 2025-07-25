import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:dio/dio.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  DateTime? _dueDate;
  final Dio _dio = Dio();
  List<File> _selectedFiles = [];
  List<Map<String, dynamic>> _uploadedAttachments = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _uploadedAttachments = [];
    });

    for (var file in _selectedFiles) {
      try {
        String fileName = file.path.split('/').last;
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        });

        final response = await _dio.post(
          'http://193.203.162.232:5050/student/api/assignments/upload',
          data: formData,
        );

        if (response.statusCode == 200) {
          setState(() {
            _uploadedAttachments.add({
              'file_name': response.data['file_name'],
              'file_path': response.data['file_path'],
            });
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${file.path.split('/').last}'),
            backgroundColor: TeacherColors.dangerAccent,
          ),
        );
      }
    }

    setState(() {
      _selectedFiles = [];
    });
  }

  void _showAssignmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Assignment',
                      style: TeacherTextStyles.headerTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      style: TeacherTextStyles.listItemTitle,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                        ),
                      ),
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: TeacherTextStyles.listItemTitle,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                        ),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      style: TeacherTextStyles.listItemTitle,
                      decoration: InputDecoration(
                        labelText: 'Total Points',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Points are required' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _dueDate == null
                            ? 'Select Due Date'
                            : 'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate!)}',
                        style: TeacherTextStyles.listItemTitle,
                      ),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: TeacherColors.chatColor,
                      ),
                      onTap: () => _pickDueDate(setState),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: TeacherColors.cardBorder),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File attachments section
                    if (_selectedFiles.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Files:',
                            style: TeacherTextStyles.cardSubtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._selectedFiles.map((file) => ListTile(
                            leading: Icon(Icons.insert_drive_file,
                                color: TeacherColors.secondaryText),
                            title: Text(
                              file.path.split('/').last,
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  color: TeacherColors.dangerAccent),
                              onPressed: () => setState(() =>
                                  _selectedFiles.remove(file)),
                            ),
                          )).toList(),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Add files button
                    InkWell(
                      onTap: _pickFiles,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: TeacherColors.cardBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file,
                                color: TeacherColors.chatColor),
                            const SizedBox(width: 10),
                            Text('Add Attachment',
                                style: TeacherTextStyles.cardSubtitle),
                          ],
                        ),
                      ),
                    ),

                    // Upload button if files selected
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _uploadFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherColors.chatColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Upload Files',
                          style: TeacherTextStyles.primaryButton,
                        ),
                      ),
                    ],

                    // Show uploaded attachments
                    if (_uploadedAttachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploaded:',
                            style: TeacherTextStyles.cardSubtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ..._uploadedAttachments.map((attachment) => ListTile(
                            leading: Icon(Icons.check_circle,
                                color: TeacherColors.successAccent),
                            title: Text(
                              attachment['file_name'],
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                          )).toList(),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _titleController.clear();
                                _descriptionController.clear();
                                _pointsController.clear();
                                _dueDate = null;
                                _selectedFiles = [];
                                _uploadedAttachments = [];
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: TeacherColors.cardBorder),
                            ),
                            child: Text(
                              'Cancel',
                              style: TeacherTextStyles.primaryButton,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate() && _dueDate != null) {
                                _submitAssignment();
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill all required fields'),
                                    backgroundColor: TeacherColors.warningAccent,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TeacherColors.chatColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Create',
                              style: TeacherTextStyles.primaryButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDueDate(StateSetter setState) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TeacherColors.chatColor,
              onPrimary: TeacherColors.primaryText,
              surface: TeacherColors.secondaryBackground,
              onSurface: TeacherColors.primaryText,
            ),
            dialogBackgroundColor: TeacherColors.primaryBackground,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
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

  Future<void> _submitAssignment() async {
    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/student/api/subjects/${widget.subject['subject_id']}/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'due_date': _dueDate?.toIso8601String(),
          'total_points': int.tryParse(_pointsController.text) ?? 100,
          'attachments': _uploadedAttachments,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment created successfully'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _pointsController.clear();
          _dueDate = null;
          _selectedFiles = [];
          _uploadedAttachments = [];
        });
        await _fetchAssignments();
      } else {
        throw Exception('Failed to create assignment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create assignment: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

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

  Widget _buildAssignmentCard(dynamic assignment) {
    final dueDate = DateTime.parse(assignment['due_date']);
    final formattedDate = DateFormat('MMM d, y').format(dueDate);
    final timeLeft = dueDate.difference(DateTime.now());
    final progress = assignment['submitted'] / assignment['total'];
    final isActive = assignment['status'] == 'active';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: TeacherColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: TeacherColors.cardBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToSubmissions(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(
                    isActive ? 'ACTIVE' : 'COMPLETED',
                    style: TeacherTextStyles.primaryButton.copyWith(fontSize: 12),
                  ),
                  backgroundColor: isActive
                      ? TeacherColors.successAccent
                      : TeacherColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assignment['title'],
                style: TeacherTextStyles.assignmentTitle,
              ),
              const SizedBox(height: 8),
              Text(
                assignment['description'],
                style: TeacherTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: TeacherColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due $formattedDate',
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                  const Spacer(),
                  Text(
                    isActive
                        ? '${timeLeft.inDays}d left'
                        : 'Completed',
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      color: isActive
                          ? (timeLeft.inDays < 3
                          ? TeacherColors.dangerAccent
                          : TeacherColors.successAccent)
                          : TeacherColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submissions: ${assignment['submitted']}/${assignment['total']}',
                    style: TeacherTextStyles.listItemTitle,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: TeacherColors.chatColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        TeacherColors.chatColor),
                  ),
                ],
              ),
              if (assignment['attachments'] != null &&
                  assignment['attachments'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: TeacherColors.secondaryText,
                    ),
                    ...(assignment['attachments'] as List).map<Widget>(
                          (file) =>
                          Chip(
                            label: Text(
                              file['file_name'],
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                            backgroundColor: TeacherColors.secondaryBackground,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToSubmissions(assignment),
                  child: Text(
                    'VIEW SUBMISSIONS',
                    style: TeacherTextStyles.secondaryButton.copyWith(
                      color: TeacherColors.chatColor,
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
        builder: (context) =>
            AssignmentSubmissionsScreen(
              assignment: assignment,
              subjectColor: TeacherColors.chatColor,
              baseUrl: _baseUrl,
            ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      backgroundColor: TeacherColors.chatColor,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: Icon(Icons.assignment_add, color: TeacherColors.primaryText),
          backgroundColor: TeacherColors.chatColor,
          label: 'New Assignment',
          labelStyle: TeacherTextStyles.primaryButton,
          onTap: _showAssignmentDialog,
        ),
        SpeedDialChild(
          child: Icon(Icons.refresh, color: TeacherColors.primaryText),
          backgroundColor: TeacherColors.primaryAccent,
          label: 'Refresh',
          labelStyle: TeacherTextStyles.primaryButton,
          onTap: _fetchAssignments,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Assignments',
          style: TeacherTextStyles.className,
        ),
        backgroundColor: TeacherColors.chatColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Column(
        children: [
          // Glass Card Create Assignment Button at Top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _showAssignmentDialog,
              child: Container(
                decoration: TeacherColors.glassDecoration(
                  borderRadius: 16,
                  borderColor: TeacherColors.chatColor.withOpacity(0.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: TeacherColors.chatColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CREATE NEW ASSIGNMENT',
                        style: TeacherTextStyles.sectionHeader.copyWith(
                          color: TeacherColors.chatColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content Stack inside Expanded
          Expanded(
            child: Stack(
              children: [
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: TeacherColors.primaryAccent,
                    ),
                  )
                else if (errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      errorMessage,
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: TeacherColors.dangerAccent,
                      ),
                    ),
                  )
                else if (assignments.isEmpty)
                    Center(
                      child: Text(
                        'No assignments yet',
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                    )
                  else
                    RefreshIndicator(
                      onRefresh: _fetchAssignments,
                      color: TeacherColors.chatColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) =>
                            _buildAssignmentCard(assignments[index]),
                      ),
                    ),
              ],
            ),
          ),
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
        SnackBar(
          content: Text('Please enter a valid grade'),
          backgroundColor: TeacherColors.warningAccent,
        ),
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
          SnackBar(
            content: Text('Submission graded successfully'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
        await _loadData();
      } else {
        throw Exception('Failed to grade submission: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grade submission: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
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
          SnackBar(
            content: Text('Reminder sent successfully'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
      } else {
        throw Exception('Failed to send reminder: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reminder: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Widget _buildSubmissionCard(dynamic submission) {
    final isSubmitted = submission['status'] == 'submitted' || submission['status'] == 'graded';
    final submittedAt = submission['submission_date'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(submission['submission_date']))
        : 'Not submitted';
    final isGraded = submission['status'] == 'graded';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: TeacherColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: TeacherColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Name and Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  submission['student_name'],
                  style: TeacherTextStyles.listItemTitle,
                ),
                Chip(
                  label: Text(
                    isGraded ? 'GRADED' : 'SUBMITTED',
                    style: TeacherTextStyles.primaryButton.copyWith(fontSize: 12),
                  ),
                  backgroundColor: isGraded
                      ? TeacherColors.successAccent
                      : TeacherColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Submission Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: TeacherColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  submittedAt,
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // File Attachment
            Row(
              children: [
                Icon(Icons.attach_file, size: 14, color: TeacherColors.secondaryText),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _viewSubmissionFile(submission),
                  child: Text(
                    submission['file_name'],
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      color: widget.subjectColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            // If graded, show grade and feedback
            if (isGraded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.grade, size: 14, color: TeacherColors.warningAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Grade: ${submission['grade']}',
                    style: TeacherTextStyles.listItemTitle,
                  ),
                ],
              ),
              if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Feedback: ${submission['feedback']}',
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ],

            // If submitted but not graded
            if (isSubmitted && !isGraded) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _gradeControllers[submission['submission_id']],
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Grade',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackControllers[submission['submission_id']],
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _gradeSubmission(submission['submission_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit Grade',
                    style: TeacherTextStyles.primaryButton,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNonSubmitterCard(dynamic student) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: TeacherColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: TeacherColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  student['student_name'],
                  style: TeacherTextStyles.listItemTitle,
                ),
                Chip(
                  label: Text(
                    'NOT SUBMITTED',
                    style: TeacherTextStyles.primaryButton.copyWith(fontSize: 12),
                  ),
                  backgroundColor: TeacherColors.dangerAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 14,
                  color: TeacherColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  student['email'] ?? 'No email',
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.warningAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sendReminder(student['RFID']),
                child: Text(
                  'Send Reminder',
                  style: TeacherTextStyles.primaryButton,
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
      final filePath = submission['file_path'];
      const String baseUrl = 'http://193.203.162.232:5050/';

      if (filePath == null || filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File path not available'),
            backgroundColor: TeacherColors.warningAccent,
          ),
        );
        return;
      }

      final fileUrl = '$baseUrl$filePath';
      final result = await OpenFile.open(fileUrl);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: TeacherColors.dangerAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _gradeControllers.forEach((_, controller) => controller.dispose());
    _feedbackControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.assignment['title'],
            style: TeacherTextStyles.className,
          ),
          backgroundColor: widget.subjectColor,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: TeacherColors.primaryText,
            tabs: [
              Tab(
                child: Text(
                  'Submissions (${submissions.length})',
                  style: TeacherTextStyles.primaryButton,
                ),
              ),
              Tab(
                child: Text(
                  'Not Submitted (${nonSubmitters.length})',
                  style: TeacherTextStyles.primaryButton,
                ),
              ),
            ],
          ),
        ),
        body: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: TeacherColors.primaryAccent,
          ),
        )
            : errorMessage.isNotEmpty
            ? Center(
          child: Text(
            errorMessage,
            style: TeacherTextStyles.cardSubtitle.copyWith(
              color: TeacherColors.dangerAccent,
            ),
          ),
        )
            : TabBarView(
          children: [
            // Submissions Tab
            RefreshIndicator(
              onRefresh: _loadData,
              color: widget.subjectColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) => _buildSubmissionCard(
                  submissions[index],
                ),
              ),
            ),
            // Non-submitters Tab
            RefreshIndicator(
              onRefresh: _loadData,
              color: widget.subjectColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: nonSubmitters.length,
                itemBuilder: (context, index) => _buildNonSubmitterCard(
                  nonSubmitters[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}