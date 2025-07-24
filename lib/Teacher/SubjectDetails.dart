import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/CreateAssessment.dart';
import 'package:newapp/Teacher/HolographicCalendarScreen.dart';
import 'package:newapp/Teacher/PlannerListScreen.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// Import other screens
import '../Teacher//AddPlannerScreen.dart';
import '../admin/themes/theme_colors.dart';
import '../admin/themes/theme_text_styles.dart';
import 'AnnouncementsScreen.dart';
import 'ComplaintsScreen.dart';
import 'SubjectAssignments.dart';
import 'SubjectQueries.dart';
import 'SubjectResults.dart';
import 'SubjectAttendance.dart';
import 'SubjectAnnouncementsScreen.dart';
import 'SubjectChat.dart';

class SubjectDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  final String teacherId;

  const SubjectDashboardScreen({
    super.key,
    required this.subject,
    required this.teacherId,
  });

  @override
  _SubjectDashboardScreenState createState() => _SubjectDashboardScreenState();
}

class _SubjectDashboardScreenState extends State<SubjectDashboardScreen> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;

  // Data variables
  Map<String, dynamic> subjectStats = {};
  List<dynamic> announcements = [];
  List<dynamic> assignments = [];
  List<dynamic> queries = [];
  List<dynamic> attendance = [];
  List<dynamic> planners = [];
  bool isLoading = true;
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://193.203.162.232:5050/TeacherSubject/api';

  @override
  void initState() {
    super.initState();
    _fetchSubjectData();
  }

  Future<void> _fetchSubjectData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Fetch all data in parallel
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/stats')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/announcements')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/assignments')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/queries')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/attendance')),
        http.get(Uri.parse('$baseUrl/SubjectPlanner/subject/${widget.subject['subject_id']}/planners')),
      ], eagerError: true);

      // Parse responses
      setState(() {
        subjectStats = _parseResponse(responses[0]);
        announcements = _parseResponse(responses[1]) ?? [];
        assignments = _parseResponse(responses[2]) ?? [];
        queries = _parseResponse(responses[3]) ?? [];
        attendance = _parseResponse(responses[4]) ?? [];
        planners = _parseResponse(responses[5]) ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;
        subjectStats = {};
        announcements = [];
        assignments = [];
        queries = [];
        attendance = [];
        planners = [];
      });
    }
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = widget.subject['color'] as Color? ?? TeacherColors.primaryAccent;
    final icon = widget.subject['icon'] as IconData? ?? Icons.school;

    // Initialize screens with top padding
    final screens = [
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: _buildOverviewScreen(),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectAssignmentsScreen(subject: widget.subject),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectQueriesScreen(subject: widget.subject),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectResultsScreen(subject: widget.subject),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectAttendanceScreen(subject: widget.subject),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SubjectAnnouncementScreen(subject: widget.subject),
      ),
    ];

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: Stack(
        children: [
          // Main content - now properly padded
          _currentIndex == 0
              ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildOverviewScreen(),
            ),
          )
              : screens[_currentIndex],

          // Menu overlay (unchanged)
          if (_isMenuOpen) ...[
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
            _buildInfographicMenu(),
          ],
        ],
      ),
      floatingActionButton: _buildMainFAB(),
    );
  }

  Widget _buildOverviewScreen() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage, style: TextStyle(color: TeacherColors.dangerAccent)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubjectData,
              child: Text('Retry', style: TeacherTextStyles.primaryButton),
            ),
          ],
        ),
      );
    }

    final subjectColor = widget.subject['color'] as Color? ?? TeacherColors.primaryAccent;
    final icon = widget.subject['icon'] as IconData? ?? Icons.school;

    return Column(
      children: [
        const SizedBox(height: 20),

        // Subject Header Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            borderRadius: 16,
            borderColor: subjectColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: subjectColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject['name'] as String? ?? 'NA',
                          style: TeacherTextStyles.headerTitle.copyWith(fontSize: 20),
                        ),
                        Text(
                          widget.subject['code'] as String? ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // QUICK STATS PANEL
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            borderRadius: 16,
            borderColor: TeacherColors.cardBorder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    subjectStats['student_count']?.toString() ?? '0',
                    'Students',
                    Icons.people_outline,
                    TeacherColors.studentColor,
                  ),
                  _buildStatItem(
                    subjectStats['assignment_count']?.toString() ?? '0',
                    'Assignments',
                    Icons.assignment_outlined,
                    TeacherColors.assignmentColor,
                  ),
                  _buildStatItem(
                    '${(double.tryParse(subjectStats['attendance_rate']?.toString() ?? '0')?.toStringAsFixed(0))}%',
                    'Attendance',
                    Icons.calendar_today_outlined,
                    TeacherColors.attendanceColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions Section
        _buildSectionHeader(
          icon: Icons.bolt_rounded,
          title: 'QUICK ACTIONS',
          color: subjectColor,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.query_builder,
                  label: 'Chat',
                  color: TeacherColors.assignmentColor,
                  onTap: () => _navigateToScreen(5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.calendar_today,
                  label: 'Attendance',
                  color: TeacherColors.attendanceColor,
                  onTap: () => _navigateToScreen(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.assessment,
                  label: 'Results',
                  color: TeacherColors.gradeColor,
                  onTap: () => _navigateToScreen(3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(
          icon: Icons.folder,
          title: 'Assignments',
          color: subjectColor,
          onTap: () => _navigateToScreen(1),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: assignments.take(2).map((assignment) {
              return _buildResourceItem(
                icon: Icons.assignment,
                title: assignment['title'] ?? 'No title',
                subtitle: 'Due: ${_formatDate(assignment['due_date'])}',
                color: TeacherColors.primaryAccent,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),



        // Lesson Planner Section
        _buildSectionHeader(
          icon: Icons.event_note_rounded,
          title: 'LESSON PLANNER',
          color: TeacherColors.plannerColor,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            borderRadius: 16,
            borderColor: TeacherColors.plannerColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAnimatedButton(
                    icon: Icons.add_rounded,
                    label: 'CREATE NEW PLAN',
                    color: TeacherColors.plannerColor,
                    onTap: () => _showAddPlannerModal(context),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlannerOption(
                          icon: Icons.today_rounded,
                          label: 'Today\'s',
                          subLabel: 'Plans',
                          color: TeacherColors.plannerColor,
                          onTap: () => _navigateToPlannerScreen(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPlannerOption(
                          icon: Icons.calendar_month_rounded,
                          label: 'View',
                          subLabel: 'Calendar',
                          color: TeacherColors.plannerColor,
                          onTap: () => _navigateToCalendarScreen(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPlannerStatsRow(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Recent Queries Section
        _buildSectionHeader(
          icon: Icons.question_answer,
          title: 'RECENT QUERIES',
          color: TeacherColors.infoAccent,
          onTap: () => _navigateToScreen(2),
        ),
        if (queries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              borderRadius: 16,
              borderColor: TeacherColors.infoAccent.withOpacity(0.3),
              child: Column(
                children: [
                  ...queries.take(2).map((query) {
                    return Column(
                      children: [
                        _buildQueryItem(
                          student: query['student_name'] ?? 'Unknown Student',
                          question: query['question'] ?? 'No question text',
                          time: _formatDateTime(query['created_at'] ?? query['timestamp'] ?? ''),
                          status: query['status']?.toString().toLowerCase() ?? 'pending',
                        ),
                        if (query != queries.last)
                          const Divider(height: 1, color: TeacherColors.cardBorder),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          ],
          const SizedBox(height: 32),
          // Announcements Console Section
          // Announcements Console Section
          _buildSectionHeader(
            icon: Icons.announcement,
            title: 'ANNOUNCEMENT CONSOLE',
            color: TeacherColors.infoAccent,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              borderRadius: 16,
              borderColor: TeacherColors.infoAccent.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // _buildAnimatedButton(
                    //   icon: Icons.add_rounded,
                    //   label: 'CREATE NEW ANNOUNCEMENT',
                    //   color: TeacherColors.infoAccent,
                    //   onTap: () => _showAddAnnouncementModal(context),
                    // ),
                    // const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConsoleOption(
                            icon: Icons.campaign_rounded,
                            label: 'View',
                            subLabel: 'Announcements',
                            color: TeacherColors.infoAccent,
                            onTap: () => _navigateToAnnouncementsScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildConsoleOption(
                            icon: Icons.history_rounded,
                            label: 'Call',
                            subLabel: 'History',
                            color: TeacherColors.infoAccent,
                            onTap: () => _navigateToCallHistoryScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedButton(
                      icon: Icons.add_rounded,
                      label: 'CREATE NEW ANNOUNCEMENT',
                      color: TeacherColors.infoAccent,
                      onTap: () => _showAddAnnouncementModal(context),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConsoleOption(
                            icon: Icons.report_problem,
                            label: 'Add',
                            subLabel: 'Complaint',
                            color: TeacherColors.infoAccent,
                            onTap: () => _showAddComplaintModal(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildConsoleOption(
                            icon: Icons.list_alt,
                            label: 'View',
                            subLabel: 'Complaints',
                            color: TeacherColors.infoAccent,
                            onTap: () => _navigateToComplaintsScreen(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

      ],
    );
  }

  void _navigateToComplaintsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintsScreen(subjectId: widget.subject['subject_id']),
      ),
    );
  }
  void _showAddComplaintModal(BuildContext context) {
    String? selectedStudentId;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Student Complaint',
                style: TeacherTextStyles.headerTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 20),

              // Student Dropdown
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchStudentsForSubject(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading students');
                  }
                  final students = snapshot.data ?? [];

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Student',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: students.map((student) {
                      return DropdownMenuItem<String>(
                        value: student['rfid'],
                        child: Text('${student['name']} (${student['rfid']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStudentId = value;
                    },
                    validator: (value) => value == null ? 'Please select a student' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: TeacherTextStyles.primaryButton),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedStudentId == null ||
                            titleController.text.isEmpty ||
                            descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        try {
                          await _submitComplaint(
                            selectedStudentId!,
                            titleController.text,
                            descriptionController.text,
                            widget.subject['subject_id'],
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Complaint submitted successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to submit complaint: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.infoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Submit', style: TeacherTextStyles.primaryButton),
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
  }

  Future<List<Map<String, dynamic>>> _fetchStudentsForSubject() async {
    // Implement API call to fetch students for this subject
    // Example:
    // return await StudentService.getStudentsForSubject(widget.subject['subject_id']);
    return [
      {'rfid': '123', 'name': 'John Doe'},
      {'rfid': '456', 'name': 'Jane Smith'},
    ];
  }

  Future<void> _submitComplaint(
      String rfid,
      String title,
      String description,
      String subjectId,
      ) async {
    // Implement API call to submit complaint
    // Example:
    // await ComplaintService.addComplaint(
    //   rfid: rfid,
    //   title: title,
    //   description: description,
    //   complaintBy: 'teacher',
    //   subjectId: subjectId,
    // );
  }

  void _navigateToAnnouncementsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementScreen(subjectId: widget.subject['subject_id']),
      ),
    );
  }

  void _navigateToCallHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementScreen(subjectId: widget.subject['subject_id']),
      ),
    );
  }
  Widget _buildConsoleOption({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TeacherTextStyles.cardSubtitle.copyWith(color: color)),
            Text(subLabel, style: TeacherTextStyles.cardSubtitle.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  void _showAddAnnouncementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Announcement',
                style: TeacherTextStyles.headerTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // Handle file attachment
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: TeacherColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: TeacherColors.infoAccent),
                      const SizedBox(width: 10),
                      Text('Add Attachment', style: TeacherTextStyles.cardSubtitle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: TeacherTextStyles.primaryButton),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle announcement creation
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.infoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Publish', style: TeacherTextStyles.primaryButton),
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
  }

  void _showAddPlannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: TeacherColors.primaryBackground.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: TeacherColors.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: AddPlannerScreen(subjectId: widget.subject['subject_id']),
          ),
        );
      },
    );
  }

  Widget _buildPlannerOption({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GlassCard(
        borderRadius: 12,
        borderColor: color.withOpacity(0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TeacherTextStyles.cardTitle,
                ),
                Text(
                  subLabel,
                  style: TeacherTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildQueryItem({
    required String student,
    required String question,
    required String time,
    required String status,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = TeacherColors.successAccent;
        break;
      case 'pending':
        statusColor = TeacherColors.warningAccent;
        break;
      default:
        statusColor = TeacherColors.secondaryText;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: TeacherColors.studentColor.withOpacity(0.2),
            child: Icon(Icons.person, color: TeacherColors.studentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: TeacherTextStyles.listItemTitle,
                ),
                Text(
                  question,
                  style: TeacherTextStyles.listItemSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TeacherTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildPlannerStatsRow() {
    Future<Map<String, int>> fetchStats() async {
      final response = await http.get(Uri.parse('http://193.203.162.232:5050/Planner/subject/planner_stats?subject_id=${widget.subject['subject_id']}'));

      if (response.statusCode == 200) {
        return {
          'completed': jsonDecode(response.body)['completed'] ?? 0,
          'pending': jsonDecode(response.body)['pending'] ?? 0,
          'upcoming': jsonDecode(response.body)['upcoming'] ?? 0,
        };
      } else {
        throw Exception('Failed to load stats');
      }
    }

    return FutureBuilder<Map<String, int>>(
      future: fetchStats(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AdminColors.accentGradient(AdminColors.plannerColor),
              border: Border.all(
                color: AdminColors.plannerColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlannerStatItem(
                  icon: Icons.event_available,
                  value: snapshot.data!['completed'].toString(),
                  label: 'Completed',
                ),
                _buildPlannerStatItem(
                  icon: Icons.event_busy,
                  value: snapshot.data!['pending'].toString(),
                  label: 'Pending',
                ),
                _buildPlannerStatItem(
                  icon: Icons.event,
                  value: snapshot.data!['upcoming'].toString(),
                  label: 'Upcoming',
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return CircularProgressIndicator();
      },
    );
  }

  Widget _buildPlannerStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: TeacherColors.plannerColor.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TeacherTextStyles.statValue.copyWith(
                color: TeacherColors.plannerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TeacherTextStyles.statLabel,
        ),
      ],
    );
  }

  void _navigateToPlannerScreen() {
    final subjectId = widget.subject['subject_id'];
    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject ID is missing.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannerListScreen(subjectID: subjectId),
      ),
    );
  }


  void _navigateToCalendarScreen() {
    final subjectId = widget.subject['subject_id'];
    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject ID is missing.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HolographicCalendarScreen(subjectId: subjectId),
      ),
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
      _isMenuOpen = false;
    });
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color ?? TeacherColors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TeacherTextStyles.sectionHeader,
                  ),
                ],
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: (color ?? TeacherColors.primaryAccent).withOpacity(0.7),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      borderRadius: 16,
      borderColor: color.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TeacherTextStyles.cardTitle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: color.toGlassDecoration(borderRadius: 12, borderWidth: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AdminTextStyles.primaryButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      borderRadius: 16,
      borderColor: color.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeacherTextStyles.listItemTitle,
                    ),
                    Text(
                      subtitle,
                      style: TeacherTextStyles.listItemSubtitle,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: TeacherColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassItem({
    required String day,
    required String date,
    required String time,
    required String room,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                day,
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: TeacherTextStyles.listItemSubtitle,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TeacherTextStyles.listItemTitle,
                ),
                Text(
                  room,
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TeacherColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Upcoming',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: TeacherColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem({
    required String sender,
    required String message,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: TeacherColors.studentColor.withOpacity(0.2),
            child: Icon(Icons.person, color: TeacherColors.studentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TeacherTextStyles.listItemTitle,
                ),
                Text(
                  message,
                  style: TeacherTextStyles.listItemSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TeacherTextStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                color.withOpacity(0.4),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TeacherTextStyles.statValue.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TeacherTextStyles.statLabel.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildInfographicMenu() {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Overview', 'icon': Icons.lightbulb_outline, 'index': 0, 'color': TeacherColors.dangerAccent},
      {'title': 'Assignments', 'icon': Icons.assignment_outlined, 'index': 1, 'color': TeacherColors.assignmentColor},
      {'title': 'Queries', 'icon': Icons.question_answer_outlined, 'index': 2, 'color': TeacherColors.infoAccent},
      {'title': 'Results', 'icon': Icons.assessment_outlined, 'index': 3, 'color': TeacherColors.successAccent},
      {'title': 'Attendance', 'icon': Icons.calendar_today_outlined, 'index': 4, 'color': TeacherColors.attendanceColor},
      {'title': 'Chat', 'icon': Icons.chat_bubble_outline, 'index': 5, 'color': TeacherColors.primaryAccent},
    ];

    return Positioned(
      top: 120,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: menuItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GlassCard(
              borderRadius: 12,
              borderColor: item['color'].withOpacity(0.3),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                    _currentIndex = item['index'];
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'], color: item['color']),
                      const SizedBox(width: 12),
                      Text(
                        item['title'],
                        style: TeacherTextStyles.cardTitle.copyWith(color: item['color']),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainFAB() {
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: TeacherColors.primaryAccent,
      elevation: 0,
      child: Icon(
        _isMenuOpen ? Icons.close : Icons.apps_rounded,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class GlassCard extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  final double borderRadius;
  final double? height;
  final double? width;

  const GlassCard({
    Key? key,
    this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? TeacherColors.cardBorder,
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TeacherColors.glassEffectLight, TeacherColors.glassEffectDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class PlannerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> planner;

  const PlannerDetailsScreen({
    Key? key,
    required this.planner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attachments = planner['attachments'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Planner Details'),
        backgroundColor: TeacherColors.primaryBackground,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planner['title'] ?? 'No title',
              style: TeacherTextStyles.sectionHeader,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: TeacherColors.secondaryText),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(planner['planned_date'])),
                  style: TeacherTextStyles.cardSubtitle,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Description',
              style: TeacherTextStyles.sectionHeader,
            ),
            SizedBox(height: 8),
            Text(
              planner['description'] ?? 'No description',
              style: TeacherTextStyles.cardSubtitle,
            ),
            SizedBox(height: 24),
            if (attachments.isNotEmpty) ...[
              Text(
                'Attachments',
                style: TeacherTextStyles.sectionHeader,
              ),
              SizedBox(height: 8),
              Column(
                children: attachments.map<Widget>((attachment) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getFileIcon(attachment['file_name']),
                        color: TeacherColors.primaryAccent,
                      ),
                      title: Text(
                        attachment['file_name'],
                        style: TeacherTextStyles.cardSubtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () => _openAttachment(attachment, context),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName
        .split('.')
        .last
        .toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openAttachment(Map<String, dynamic> attachment,
      BuildContext parentContext) async {
    final url = attachment['file_url'];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Attachment URL is invalid')),
      );
      return;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) =>
          AlertDialog(
            title: Text('Open Attachment'),
            content: Text(
                'Would you like to download or view ${attachment['file_name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Opening attachment...')),
                  );

                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Could not launch attachment')),
                    );
                  }
                },
                child: Text('Open'),
              ),
            ],
          ),
    );
  }


}