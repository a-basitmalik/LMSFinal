import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
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
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: Stack(
        children: [
          CustomPaint(
            painter: _ParticlePainter(animation: _animation, colors: colors),
            size: Size.infinite,
          ),
          SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: AdminColors.primaryAccent))
                : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('TEACHER PROFILE', style: AdminTextStyles.portalTitle),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AdminColors.primaryAccent.withOpacity(0.1),
                                AdminColors.primaryBackground,
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
                                      color: AdminColors.primaryAccent.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AdminColors.primaryAccent,
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
                          style: AdminTextStyles.campusName,
                        ),
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Faculty Member',
                          style: AdminTextStyles.accentText(AdminColors.primaryAccent),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Contact Information
                      _buildSectionHeader(
                        icon: Icons.contact_mail_rounded,
                        title: 'CONTACT INFORMATION',
                        colors: colors,
                        textStyles: textStyles,
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: AdminColors.glassDecoration(),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildContactItem(
                                Icons.email,
                                teacherData?['email'] ?? 'Not available',
                                colors: colors,
                              ),
                              Divider(color: AdminColors.cardBorder, height: 30),
                              _buildContactItem(
                                Icons.phone,
                                teacherData?['phone'] ?? 'Not available',
                                colors: colors,
                              ),
                              Divider(color: AdminColors.cardBorder, height: 30),
                              _buildContactItem(
                                Icons.location_on,
                                'Faculty Building',
                                colors: colors,
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
                        iconColor: AdminColors.studentColor,
                        colors: colors,
                        textStyles: textStyles,
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: AdminColors.glassDecoration(
                          borderColor: AdminColors.studentColor.withOpacity(0.3),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: subjects.isEmpty
                                ? [
                              Text(
                                'No subjects assigned',
                                style: AdminTextStyles.cardSubtitle,
                              )
                            ]
                                : subjects.map((subject) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.school,
                                      color: AdminColors.studentColor,
                                      size: 20),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject['subject_name'] ?? 'Unknown',
                                          style: AdminTextStyles.cardTitle,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${subject['day'] ?? ''} ${subject['time'] != null ? 'at ${subject['time']}' : ''}',
                                          style: AdminTextStyles.cardSubtitle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      color: AdminColors.disabledText,
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
                        iconColor: AdminColors.attendanceColor,
                        colors: colors,
                        textStyles: textStyles,
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: AdminColors.glassDecoration(
                          borderColor: AdminColors.attendanceColor.withOpacity(0.3),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Select Date Range',
                                  labelStyle: AdminTextStyles.cardSubtitle,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AdminColors.attendanceColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today,
                                      color: AdminColors.attendanceColor),
                                ),
                                style: AdminTextStyles.cardTitle,
                                readOnly: true,
                              ),
                              SizedBox(height: 20),
                              _buildAnimatedButton(
                                icon: Icons.download,
                                label: 'EXPORT REPORT',
                                color: AdminColors.attendanceColor,
                                onTap: () {},
                                colors: colors,
                                textStyles: textStyles,
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
    required AdminColors colors,
    required AdminTextStyles textStyles,
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
                  style: AdminTextStyles.sectionHeader,
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

  Widget _buildContactItem(IconData icon, String text, {required AdminColors colors}) {
    return Row(
      children: [
        Icon(icon, color: AdminColors.primaryAccent, size: 24),
        SizedBox(width: 15),
        Text(
          text,
          style: TextStyle(color: AdminColors.primaryText, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required AdminColors colors,
    required AdminTextStyles textStyles,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: color.toGlassDecoration(borderRadius: 12),
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
                  style: AdminTextStyles.primaryButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random random = Random(42);
  final AdminColors colors;

  _ParticlePainter({required this.animation, required this.colors});

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