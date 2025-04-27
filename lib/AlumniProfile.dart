import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alumni Profile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AlumniProfileScreen(),
    );
  }
}

class Alumni {
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String university;
  final String degree;
  final String graduationYear;
  final String gpa;
  final String standing;
  final String thesis;

  Alumni({
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.university,
    required this.degree,
    required this.graduationYear,
    required this.gpa,
    required this.standing,
    required this.thesis,
  });
}

class AlumniProfileScreen extends StatelessWidget {
  final Alumni alumni = Alumni(
    name: "John Doe",
    email: "johndoe@example.com",
    phone: "+1 (555) 123-4567",
    photoUrl: "https://randomuser.me/api/portraits/men/42.jpg",
    university: "Massachusetts Institute of Technology",
    degree: "Bachelor of Science in Computer Science",
    graduationYear: "2022",
    gpa: "3.85 / 4.0",
    standing: "Summa Cum Laude",
    thesis: "Machine Learning Applications in Educational Technology",
  );

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
              title: Text('ALUMNI PROFILE',
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
                              image: NetworkImage(alumni.photoUrl),
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
                      alumni.name,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
                        _buildContactItem(
                          Icons.email,
                          alumni.email,
                          onTap: () => _launchEmail(alumni.email),
                        ),
                        Divider(color: Colors.white24, height: 30),
                        _buildContactItem(
                          Icons.phone,
                          alumni.phone,
                          onTap: () => _launchPhone(alumni.phone),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // University Information Card
                  _buildSectionCard(
                    title: 'UNIVERSITY TRACKING',
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.school, alumni.university),
                        Divider(color: Colors.white24, height: 30),
                        _buildInfoRow(Icons.workspaces_outline, alumni.degree),
                        Divider(color: Colors.white24, height: 30),
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Class of ${alumni.graduationYear}",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // Final Results Card
                  _buildSectionCard(
                    title: 'FINAL RESULTS',
                    child: Column(
                      children: [
                        _buildResultRow("GPA", alumni.gpa),
                        Divider(color: Colors.white24, height: 20),
                        _buildResultRow("Standing", alumni.standing),
                        Divider(color: Colors.white24, height: 20),
                        _buildResultRow("Thesis", alumni.thesis),
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
        onPressed: () {
          // Edit profile functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Edit profile functionality")),
          );
        },
        backgroundColor: Colors.tealAccent,
        child: Icon(Icons.edit, color: Colors.black),
        elevation: 8,
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 24),
          SizedBox(width: 15),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 24),
        SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No email app found")),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunch(phoneLaunchUri.toString())) {
      await launch(phoneLaunchUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No phone app found")),
      );
    }
  }
}