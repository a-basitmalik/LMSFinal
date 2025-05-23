import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final int campusID;
  final String campusName;

  const AdminDashboard({required this.campusID, required this.campusName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> managementOptions = [
      {
        'title': 'Student Management',
        'icon': Icons.school_outlined,
        'route': '/studentList',
        'gradient': [Colors.blueAccent, Colors.indigoAccent]
      },
      {
        'title': 'Faculty Management',
        'icon': Icons.person_outline,
        'route': '/teacherList',
        'gradient': [Colors.tealAccent, Colors.cyan]
      },
      {
        'title': 'Curriculum',
        'icon': Icons.menu_book_outlined,
        'route': '/subjects',
        'gradient': [Colors.purpleAccent, Colors.deepPurple]
      },
      {
        'title': 'Attendance',
        'icon': Icons.fingerprint_outlined,
        'route': '/attendance',
        'gradient': [Colors.orangeAccent, Colors.deepOrange]
      },
      {
        'title': 'Results',
        'icon': Icons.assessment_outlined,
        'route': '/result',
        'gradient': [Colors.greenAccent, Colors.teal]
      },
      {
        'title': 'Finance',
        'icon': Icons.monetization_on_outlined,
        'route': '/fees',
        'gradient': [Colors.amber, Colors.orange]
      },
      {
        'title': 'Alumni Network',
        'icon': Icons.people_alt_outlined,
        'route': '/alumniList',
        'gradient': [Colors.pinkAccent, Colors.purple]
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
        'route': '/announcements',
        'gradient': [Colors.lightBlueAccent, Colors.blue]
      },
      {
        'title': 'Calendar',
        'icon': Icons.date_range_outlined,
        'route': '/calendar',
        'gradient': [Colors.lightGreenAccent, Colors.green]
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Futuristic Header
              Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: Colors.blueAccent, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        campusName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Grid View
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: managementOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildFuturisticCard(context, managementOptions[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildFuturisticCard(BuildContext context, Map<String, dynamic> option) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, option['route'],
            arguments: {'campusID': campusID});
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: option['gradient'],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: option['gradient'][1].withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                option['icon'],
                size: 120,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      option['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}