import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/SubjectChat.dart';
import 'dart:convert';
import 'SubjectAssignments.dart';
import 'SubjectQueries.dart';
import 'SubjectResults.dart';
import 'SubjectAttendance.dart';
import 'SubjectAnnouncementsScreen.dart';
import 'dart:ui';

class SubjectDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  final String teacherId;

  const SubjectDashboardScreen({super.key, required this.subject,required this.teacherId});

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
  bool isLoading = true;
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://192.168.18.185:5050/TeacherSubject/api';

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
      // SubjectChatScreen(subject: widget.subject),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar:
      _currentIndex == 0
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      )
          : null,
      body: Stack(
        children: [
          _screens.isNotEmpty
              ? _screens[_currentIndex]
              : const Center(child: CircularProgressIndicator()),

          // Blur effect when menu is open
          if (_isMenuOpen)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),

          _buildInfographicMenu(),
        ],
      ),
      floatingActionButton: _buildMainFAB(),
    );
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
        // http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/chat')),
      ]);

      // Check all responses
      for (var response in responses) {
        if (response.statusCode != 200) {
          throw Exception('Failed to load data: ${response.statusCode}');
        }
      }

      // Parse responses
      setState(() {
        subjectStats = json.decode(responses[0].body);
        announcements = json.decode(responses[1].body);
        assignments = json.decode(responses[2].body);
        queries = json.decode(responses[3].body);
        attendance = json.decode(responses[4].body);
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
      });
    }
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (_screens.isEmpty && !isLoading) {
  //     _screens = [
  //       _buildOverviewScreen(),
  //       SubjectAssignmentsScreen(subject: widget.subject),
  //       SubjectQueriesScreen(subject: widget.subject),
  //       SubjectResultsScreen(subject: widget.subject),
  //       SubjectAttendanceScreen(subject: widget.subject),
  //     ];
  //   }
  // }

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
  Widget? _buildFloatingActionButton() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    switch (_currentIndex) {
      case 1: // Assignments
        return FloatingActionButton(
          backgroundColor: subjectColor,
          child: Icon(Icons.add),
          onPressed: () {
            // Add new assignment
          },
        );
      case 2: // Queries
        return FloatingActionButton(
          backgroundColor: subjectColor,
          child: Icon(Icons.add_comment),
          onPressed: () {
            // Add new query
          },
        );
      case 3: // Results
        return FloatingActionButton(
          backgroundColor: subjectColor,
          child: Icon(Icons.download),
          onPressed: () {
            // Export results
          },
        );
      case 4: // Attendance
        return FloatingActionButton(
          backgroundColor: subjectColor,
          child: Icon(Icons.date_range),
          onPressed: () {
            // View attendance calendar
          },
        );

      default:
        return null;
    }

  }
  Widget _buildMainFAB() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    return FloatingActionButton(
      shape: const CircleBorder(), // ensure perfectly rounded FAB
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
  Widget _buildMenuButton(String title, IconData icon, int index, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
            _currentIndex == index
                ? color.withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
            _currentIndex == index
                ? color
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color:
            _currentIndex == index
                ? color
                : (isDarkMode ? Colors.white : Colors.black87),
            fontWeight:
            _currentIndex == index ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _navigateToScreen(index),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 24,
        tileColor:
        _currentIndex == index
            ? color.withOpacity(0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }


  // ... [Keep all other existing helper methods like _buildMenuButton, _buildMainFAB, etc.]

  Widget _buildQuickStatsPanel() {
    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;

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
                '${subjectStats['attendance_rate']?.toStringAsFixed(0) ?? '0'}%',
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

    return Column(
      children: assignments.take(2).map((assignment) {
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
                    value: (assignment['submitted_count'] ?? 0) /
                        (subjectStats['student_count'] ?? 1),
                    backgroundColor: subjectColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                  ),
                  Text(
                    '${assignment['submitted_count'] ?? 0}/${subjectStats['student_count'] ?? 0} submitted',
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
                query['question']?.length > 30
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
    final attendanceRate = subjectStats['attendance_rate'] ?? 0;

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
              return _buildMiniAttendanceStat(
                _getDayName(day['day']),
                '${day['attendance_rate']?.toStringAsFixed(0) ?? '0'}%',
                day['attendance_rate'] >= 90 ? Icons.check : Icons.warning,
                day['attendance_rate'] >= 90 ? Colors.green : Colors.orange,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
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
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(String? day) {
    if (day == null) return 'Day';
    return day.substring(0, 3); // Returns first 3 letters (Mon, Tue, etc.)
  }

// ... [Keep all other existing methods]
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
                    color:
                    widget.subject['color'] ??
                        Theme.of(context).primaryColor,
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

  Widget _buildAnnouncementsScreen() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Announcements'),
        backgroundColor: subjectColor,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildAnnouncementCard(
            title: 'Exam Schedule Posted',
            content: 'Final exams will begin next week on Monday',
            time: '2h ago',
            icon: Icons.announcement,
            color: Colors.blue,
          ),
          SizedBox(height: 12),
          _buildAnnouncementCard(
            title: 'Assignment 3 Graded',
            content: 'Grades for the last assignment are now available',
            time: '1d ago',
            icon: Icons.assignment,
            color: Colors.green,
          ),
          SizedBox(height: 12),
          _buildAnnouncementCard(
            title: 'Course Materials Updated',
            content: 'New reading materials have been uploaded for Chapter 4',
            time: '3d ago',
            icon: Icons.library_books,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
  Widget _buildAnnouncementCard({
    required String title,
    required String content,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(content, style: GoogleFonts.poppins()),
          ],
        ),
      ),
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