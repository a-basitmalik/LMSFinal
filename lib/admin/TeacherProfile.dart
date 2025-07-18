import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class TeacherProfileScreen extends StatefulWidget {
  final int teacherId;

  const TeacherProfileScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  _TeacherProfileScreenState createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<String, dynamic>? teacherData;
  List<dynamic> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _fetchTeacherData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchTeacherData() async {
    try {
      // Fetch teacher details
      final teacherResponse = await http.get(
        Uri.parse('http://193.203.162.232:5050/teacher/api/teachers/${widget.teacherId}'),
      );

      if (teacherResponse.statusCode == 200) {
        setState(() {
          teacherData = json.decode(teacherResponse.body);
        });
      }

      // Fetch subjects taught by this teacher
      final subjectsResponse = await http.get(
        Uri.parse('http://193.203.162.232:5050/teacher/api/subjects?teacherid=${widget.teacherId}'),
      );

      if (subjectsResponse.statusCode == 200) {
        setState(() {
          subjects = json.decode(subjectsResponse.body);
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomPaint(
            painter: _ParticlePainter(animation: _animation),
            size: Size.infinite,
          ),
          SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('TEACHER PROFILE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        )),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.cyanAccent.withOpacity(0.1),
                                Colors.black,
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
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                        'https://randomuser.me/api/portraits/men/${widget.teacherId}.jpg'),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.cyanAccent,
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
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          teacherData?['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Faculty Member',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Contact Information
                      _buildSectionHeader(
                        icon: Icons.contact_mail_rounded,
                        title: 'CONTACT INFORMATION',
                      ),
                      SizedBox(height: 16),
                      GlassCard(
                        borderRadius: 16,
                        borderColor: Colors.cyanAccent.withOpacity(0.3),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildContactItem(
                                Icons.email,
                                teacherData?['email'] ?? 'Not available',
                              ),
                              Divider(color: Colors.white24, height: 30),
                              _buildContactItem(
                                Icons.phone,
                                teacherData?['phone'] ?? 'Not available',
                              ),
                              Divider(color: Colors.white24, height: 30),
                              _buildContactItem(
                                Icons.location_on,
                                'Faculty Building',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Subjects Taught
                      _buildSectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'SUBJECTS TAUGHT',
                        iconColor: Colors.blueAccent,
                      ),
                      SizedBox(height: 16),
                      GlassCard(
                        borderRadius: 16,
                        borderColor: Colors.blueAccent.withOpacity(0.3),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: subjects.isEmpty
                                ? [
                              Text(
                                'No subjects assigned',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              )
                            ]
                                : subjects.map((subject) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.school,
                                      color: Colors.blueAccent,
                                      size: 20),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject['subject_name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${subject['day'] ?? ''} ${subject['time'] != null ? 'at ${subject['time']}' : ''}',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.white54,
                                      size: 16),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Attendance Reports
                      _buildSectionHeader(
                        icon: Icons.fingerprint_outlined,
                        title: 'ATTENDANCE REPORTS',
                        iconColor: Colors.greenAccent,
                      ),
                      SizedBox(height: 16),
                      GlassCard(
                        borderRadius: 16,
                        borderColor: Colors.greenAccent.withOpacity(0.3),
                        child: Padding(
                          padding: EdgeInsets.all(16),
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
                                    borderSide: BorderSide(color: Colors.greenAccent),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today,
                                      color: Colors.greenAccent),
                                ),
                                style: TextStyle(color: Colors.white),
                                readOnly: true,
                              ),
                              SizedBox(height: 20),
                              _buildAnimatedButton(
                                icon: Icons.download,
                                label: 'EXPORT REPORT',
                                color: Colors.greenAccent,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color iconColor = Colors.cyanAccent,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: iconColor.withOpacity(0.7),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        SizedBox(width: 15),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
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
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random random = Random(42);

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    const particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 3;
      final hue = 180 + random.nextDouble() * 60; // Cyan to blue range
      final opacity = 0.1 + random.nextDouble() * 0.2;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + 0.4 * animation.value),
        paint..color = HSVColor.fromAHSV(opacity * animation.value, hue, 0.8, 1).toColor(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}