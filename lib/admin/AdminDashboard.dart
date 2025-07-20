import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'AdminRoutes.dart';
import 'AddPlannerScreen.dart';
import 'Announcement.dart';


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

  void _showAddAnnouncementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: AdminColors.primaryBackground.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: AdminColors.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: AnnouncementCreator(
              campusID: campusID,
              campusName: campusName,
            ),
          ),
        );
      },
    );
  }

  void _showAddPlannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: AdminColors.primaryBackground.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: AdminColors.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: AddPlannerScreen(campusID: campusID),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shortcutOptions = [
      {
        'title': 'Student',
        'icon': Icons.school_outlined,
        'route': '/studentList',
        'color': AdminColors.studentColor,
      },
      {
        'title': 'Faculty',
        'icon': Icons.person_outlined,
        'route': '/teacherList',
        'color': AdminColors.facultyColor,
      },
      {
        'title': 'Attendance',
        'icon': Icons.fingerprint_outlined,
        'route': '/attendance',
        'color': AdminColors.attendanceColor,
      },
      {
        'title': 'Fine',
        'icon': Icons.monetization_on_outlined,
        'route': '/fees',
        'color': AdminColors.fineColor,
      },
      {
        'title': 'Results',
        'icon': Icons.monetization_on_outlined,
        'route': '/results',
        'color': AdminColors.resultsColor,
      },
    ];

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
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
                          color: AdminColors.primaryAccent,
                          animation: animation,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_outlined,
                                      color: AdminColors.primaryAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ADMIN PORTAL',
                                    style: AdminTextStyles.portalTitle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                campusName.toUpperCase(),
                                style: AdminTextStyles.campusName,
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
                      borderColor: AdminColors.announcementColor.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildAnimatedButton(
                              icon: Icons.add_rounded,
                              label: 'POST NEW',
                              color: AdminColors.announcementColor,
                              onTap: () => _showAddAnnouncementModal(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.menu_book_rounded,
                      title: 'CURRICULUM',
                      iconColor: AdminColors.curriculumColor,
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          _buildAnimatedCurriculumOption(
                            icon: Icons.medical_services,
                            label: 'Pre-Medical',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'Pre-Medical'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.engineering,
                            label: 'Pre-Engineering',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'Pre-Engineering'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.science,
                            label: 'ICS (Physics)',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'ICS (Physics)'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.bar_chart,
                            label: 'ICS (Stats)',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'ICS (Stats)'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.bubble_chart,
                            label: 'General Science',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'General Science'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.account_balance_wallet,
                            label: 'I.COM (Part-I)',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'I.COM (Part-I)'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.account_balance,
                            label: 'I.COM (Part-II)',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'I.COM (Part-II)'),
                          ),
                          _buildAnimatedCurriculumOption(
                            icon: Icons.people,
                            label: 'Humanities (F.A.)',
                            color: AdminColors.curriculumColor,
                            onTap: () => _navigateToCurriculum(context, 'Humanities (F.A.)'),
                          ),
                        ].map((widget) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SizedBox(width: 150, child: widget),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.event_note_rounded,
                      title: 'LESSON PLANNER',
                      iconColor: AdminColors.plannerColor,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/planner',
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
                      borderColor: AdminColors.plannerColor.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildAnimatedButton(
                              icon: Icons.add_rounded,
                              label: 'CREATE NEW PLAN',
                              color: AdminColors.plannerColor,
                              onTap: () => _showAddPlannerModal(context),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPlannerOption(
                                    icon: Icons.today_rounded,
                                    label: 'Today\'s',
                                    subLabel: 'Plans',
                                    color: AdminColors.plannerColor,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/planner',
                                        arguments: {
                                          'campusID': campusID,
                                          'campusName': campusName,
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPlannerOption(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'View',
                                    subLabel: 'Calendar',
                                    color: AdminColors.plannerColor,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/calendar',
                                        arguments: {
                                          'campusID': campusID,
                                          'campusName': campusName,
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPlannerStatsRow(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.analytics_rounded,
                      title: 'REPORT DOWNLOAD',
                      iconColor: AdminColors.reportsColor,
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
                            color: AdminColors.reportsColor,
                            onTap: () => _navigateToReports(context, 0),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.assessment,
                            label: 'Assessment',
                            subLabel: 'Report',
                            color: AdminColors.reportsColor,
                            onTap: () => _navigateToReports(context, 1),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.quiz,
                            label: 'Monthly',
                            subLabel: '+ Quizzes',
                            color: AdminColors.reportsColor,
                            onTap: () => _navigateToReports(context, 2),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedReportOption(
                            icon: Icons.library_books,
                            label: 'All',
                            subLabel: 'Subjects',
                            color: AdminColors.reportsColor,
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
    );
  }

  Widget _buildPlannerStatsRow() {
    Future<Map<String, int>> fetchStats() async {
      final response = await http.get(Uri.parse('http://193.203.162.232:5050/Planner/planner_stats?campus_id=$campusID'));

      if (response.statusCode == 200) {
        return {
          'completed': jsonDecode(response.body)['completed'] ?? 0,
          'pending': jsonDecode(response.body)['pending'] ?? 0,
          'upcoming': jsonDecode(response.body)['upcoming'] ?? 0,
        };
      } else {
        throw Exception('Failed to load stats');
      }
    }

    return FutureBuilder<Map<String, int>>(
      future: fetchStats(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AdminColors.accentGradient(AdminColors.plannerColor),
              border: Border.all(
                color: AdminColors.plannerColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlannerStatItem(
                  icon: Icons.event_available,
                  value: snapshot.data!['completed'].toString(),
                  label: 'Completed',
                ),
                _buildPlannerStatItem(
                  icon: Icons.event_busy,
                  value: snapshot.data!['pending'].toString(),
                  label: 'Pending',
                ),
                _buildPlannerStatItem(
                  icon: Icons.event,
                  value: snapshot.data!['upcoming'].toString(),
                  label: 'Upcoming',
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return CircularProgressIndicator();
      },
    );
  }

  Widget _buildPlannerStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AdminColors.plannerColor.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              value,
              style: AdminTextStyles.statValue.copyWith(
                color: AdminColors.plannerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AdminTextStyles.statLabel,
        ),
      ],
    );
  }

  Widget _buildPlannerOption({
    required IconData icon,
    required String label,
    required String subLabel,
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: color.toCircleDecoration(size: 36),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AdminTextStyles.cardTitle,
                ),
                Text(
                  subLabel,
                  style: AdminTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color iconColor = AdminColors.primaryAccent,
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
                  decoration: (option['color'] as Color).toCircleDecoration(size: 48),
                  child: Icon(
                    option['icon'],
                    color: option['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  option['title'],
                  style: AdminTextStyles.cardTitle,
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
      decoration: color.toGlassDecoration(borderRadius: 12, borderWidth: 1),
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
                  style: AdminTextStyles.primaryButton,
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
                  decoration: color.toCircleDecoration(size: 40),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: AdminTextStyles.cardTitle,
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
                  decoration: color.toCircleDecoration(size: 36),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AdminTextStyles.cardTitle,
                ),
                Text(
                  subLabel,
                  style: AdminTextStyles.cardSubtitle,
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
    int groupId = 8; // Default to Pre-Medical
    switch(section) {
      case 'Pre-Medical':
        groupId = 8;
        break;
      case 'Pre-Engineering':
        groupId = 9;
        break;
      case 'ICS (Physics)':
        groupId = 10;
        break;
      case 'ICS (Stats)':
        groupId = 11;
        break;
      case 'General Science':
        groupId = 12;
        break;
      case 'I.COM (Part-I)':
        groupId = 13;
        break;
      case 'I.COM (Part-II)':
        groupId = 14;
        break;
      case 'Humanities (F.A.)':
        groupId = 15;
        break;
    }

    Navigator.pushNamed(
      context,
      '/subjects',
      arguments: {
        'campusID': campusID,
        'campusName': campusName,
        'subjectGroupId': groupId,
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
      decoration: AdminColors.glassDecoration(
        borderColor: borderColor,
        borderRadius: borderRadius,
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