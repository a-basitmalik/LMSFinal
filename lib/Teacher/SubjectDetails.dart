import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SubjectAssignments.dart';
import 'SubjectQueries.dart';
import 'SubjectResults.dart';
import 'SubjectAttendance.dart';
import 'SubjectChat.dart';
import 'SubjectAnnouncementsScreen.dart';
import 'dart:ui';

class SubjectDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectDashboardScreen({super.key, required this.subject});

  @override
  _SubjectDashboardScreenState createState() => _SubjectDashboardScreenState();
}

class _SubjectDashboardScreenState extends State<SubjectDashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _screens = []; // Initialize empty list
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
      SubjectChatScreen(subject: widget.subject),
    ];
  }

  Widget _buildOverviewScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStatsPanel(),
          SizedBox(height: 24),
          _buildSectionPreview(
            title: 'Recent Announcements',
            onViewAll:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SubjectAnnouncementsScreen(subject: widget.subject),
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
          children:
              menuItems.map((item) {
                return GestureDetector(
                  onTap: () {
                    _navigateToScreen(item['index']);
                  },
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

  Widget _buildQuickStatsPanel() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              _buildStatItem('45', 'Students', Icons.people),
              _buildStatItem('5', 'Assignments', Icons.assignment),
              _buildStatItem('92%', 'Attendance', Icons.calendar_today),
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

  Widget _buildAnnouncementsPreview() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(Icons.announcement, color: Colors.blue),
          ),
          title: Text(
            'Exam Schedule Posted',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Final exams will begin next week on Monday',
            style: GoogleFonts.poppins(),
          ),
          trailing: Text(
            '2h ago',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
        ),
        Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[50],
            child: Icon(Icons.assignment, color: Colors.green),
          ),
          title: Text(
            'Assignment 3 Graded',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Grades for the last assignment are now available',
            style: GoogleFonts.poppins(),
          ),
          trailing: Text(
            '1d ago',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsPreview() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange[50],
            child: Icon(Icons.assignment, color: Colors.orange),
          ),
          title: Text(
            'Linear Algebra Homework',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Due: Jun 15, 2023', style: GoogleFonts.poppins()),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: subjectColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
              ),
              Text('32/45 submitted', style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
        Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple[50],
            child: Icon(Icons.assignment, color: Colors.purple),
          ),
          title: Text(
            'Midterm Project',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Due: Jun 30, 2023', style: GoogleFonts.poppins()),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.3,
                backgroundColor: subjectColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
              ),
              Text('12/45 submitted', style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQueriesPreview() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red[50],
            child: Icon(Icons.question_answer, color: Colors.red),
          ),
          title: Text(
            'Alice Johnson',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Clarification on problem 3 in homework',
            style: GoogleFonts.poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Chip(
            label: Text(
              'Pending',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        ),
        Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[50],
            child: Icon(Icons.question_answer, color: Colors.green),
          ),
          title: Text(
            'Bob Smith',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Extension request for assignment',
            style: GoogleFonts.poppins(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Chip(
            label: Text(
              'Answered',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendancePreview() {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

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
                '92%',
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
            value: 0.92,
            backgroundColor: subjectColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniAttendanceStat(
                'Mon',
                '100%',
                Icons.check,
                Colors.green,
              ),
              _buildMiniAttendanceStat('Tue', '95%', Icons.check, Colors.green),
              _buildMiniAttendanceStat('Wed', '89%', Icons.check, Colors.green),
              _buildMiniAttendanceStat('Thu', '92%', Icons.check, Colors.green),
              _buildMiniAttendanceStat(
                'Fri',
                '85%',
                Icons.warning,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
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
}
