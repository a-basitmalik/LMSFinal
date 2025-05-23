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
  // Static data - will be replaced by API calls
  List<Map<String, dynamic>> announcements = [
    {
      'title': 'Staff Meeting Tomorrow',
      'content': 'All teaching staff required at 3:00 PM in Conference Room A',
      'time': '10:30 AM',
      'isNew': true,
      'icon': Icons.people,
      'color': Color(0xFF7209B7),
    },
    {
      'title': 'Curriculum Update',
      'content': 'New mathematics curriculum guidelines available',
      'time': 'Yesterday',
      'isNew': false,
      'icon': Icons.school,
      'color': Color(0xFF4361EE),
    },
  ];

  List<Map<String, dynamic>> todaysSchedule = [
    {
      'subject': 'Mathematics',
      'time': '8:00 - 9:30 AM',
      'class': 'Grade 10-A',
      'room': 'Room 205',
      'color': Color(0xFF4361EE),
    },
    {
      'subject': 'Physics',
      'time': '10:00 - 11:30 AM',
      'class': 'Grade 11-B',
      'room': 'Lab 3',
      'color': Color(0xFF7209B7),
    },
  ];

  List<Map<String, dynamic>> subjects = [
    {
      'name': 'Mathematics',
      'code': 'MATH101',
      'color': Color(0xFF4361EE),
      'icon': Icons.calculate,
    },
    {
      'name': 'Physics',
      'code': 'PHYS202',
      'color': Color(0xFF7209B7),
      'icon': Icons.science,
    },
    {
      'name': 'Computer Science',
      'code': 'COMP110',
      'color': Color(0xFF4CC9F0),
      'icon': Icons.computer,
    },
  ];

  // Teacher profile data
  Map<String, dynamic> teacherProfile = {
    'name': 'Dr. Asma Ali',
    'email': 'robert.chen@university.edu',
    'department': 'Mathematics, Physics & Computer ',
    'avatar': 'assets/teacher_avatar.png', // Replace with actual asset
  };

  // API Endpoints - Replace with your Flask server URLs
  final String baseUrl = 'http://your-flask-server.com/api';
  final String announcementsEndpoint = '/announcements';
  final String scheduleEndpoint = '/schedule';
  final String subjectsEndpoint = '/subjects';
  final String profileEndpoint = '/profile';

  @override
  void initState() {
    super.initState();
    // Uncomment these when your backend is ready
    // _fetchAnnouncements();
    // _fetchSchedule();
    // _fetchSubjects();
    // _fetchProfile();
  }

  // API Call Methods
  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$announcementsEndpoint'),
      );
      if (response.statusCode == 200) {
        setState(() {
          announcements = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      // You might want to show an error message to the user
    }
  }

  Future<void> _fetchSchedule() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$scheduleEndpoint'));
      if (response.statusCode == 200) {
        setState(() {
          todaysSchedule = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      print('Error fetching schedule: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$subjectsEndpoint'));
      if (response.statusCode == 200) {
        setState(() {
          subjects = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$profileEndpoint'));
      if (response.statusCode == 200) {
        setState(() {
          teacherProfile = Map<String, dynamic>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
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

            // Announcements Section
            _buildSectionHeader(
              context,
              'Announcements',
              'View All',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                        AnnouncementScreen(announcements: announcements),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildAnnouncementsPanel(context),
            SizedBox(height: 24),

            // Today's Schedule
            _buildSectionHeader(
              context,
              "Today's Schedule",
              'View All',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScheduleScreen(
                      teacherId: '12345',
                      schedule: todaysSchedule, subject: {},
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildScheduleList(context),
            SizedBox(height: 24),

            _buildSectionHeader(context, 'Your Subjects', ''),
            SizedBox(height: 12),
            _buildSubjectsGrid(),
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
                  teacherProfile['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  teacherProfile['department'],
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
            value: '12',
            icon: Icons.class_,
            color: Color(0xFF4361EE),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Students',
            value: '240',
            icon: Icons.people_alt,
            color: Color(0xFF7209B7),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Tasks',
            value: '5',
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

  Widget _buildAnnouncementsPanel(BuildContext context) {
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
        children:
        announcements
            .map(
              (announcement) => Column(
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
                    color: announcement['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    announcement['icon'],
                    color: announcement['color'],
                  ),
                ),
                title: Text(
                  announcement['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  announcement['content'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      announcement['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (announcement['isNew'])
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (announcement != announcements.last)
                Divider(height: 1, indent: 16),
            ],
          ),
        )
            .toList(),
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
        children:
        todaysSchedule
            .map(
              (schedule) => Column(
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
                    color: schedule['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.schedule, color: schedule['color']),
                ),
                title: Text(
                  schedule['subject'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  schedule['class'],
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      schedule['time'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: schedule['color'],
                      ),
                    ),
                    Text(
                      schedule['room'],
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
          ),
        )
            .toList(),
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                subject['color'].withOpacity(0.9),
                subject['color'].withOpacity(0.7),
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
                    builder:
                        (context) => SubjectDashboardScreen(subject: subject),
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
                        subject['icon'],
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['name'],
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
                          subject['code'],
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

            // Handle navigation based on tab index
            switch (index) {
              case 0: // Home tab
              // If already on home, do nothing
                if (ModalRoute.of(context)?.settings.name != '/') {
                  Navigator.pushReplacementNamed(context, '/');
                }
                break;

              case 1: // Subjects tab
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubjectsScreen()),
                );
                break;

              case 2: // Schedule tab
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScheduleScreen(
                      teacherId: '12345', // Replace with actual teacher ID
                      schedule: todaysSchedule, subject: {}, // Pass your schedule data
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
}
