import 'dart:math';
import 'package:flutter/material.dart';
import 'AdminRoutes.dart';

class AdminDashboard extends StatefulWidget {
  final int campusID;
  final String campusName;

  const AdminDashboard({
    required this.campusID,
    required this.campusName,
    Key? key,
  }) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AdminRoutes.generateRoute,
      home: _AdminDashboardContent(
        campusID: widget.campusID,
        campusName: widget.campusName,
        animation: _animation,
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  final int campusID;
  final String campusName;
  final Animation<double> animation;

  const _AdminDashboardContent({
    required this.campusID,
    required this.campusName,
    required this.animation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shortcutOptions = [
      {
        'title': 'Student',
        'icon': Icons.school_outlined,
        'route': '/studentList',
        'color': Colors.blueAccent,
      },
      {
        'title': 'Faculty',
        'icon': Icons.person_outlined,
        'route': '/teacherList',
        'color': Colors.purpleAccent,
      },
      {
        'title': 'Attendance',
        'icon': Icons.fingerprint_outlined,
        'route': '/attendance',
        'color': Colors.greenAccent,
      },
      {
        'title': 'Finance',
        'icon': Icons.monetization_on_outlined,
        'route': '/fees',
        'color': Colors.orangeAccent,
      },
      {
        'title': 'Alumni',
        'icon': Icons.people_alt_outlined,
        'route': '/alumniList',
        'color': Colors.redAccent,
      },
      {
        'title': 'Calendar',
        'icon': Icons.date_range_outlined,
        'route': '/calendar',
        'color': Colors.tealAccent,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomPaint(
            painter: _ParticlePainter(animation: animation),
            size: Size.infinite,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedCircularProgress(
                          value: 0.75,
                          color: Colors.cyanAccent,
                          animation: animation,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_outlined,
                                      color: Colors.cyanAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ADMIN PORTAL',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                campusName.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.bolt_rounded,
                      title: 'QUICK ACCESS',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        children: shortcutOptions.map((option) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildAnimatedQuickAccessCard(context, option),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.campaign_outlined,
                      title: 'ANNOUNCEMENTS',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/announcements',
                          arguments: {
                            'campusID': campusID,
                            'campusName': campusName,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      borderRadius: 20,
                      borderColor: Colors.cyanAccent.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildAnimatedButton(
                              icon: Icons.add_rounded,
                              label: 'POST NEW',
                              color: Colors.cyanAccent,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/announcements',
                                  arguments: {
                                    'campusID': campusID,
                                    'campusName': campusName,
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.menu_book_rounded,
                      title: 'CURRICULUM',
                      iconColor: Colors.blueAccent,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/subjects',
                          arguments: {
                            'campusID': campusID,
                            'campusName': campusName,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedCurriculumOption(
                            icon: Icons.medical_services,
                            label: 'Pre Medical',
                            color: Colors.blueAccent,
                            onTap: () => _navigateToCurriculum(context, 'Pre Medical'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnimatedCurriculumOption(
                            icon: Icons.computer,
                            label: 'Computer',
                            color: Colors.blueAccent,
                            onTap: () => _navigateToCurriculum(context, 'Computer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.analytics_rounded,
                      title: 'REPORT DOWNLOAD',
                      iconColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/downloadReports',
                          arguments: {
                            'campusID': campusID,
                            'campusName': campusName,
                            'initialTab': 0,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          _buildAnimatedReportOption(
                            icon: Icons.assignment,
                            label: 'Subject',
                            subLabel: 'Report',
                            color: Colors.redAccent,
                            onTap: () => _navigateToReports(context, 0),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.assessment,
                            label: 'Assessment',
                            subLabel: 'Report',
                            color: Colors.redAccent,
                            onTap: () => _navigateToReports(context, 1),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.quiz,
                            label: 'Monthly',
                            subLabel: '+ Quizzes',
                            color: Colors.redAccent,
                            onTap: () => _navigateToReports(context, 2),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.library_books,
                            label: 'All',
                            subLabel: 'Subjects',
                            color: Colors.redAccent,
                            onTap: () => _navigateToReports(context, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.8),
                Colors.blueAccent.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
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
                const SizedBox(width: 8),
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

  Widget _buildAnimatedQuickAccessCard(
      BuildContext context, Map<String, dynamic> option) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 100,
      child: GlassCard(
        borderRadius: 16,
        borderColor: option['color'].withOpacity(0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              option['route'],
              arguments: {
                'campusID': campusID,
                'campusName': campusName,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        option['color'].withOpacity(0.3),
                        option['color'].withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: option['color'].withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    option['icon'],
                    color: option['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  option['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                const SizedBox(width: 8),
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

  Widget _buildAnimatedCurriculumOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GlassCard(
        borderRadius: 12,
        borderColor: color.withOpacity(0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildAnimatedReportOption({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 100,
      child: GlassCard(
        borderRadius: 12,
        borderColor: color.withOpacity(0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToReports(BuildContext context, int tabIndex) {
    Navigator.pushNamed(
      context,
      '/downloadReports',
      arguments: {
        'campusID': campusID,
        'campusName': campusName,
        'initialTab': tabIndex,
      },
    );
  }

  void _navigateToCurriculum(BuildContext context, String section) {
    Navigator.pushNamed(
      context,
      '/subjects',
      arguments: {
        'campusID': campusID,
        'campusName': campusName,
        'initialSection': section,
      },
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

class AnimatedCircularProgress extends StatelessWidget {
  final double value;
  final Color color;
  final Animation<double> animation;

  const AnimatedCircularProgress({
    Key? key,
    required this.value,
    required this.color,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 * animation.value),
                blurRadius: 10 * animation.value,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 3,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
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