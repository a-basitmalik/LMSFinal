import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Profile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TeacherProfileScreen(),
    );
  }
}

class TeacherProfileScreen extends StatelessWidget {
  final List<String> subjects = [
    'Mathematics - Grade 10',
    'Physics - Grade 11',
    'Advanced Calculus - Grade 12'
  ];

  final List<Map<String, dynamic>> feedbacks = [
    {
      'student': 'Alex Johnson',
      'comment': 'Excellent teaching methodology, really helped me understand complex concepts.',
      'rating': 5,
      'date': '15 Mar 2023'
    },
    {
      'student': 'Sarah Williams',
      'comment': 'Very patient and explains things clearly. Highly recommended!',
      'rating': 4,
      'date': '28 Feb 2023'
    },
    {
      'student': 'Michael Brown',
      'comment': 'Makes learning fun and engaging. Always available for extra help.',
      'rating': 5,
      'date': '10 Feb 2023'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('PROFILE',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  )),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1579547945413-497e1b99dac0?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 50),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                  'https://randomuser.me/api/portraits/men/42.jpg'),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.tealAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Dr. Robert Chen',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: Text(
                      'Senior Mathematics Professor',
                      style: GoogleFonts.raleway(
                        color: Colors.tealAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Contact Information Card
                  _buildSectionCard(
                    title: 'CONTACT INFORMATION',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem(Icons.email, 'robert.chen@university.edu'),
                        Divider(color: Colors.white24, height: 30),
                        _buildContactItem(Icons.phone, '+1 (555) 123-4567'),
                        Divider(color: Colors.white24, height: 30),
                        _buildContactItem(Icons.location_on, 'Faculty Building, Room 304'),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // Attendance Reports
                  Text(
                    'ATTENDANCE REPORTS',
                    style: GoogleFonts.orbitron(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Select Date Range',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.tealAccent),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: Icon(Icons.calendar_today, color: Colors.tealAccent),
                          ),
                          style: TextStyle(color: Colors.white),
                          readOnly: true,
                        ),
                        SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.tealAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          child: Text(
                            'EXPORT REPORT',
                            style: GoogleFonts.orbitron(
                              color: Colors.tealAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // Subjects Taught
                  Text(
                    'SUBJECTS TAUGHT',
                    style: GoogleFonts.orbitron(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        ...subjects.map((subject) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: Colors.tealAccent, size: 20),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  subject,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // Performance and Feedback
                  Text(
                    'PERFORMANCE & FEEDBACK',
                    style: GoogleFonts.orbitron(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 30),
                              SizedBox(width: 10),
                              Text(
                                '4.8/5.0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ...feedbacks.map((feedback) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    feedback['student'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    feedback['date'],
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: List.generate(5, (index) => Icon(
                                  index < feedback['rating'] ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                              ),
                              SizedBox(height: 8),
                              Text(
                                feedback['comment'],
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 10),
                              Divider(color: Colors.white24),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.tealAccent,
        child: Icon(Icons.edit, color: Colors.black),
        elevation: 8,
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 24),
        SizedBox(width: 15),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: Colors.tealAccent,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 15),
          ],
          child,
        ],
      ),
    );
  }
}