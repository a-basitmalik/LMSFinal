import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/SubjectChat.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'SubjectAssignments.dart';
import 'SubjectQueries.dart';
import 'SubjectResults.dart';
import 'SubjectAttendance.dart';
import 'SubjectAnnouncementsScreen.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

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
  late List<Widget> _screens;
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
    _screens = []; // Initialize empty list
    _fetchSubjectData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access inherited widgets
    _screens = [
      _buildOverviewScreen(),
      SubjectAssignmentsScreen(subject: widget.subject),
      SubjectQueriesScreen(subject: widget.subject),
      SubjectResultsScreen(subject: widget.subject),
      SubjectAttendanceScreen(subject: widget.subject),
      SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
    ];
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
        http.get(Uri.parse('http://192.168.18.185:5050/SubjectPlanner/subject/${widget.subject['subject_id']}/planners')),
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

      // Initialize screens after data is loaded
      _screens = [
        _buildOverviewScreen(),
        SubjectAssignmentsScreen(subject: widget.subject),
        SubjectQueriesScreen(subject: widget.subject),
        SubjectResultsScreen(subject: widget.subject),
        SubjectAttendanceScreen(subject: widget.subject),
        SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
      ];
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;

        // Initialize with empty data to prevent UI from getting stuck
        subjectStats = {};
        announcements = [];
        assignments = [];
        queries = [];
        attendance = [];
        planners = [];

        _screens = [
          _buildOverviewScreen(),
          SubjectAssignmentsScreen(subject: widget.subject),
          SubjectQueriesScreen(subject: widget.subject),
          SubjectResultsScreen(subject: widget.subject),
          SubjectAttendanceScreen(subject: widget.subject),
          SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
        ];
      });
    }
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null; // or empty list/map depending on expected type
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
        title: Text(
          widget.subject['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      )
          : null,
      body: Stack(
        children: [
          // Main screen content
          _screens.isNotEmpty
              ? _screens[_currentIndex]
              : const Center(child: CircularProgressIndicator()),

          // Blur and overlay menu if open
          if (_isMenuOpen) ...[
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                color: Colors.black.withOpacity(0.1),
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
            Text(errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubjectData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStatsPanel(),
          SizedBox(height: 24),
          _buildTodaysPlannerSection(),
          SizedBox(height: 24),
          _buildSectionPreview(
            title: 'Recent Announcements',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectAnnouncementsScreen(subject: widget.subject),
              ),
            ),
            child: _buildAnnouncementsPreview(),
          ),
          _buildSectionPreview(
            title: 'Upcoming Assignments',
            onViewAll: () => _navigateToScreen(1),
            child: _buildAssignmentsPreview(),
          ),
          _buildSectionPreview(
            title: 'Pending Queries',
            onViewAll: () => _navigateToScreen(2),
            child: _buildQueriesPreview(),
          ),
          _buildSectionPreview(
            title: 'Attendance Summary',
            onViewAll: () => _navigateToScreen(4),
            child: _buildAttendancePreview(),
          ),
          _buildSectionPreview(
            title: 'Recent Messages',
            onViewAll: () => _navigateToScreen(5),
            child: _buildChatPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlannerSection() {
    final today = DateTime.now();
    final todayPlanners = planners.where((planner) {
      final plannerDate = DateTime.parse(planner['planned_date']);
      return plannerDate.year == today.year &&
          plannerDate.month == today.month &&
          plannerDate.day == today.day;
    }).toList();

    if (todayPlanners.isEmpty) {
      return _buildSectionPreview(
        title: "Today's Planner",
        onViewAll: () => _showAllPlanners(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No planner for today',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildSectionPreview(
      title: "Today's Planner",
      onViewAll: () => _showAllPlanners(),
      child: Column(
        children: todayPlanners.take(2).map((planner) {
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple[50],
                  child: Icon(Icons.calendar_today, color: Colors.purple),
                ),
                title: Text(
                  planner['title'] ?? 'No title',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  planner['description'] != null &&
                      planner['description'].isNotEmpty
                      ? planner['description'].length > 50
                      ? '${planner['description'].substring(0, 50)}...'
                      : planner['description']
                      : 'No description',
                  style: GoogleFonts.poppins(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => _showPlannerDetails(planner),
                ),
              ),
              if (planner != todayPlanners.last) Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAllPlanners() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                'All Planners',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: planners.length,
                  itemBuilder: (context, index) {
                    final planner = planners[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[50],
                          child: Icon(Icons.calendar_today, color: Colors.purple),
                        ),
                        title: Text(
                          planner['title'] ?? 'No title',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(
                                  DateTime.parse(planner['planned_date'])),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              planner['description'] != null &&
                                  planner['description'].isNotEmpty
                                  ? planner['description'].length > 50
                                  ? '${planner['description'].substring(0, 50)}...'
                                  : planner['description']
                                  : 'No description',
                              style: GoogleFonts.poppins(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () => _showPlannerDetails(planner),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlannerDetails(Map<String, dynamic> planner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannerDetailsScreen(
          planner: planner,
          subjectColor: widget.subject['color'] ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
      _isMenuOpen = false;
    });
  }

  Widget _buildInfographicMenu() {

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Overview',
        'icon': Icons.lightbulb,
        'index': 0,
        'color': Colors.red,
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment,
        'index': 1,
        'color': Colors.orange,
      },
      {
        'title': 'Queries',
        'icon': Icons.question_answer,
        'index': 2,
        'color': Colors.blue,
      },
      {
        'title': 'Results',
        'icon': Icons.assessment,
        'index': 3,
        'color': Colors.green,
      },
      {
        'title': 'Attendance',
        'icon': Icons.calendar_today,
        'index': 4,
        'color': Colors.purple,
      },
      {
        'title': 'Chat',
        'icon': Icons.chat_bubble,
        'index': 5,
        'color': Colors.teal,
      },

    ];

    return Positioned(
      top: 120,
      right: 20,
      child: AnimatedOpacity(
        opacity: _isMenuOpen ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Column(
          children: menuItems.map((item) {
            return GestureDetector(
              onTap: () => _navigateToScreen(item['index']),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: item['color'],
                      radius: 26,
                      child: Icon(
                        item['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      item['title'],
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;

    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: subjectColor,
      elevation: 8,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          _isMenuOpen ? Icons.close : Icons.apps_rounded,
          key: ValueKey(_isMenuOpen ? 'close' : 'menu'),
          size: 28,
        ),
      ),
      onPressed: () {
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });
      },
    );
  }

  Widget _buildQuickStatsPanel() {
    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;

    // Safely parse attendance rate
    double attendanceRate = 0.0;
    if (subjectStats['attendance_rate'] != null) {
      if (subjectStats['attendance_rate'] is String) {
        attendanceRate = double.tryParse(subjectStats['attendance_rate']) ?? 0.0;
      } else if (subjectStats['attendance_rate'] is num) {
        attendanceRate = subjectStats['attendance_rate'].toDouble();
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            subjectColor.withOpacity(0.8),
            subjectColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                subjectStats['student_count']?.toString() ?? '0',
                'Students',
                Icons.people,
              ),
              _buildStatItem(
                subjectStats['assignment_count']?.toString() ?? '0',
                'Assignments',
                Icons.assignment,
              ),
              _buildStatItem(
                '${attendanceRate.toStringAsFixed(0)}%',
                'Attendance',
                Icons.calendar_today,
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsPreview() {
    if (announcements.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No recent announcements',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: announcements.take(2).map((announcement) {
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Icon(Icons.announcement, color: Colors.blue),
              ),
              title: Text(
                announcement['title'] ?? 'No title',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                announcement['content'] ?? 'No content',
                style: GoogleFonts.poppins(),
              ),
              trailing: Text(
                _formatTime(announcement['created_at']),
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
              ),
            ),
            if (announcement != announcements.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentsPreview() {
    if (assignments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No upcoming assignments',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;
    final studentCount = subjectStats['student_count'] is String
        ? int.tryParse(subjectStats['student_count']) ?? 1
        : (subjectStats['student_count'] ?? 1);

    return Column(
      children: assignments.take(2).map((assignment) {
        final submittedCount = assignment['submitted_count'] is String
            ? int.tryParse(assignment['submitted_count']) ?? 0
            : (assignment['submitted_count'] ?? 0);

        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange[50],
                child: Icon(Icons.assignment, color: Colors.orange),
              ),
              title: Text(
                assignment['title'] ?? 'No title',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due: ${_formatDate(assignment['due_date'])}',
                    style: GoogleFonts.poppins(),
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: submittedCount / studentCount,
                    backgroundColor: subjectColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                  ),
                  Text(
                    '$submittedCount/$studentCount submitted',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (assignment != assignments.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQueriesPreview() {
    if (queries.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No pending queries',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: queries.take(2).map((query) {
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: query['status'] == 'answered'
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Icon(
                  Icons.question_answer,
                  color: query['status'] == 'answered'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              title: Text(
                query['student_name'] ?? 'Student',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                (query['question']?.length ?? 0) > 30
                    ? '${query['question'].substring(0, 30)}...'
                    : query['question'] ?? 'No question',
                style: GoogleFonts.poppins(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(
                  query['status'] == 'answered' ? 'Answered' : 'Pending',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white),
                ),
                backgroundColor: query['status'] == 'answered'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            if (query != queries.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAttendancePreview() {
    if (attendance.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No attendance data available',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;
    double attendanceRate = 0.0;
    if (subjectStats['attendance_rate'] != null) {
      if (subjectStats['attendance_rate'] is String) {
        attendanceRate = double.tryParse(subjectStats['attendance_rate']) ?? 0.0;
      } else if (subjectStats['attendance_rate'] is num) {
        attendanceRate = subjectStats['attendance_rate'].toDouble();
      }
    }

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                '${attendanceRate.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: subjectColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: attendanceRate / 100,
            backgroundColor: subjectColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: attendance.take(5).map((day) {
              double dayRate = 0.0;
              if (day['attendance_rate'] is String) {
                dayRate = double.tryParse(day['attendance_rate']) ?? 0.0;
              } else if (day['attendance_rate'] is num) {
                dayRate = day['attendance_rate'].toDouble();
              }

              return _buildMiniAttendanceStat(
                _getDayName(day['day']),
                '${dayRate.toStringAsFixed(0)}%',
                dayRate >= 90 ? Icons.check : Icons.warning,
                dayRate >= 90 ? Colors.green : Colors.orange,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
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

  String _getDayName(String? day) {
    if (day == null) return 'Day';
    return day.length >= 3 ? day.substring(0, 3) : day;
  }

  Widget _buildSectionPreview({
    required String title,
    required VoidCallback onViewAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: widget.subject['color'] ?? Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: EdgeInsets.all(8), child: child),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMiniAttendanceStat(
      String day,
      String percent,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Text(day, style: GoogleFonts.poppins(fontSize: 12)),
        SizedBox(height: 4),
        Icon(icon, color: color, size: 16),
        Text(percent, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Widget _buildChatPreview() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(Icons.person, color: Colors.blue),
          ),
          title: Text(
            'Prof. Smith',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Don\'t forget about the assignment due tomorrow',
            style: GoogleFonts.poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '10m ago',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
        ),
        Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[50],
            child: Icon(Icons.person, color: Colors.green),
          ),
          title: Text(
            'You',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'I submitted the assignment last night',
            style: GoogleFonts.poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '5m ago',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}



class PlannerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> planner;
  final Color subjectColor;

  const PlannerDetailsScreen({
    Key? key,
    required this.planner,
    required this.subjectColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attachments = planner['attachments'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Planner Details'),
        backgroundColor: subjectColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planner['title'] ?? 'No title',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(planner['planned_date'])),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              planner['description'] ?? 'No description',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 24),
            if (attachments.isNotEmpty) ...[
              Text(
                'Attachments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: attachments.map<Widget>((attachment) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getFileIcon(attachment['file_name']),
                        color: subjectColor,
                      ),
                      title: Text(
                        attachment['file_name'],
                        style: GoogleFonts.poppins(),
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