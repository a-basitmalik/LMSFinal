import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/AnnouncementsScreen.dart';
import 'package:newapp/Teacher/SubjectDetails.dart';
import 'package:newapp/Teacher/Subjects.dart';
import 'package:newapp/Teacher/FullSchedule.dart';
import 'package:newapp/Teacher/TeacherProfile.dart';

class TeacherMain extends StatelessWidget {
  final String userId;

  const TeacherMain({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF4361EE),
          secondary: Color(0xFF7209B7),
          tertiary: Color(0xFF3A0CA3),
          surface: Colors.white,
          background: Color(0xFFF8F9FF),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TeacherHomeScreen(userId: userId),
    );
  }
}

class TeacherHomeScreen extends StatefulWidget {
  final String userId;

  const TeacherHomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  late Map<String, dynamic> teacherProfile = {};
  late List<dynamic> todaysSchedule = [];
  late List<dynamic> subjects = [];
  int studentCount = 0;
  int classCount = 0;
  int taskCount = 0;

  // API Endpoints - Replace with your actual Flask server URL
  final String baseUrl = 'http://193.203.162.232:5050/Teacher/api';

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
    _fetchTodaysSchedule();
    _fetchSubjects();
    _fetchStats();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          teacherProfile = json.decode(response.body);
        });
      } else {
        setState(() {
          teacherProfile = {
            'name': 'NA',
            'email': 'NA',
            'department': 'NA',
          };
        });
      }
    } catch (e) {
      print('Error fetching teacher data: $e');
      setState(() {
        teacherProfile = {
          'name': 'NA',
          'email': 'NA',
          'department': 'NA',
        };
      });
    }
  }

  Future<void> _fetchTodaysSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.userId}/schedule/today'),
      );
      if (response.statusCode == 200) {
        setState(() {
          todaysSchedule = json.decode(response.body);
        });
      } else {
        setState(() {
          todaysSchedule = [];
        });
      }
    } catch (e) {
      print('Error fetching today\'s schedule: $e');
      setState(() {
        todaysSchedule = [];
      });
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.userId}/subjects'),
      );
      if (response.statusCode == 200) {
        setState(() {
          subjects = json.decode(response.body);
        });
      } else {
        setState(() {
          subjects = [];
        });
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        subjects = [];
      });
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.userId}/stats'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          studentCount = data['student_count'] ?? 0;
          classCount = data['class_count'] ?? 0;
          taskCount = data['task_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Teacher Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(context),
            SizedBox(height: 24),

            // Quick Stats Cards
            _buildQuickStatsRow(),
            SizedBox(height: 24),

            // Coming Soon Section (replaced announcements)
            _buildSectionHeader(context, 'Coming Soon', ''),
            SizedBox(height: 12),
            _buildComingSoonPanel(context),
            SizedBox(height: 24),

            // Today's Schedule
            _buildSectionHeader(
              context,
              "Today's Schedule",
              todaysSchedule.isNotEmpty ? 'View All' : '',
              onPressed: todaysSchedule.isNotEmpty ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScheduleScreen(
                      teacherId: widget.userId,
                      schedule: List<Map<String, dynamic>>.from(todaysSchedule),
                      subject: {},
                    ),
                  ),
                );
              } : null,
            ),
            SizedBox(height: 12),
            todaysSchedule.isNotEmpty
                ? _buildScheduleList(context)
                : _buildNoSchedulePlaceholder(),
            SizedBox(height: 24),

            _buildSectionHeader(context, 'Your Subjects', ''),
            SizedBox(height: 12),
            subjects.isNotEmpty
                ? _buildSubjectsGrid()
                : _buildNoSubjectsPlaceholder(),
            SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.person, size: 32, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  teacherProfile['name'] ?? 'NA',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  teacherProfile['department'] ?? 'NA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Classes',
            value: classCount.toString(),
            icon: Icons.class_,
            color: Color(0xFF4361EE),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Students',
            value: studentCount.toString(),
            icon: Icons.people_alt,
            color: Color(0xFF7209B7),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Tasks',
            value: taskCount.toString(),
            icon: Icons.assignment,
            color: Color(0xFF4CC9F0),
          ),
        ),
      ],
    );
  }


  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context,
      String title,
      String actionText, {
        VoidCallback? onPressed,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onPressed,
            child: Text(
              actionText,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComingSoonPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'New features coming soon!',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: todaysSchedule.map((schedule) {
          final subjectColor = _getColorForSubject(schedule['subject_id'] ?? 0);
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.schedule, color: subjectColor),
                ),
                title: Text(
                  schedule['subject_name'] ?? 'NA',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  schedule['year'] != null ? 'Grade ${schedule['year']}' : 'NA',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      schedule['time'] ?? 'NA',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                      ),
                    ),
                    Text(
                      schedule['room'] ?? 'NA',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (schedule != todaysSchedule.last)
                Divider(height: 1, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoSchedulePlaceholder() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'No classes scheduled for today',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final subjectColor = _getColorForSubject(subject['subject_id'] ?? index);
        final icon = _getIconForSubject(subject['subject_name'] ?? '');

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                subjectColor.withOpacity(0.9),
                subjectColor.withOpacity(0.7),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectDashboardScreen(subject: subject,teacherId: widget.userId,),
                  ),
                );
              },
              splashColor: Colors.white.withOpacity(0.2),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['subject_name'] ?? 'NA',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          subject['year'] != null ? 'Grade ${subject['year']}' : 'NA',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSubjectsPlaceholder() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'No subjects assigned',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          elevation: 10,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });

            switch (index) {
              case 0: // Home tab
                if (ModalRoute.of(context)?.settings.name != '/') {
                  Navigator.pushReplacementNamed(context, '/');
                }
                break;

              case 1: // Subjects tab
                Navigator.push(
                  context,
                  MaterialPageRoute( builder: (context) => SubjectsScreen(teacherId: widget.userId)),
                );
                break;

              case 2: // Schedule tab
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScheduleScreen(
                      teacherId: widget.userId,
                      schedule: List<Map<String, dynamic>>.from(todaysSchedule),
                      subject: {},
                    ),
                  ),
                );
                break;

              case 3: // Profile tab
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_outlined),
              ),
              label: 'Home',
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Subjects',
              activeIcon: Icon(Icons.menu_book),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Schedule',
              activeIcon: Icon(Icons.calendar_today),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
              activeIcon: Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForSubject(int subjectId) {
    final colors = [
      Color(0xFF4361EE),
      Color(0xFF7209B7),
      Color(0xFF4CC9F0),
      Color(0xFF3A0CA3),
      Color(0xFF4895EF),
      Color(0xFF560BAD),
    ];
    return colors[subjectId % colors.length];
  }

  IconData _getIconForSubject(String subjectName) {
    if (subjectName.toLowerCase().contains('math')) {
      return Icons.calculate;
    } else if (subjectName.toLowerCase().contains('physics')) {
      return Icons.science;
    } else if (subjectName.toLowerCase().contains('computer')) {
      return Icons.computer;
    } else if (subjectName.toLowerCase().contains('english')) {
      return Icons.language;
    } else if (subjectName.toLowerCase().contains('history')) {
      return Icons.history_edu;
    } else {
      return Icons.school;
    }
  }
}