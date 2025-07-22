import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'teacher_routes.dart';

class TeacherMain extends StatefulWidget {
  final String userId;

  const TeacherMain({Key? key, required this.userId}) : super(key: key);

  @override
  _TeacherMainState createState() => _TeacherMainState();
}

class _TeacherMainState extends State<TeacherMain> with SingleTickerProviderStateMixin {
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
      home: _TeacherDashboardContent(
        userId: widget.userId,
        animation: _animation,
      ),
    );
  }
}

class _TeacherDashboardContent extends StatefulWidget {
  final String userId;
  final Animation<double> animation;

  const _TeacherDashboardContent({
    required this.userId,
    required this.animation,
    Key? key,
  }) : super(key: key);

  @override
  __TeacherDashboardContentState createState() => __TeacherDashboardContentState();
}

class __TeacherDashboardContentState extends State<_TeacherDashboardContent> {
  late Map<String, dynamic> teacherProfile = {};
  late List<dynamic> todaysSchedule = [];
  late List<dynamic> subjects = [];
  late List<dynamic> announcements = [];
  int studentCount = 0;
  int classCount = 0;
  int taskCount = 0;
  bool hasNewAnnouncements = true;

  final String baseUrl = 'http://193.203.162.232:5050/Teacher/api';

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
    _fetchTodaysSchedule();
    _fetchStats();
    _fetchAnnouncements();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() => teacherProfile = json.decode(response.body));
      } else {
        setState(() => teacherProfile = {'name': 'NA', 'email': 'NA', 'department': 'NA'});
      }
    } catch (e) {
      setState(() => teacherProfile = {'name': 'NA', 'email': 'NA', 'department': 'NA'});
    }
  }

  Future<void> _fetchTodaysSchedule() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/schedule/today'));
      if (response.statusCode == 200) {
        setState(() => todaysSchedule = json.decode(response.body));
      } else {
        setState(() => todaysSchedule = []);
      }
    } catch (e) {
      setState(() => todaysSchedule = []);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/stats'));
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

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/announcements'));
      if (response.statusCode == 200) {
        setState(() {
          announcements = json.decode(response.body);
          hasNewAnnouncements = announcements.any((a) => a['isNew'] == true);
        });
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: Stack(
        children: [
          CustomPaint(
            painter: _ParticlePainter(animation: widget.animation),
            size: Size.infinite,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildQuickAccessSection(),
                    const SizedBox(height: 32),
                    _buildAnnouncementsSection(),
                    const SizedBox(height: 32),
                    _buildScheduleViewsSection(), // New section for schedule views
                    const SizedBox(height: 32),
                    _buildTodaysScheduleSection(),
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

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: TeacherColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              teacherProfile['name'] ?? 'Professor',
              style: TeacherTextStyles.headerTitle,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => TeacherRoutes.navigateToProfile(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  TeacherColors.primaryAccent,
                  TeacherColors.secondaryAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: TeacherColors.primaryAccent.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                teacherProfile['name'] != null
                    ? teacherProfile['name'].substring(0, 1)
                    : 'P',
                style: TextStyle(
                  color: TeacherColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.bolt_rounded,
          title: 'QUICK ACCESS',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickAccessCard(
                icon: Icons.person,
                label: 'Teacher Profile',
                value: '',
                color: TeacherColors.announcementColor,
                onTap: () => TeacherRoutes.navigateToProfile(context),
              ),
              _buildQuickAccessCard(
                icon: Icons.school,
                label: 'My Subjects',
                value: '',
                color: TeacherColors.classColor,
                onTap: () => TeacherRoutes.navigateToSubjects(context, widget.userId),
              ),
            ].map((card) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(width: 140, child: card),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.campaign_outlined,
          title: 'ANNOUNCEMENTS',
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          borderColor: TeacherColors.announcementColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAnimatedButton(
                  icon: Icons.notifications,
                  label: 'VIEW ALL ANNOUNCEMENTS',
                  color: TeacherColors.primaryAccent,
                  onTap: () {
                    TeacherRoutes.navigateToAnnouncements(
                      context,
                      List<Map<String, dynamic>>.from(announcements),
                    );
                  },
                ),
                if (hasNewAnnouncements) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          'New announcements available',
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // New Schedule Views Section
  Widget _buildScheduleViewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.calendar_month,
          title: 'SCHEDULE VIEWS',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildScheduleViewCard(
                icon: Icons.calendar_view_month,
                label: "Calendar",
                description: "Month view",
                color: TeacherColors.primaryAccent,
                onTap: () {
                  TeacherRoutes.navigateToSchedule(
                    context,
                    widget.userId,
                    List<Map<String, dynamic>>.from(todaysSchedule),
                    {
                      'view': 'month',
                      'tabIndex': 0,  // Combined into single params map
                    },
                  );
                },
              ),
              _buildScheduleViewCard(
                icon: Icons.view_week,
                label: "Week",
                description: "Week view",
                color: TeacherColors.scheduleColor,
                onTap: () {
                  TeacherRoutes.navigateToSchedule(
                    context,
                    widget.userId,
                    List<Map<String, dynamic>>.from(todaysSchedule),
                    {
                      'view': 'week',
                      'tabIndex': 1,  // Combined into single params map
                    },
                  );
                },
              ),
              _buildScheduleViewCard(
                icon: Icons.view_day,
                label: "Day",
                description: "Day view",
                color: TeacherColors.classColor,
                onTap: () {
                  TeacherRoutes.navigateToSchedule(
                    context,
                    widget.userId,
                    List<Map<String, dynamic>>.from(todaysSchedule),
                    {
                      'view': 'day',
                      'tabIndex': 2,  // Combined into single params map
                    },
                  );
                },
              ),
            ].map((card) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(width: 140, child: card),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.schedule_rounded,
          title: "TODAY'S CLASSES",
        ),
        const SizedBox(height: 16),
        todaysSchedule.isNotEmpty
            ? GlassCard(
          borderRadius: 20,
          borderColor: TeacherColors.scheduleColor.withOpacity(0.3),
          child: Column(
            children: todaysSchedule.map((schedule) {
              final subjectColor = _getColorForSubject(schedule['subject_id'] ?? 0);
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: subjectColor.toCircleDecoration(size: 40),
                      child: Icon(Icons.schedule, color: subjectColor),
                    ),
                    title: Text(
                      schedule['subject_name'] ?? 'NA',
                      style: TeacherTextStyles.listItemTitle,
                    ),
                    subtitle: Text(
                      schedule['year'] != null ? 'Grade ${schedule['year']}' : 'NA',
                      style: TeacherTextStyles.listItemSubtitle,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          schedule['time'] ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: subjectColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          schedule['room'] ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (schedule != todaysSchedule.last)
                    Divider(height: 1, color: TeacherColors.cardBorder, indent: 16),
                ],
              );
            }).toList(),
          ),
        )
            : GlassCard(
          borderRadius: 20,
          borderColor: TeacherColors.scheduleColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No classes scheduled for today',
                style: TeacherTextStyles.cardSubtitle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return GlassCard(
      borderRadius: 16,
      borderColor: color.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: color.toCircleDecoration(size: 36),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TeacherTextStyles.cardTitle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    value,
                    style: TeacherTextStyles.statValue.copyWith(
                      color: color,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              if (value.isEmpty)
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleViewCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      borderRadius: 16,
      borderColor: color.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: color.toCircleDecoration(size: 36),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TeacherTextStyles.cardTitle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
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
                Icon(icon, color: TeacherColors.primaryAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TeacherTextStyles.sectionHeader,
                ),
              ],
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: TeacherColors.primaryAccent.withOpacity(0.7),
                size: 16,
              ),
          ],
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
                  style: TeacherTextStyles.primaryButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForSubject(int subjectId) {
    final colors = [
      TeacherColors.classColor,
      TeacherColors.studentColor,
      TeacherColors.assignmentColor,
      TeacherColors.gradeColor,
      TeacherColors.scheduleColor,
      TeacherColors.announcementColor,
    ];
    return colors[subjectId % colors.length];
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
      decoration: TeacherColors.glassDecoration(
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

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random random = Random(42);

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 3;
      final hue = 180 + random.nextDouble() * 60;
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