import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/AnnouncementsScreen.dart';
import 'package:newapp/Teacher/SubjectDetails.dart';
import 'package:newapp/Teacher/Subjects.dart';
import 'package:newapp/Teacher/FullSchedule.dart';
import 'package:newapp/Teacher/TeacherProfile.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';

class TeacherMain extends StatelessWidget {
  final String userId;

  const TeacherMain({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: TeacherColors.primaryAccent,
        colorScheme: ColorScheme.dark(
          primary: TeacherColors.primaryAccent,
          secondary: TeacherColors.secondaryAccent,
          surface: TeacherColors.primaryBackground,
          background: TeacherColors.primaryBackground,
        ),
        scaffoldBackgroundColor: TeacherColors.primaryBackground,
        textTheme: TextTheme(
          headlineSmall: TeacherTextStyles.portalTitle,
          titleLarge: TeacherTextStyles.className,
          titleMedium: TeacherTextStyles.sectionHeader,
          bodyLarge: TeacherTextStyles.listItemTitle,
          bodyMedium: TeacherTextStyles.listItemSubtitle,
          labelLarge: TeacherTextStyles.primaryButton,
          bodySmall: TeacherTextStyles.statLabel,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TeacherDashboardContent(userId: userId),
    );
  }
}

class TeacherDashboardContent extends StatefulWidget {
  final String userId;

  const TeacherDashboardContent({Key? key, required this.userId}) : super(key: key);

  @override
  _TeacherDashboardContentState createState() => _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<TeacherDashboardContent> {
  late Map<String, dynamic> teacherProfile = {};
  late List<dynamic> todaysSchedule = [];
  late List<Map<String, dynamic>> subjects = [];
  late List<dynamic> announcements = [];
  bool isLoading = false;
  String errorMessage = '';
  int studentCount = 0;
  int classCount = 0;
  int taskCount = 0;
  bool hasNewAnnouncements = false;

  final String baseUrl = 'http://193.203.162.232:5050/Teacher/api';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchTeacherData(),
        _fetchTodaysSchedule(),
        _fetchStats(),
        _fetchAnnouncements(),
        _fetchSubjects(),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTeacherData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() => teacherProfile = json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching teacher data: $e');
    }
  }

  Future<void> _fetchTodaysSchedule() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/schedule/today'));
      if (response.statusCode == 200) {
        setState(() => todaysSchedule = json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching schedule: $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/stats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          studentCount = (data['student_count'] as num?)?.toInt() ?? 0;
          classCount = (data['class_count'] as num?)?.toInt() ?? 0;
          taskCount = (data['task_count'] as num?)?.toInt() ?? 0;
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
          hasNewAnnouncements = announcements.any((a) => (a['isNew'] as bool?) ?? false);
        });
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/${widget.userId}/subjects'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subjects = data.map((item) {
            return {
              'subject_id': (item['subject_id'] as num?)?.toString() ?? 'NA',
              'name': (item['subject_name'] as String?) ?? 'NA',
              'code': (item['subject_code'] as String?) ?? 'NA',
              'color': _getColorForSubject(item['subject_id']),
              'icon': _getIconForSubject(item['subject_name'] as String?),
              'students': (item['student_count'] as num?)?.toInt() ?? 0,
              'classes': _parseClasses(item['classes']),
              'schedule': _parseSchedule(item['schedule']),
              'year': (item['year'] as num?)?.toString() ?? 'NA',
              'room': (item['room'] as String?) ?? 'NA',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  List<String> _parseClasses(dynamic classesData) {
    if (classesData is String) return [classesData];
    if (classesData is List) return classesData.map((e) => e.toString()).toList();
    return ['NA'];
  }

  String _parseSchedule(dynamic scheduleData) {
    if (scheduleData is String) return scheduleData;
    if (scheduleData is List) return scheduleData.map((e) => e.toString()).join(', ');
    return 'Schedule not available';
  }

  IconData _getIconForSubject(String? subjectName) {
    final name = (subjectName ?? '').toLowerCase();
    if (name.contains('math')) return Icons.calculate;
    if (name.contains('physics')) return Icons.science;
    if (name.contains('computer')) return Icons.computer;
    if (name.contains('chemistry')) return Icons.science_outlined;
    if (name.contains('biology')) return Icons.eco;
    return Icons.school;
  }

  Color _getColorForSubject(dynamic subjectId) {
    final colors = [
      TeacherColors.studentColor,
      TeacherColors.classColor,
      TeacherColors.attendanceColor,
      TeacherColors.assignmentColor,
      TeacherColors.gradeColor,
    ];

    int id;
    if (subjectId is String) {
      id = int.tryParse(subjectId) ?? 0;
    } else if (subjectId is num) {
      id = subjectId.toInt();
    } else {
      id = 0;
    }

    return colors[id % colors.length];
  }

  void _navigateToSubjectDetail(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDashboardScreen(
          subject: subject,
          teacherId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildSubjectSummaryCard() {
    final totalSubjects = subjects.length;
    final int totalStudents = subjects.fold<int>(0, (sum, subject) => sum + ((subject['students'] as int?) ?? 0));
    final int totalClasses = subjects.fold<int>(0, (sum, subject) => sum + ((subject['classes'] as List?)?.length ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TeacherColors.primaryAccent.withOpacity(0.8),
            TeacherColors.secondaryAccent.withOpacity(0.8),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(Icons.school, '$totalSubjects', 'Subjects'),
          _buildSummaryItem(Icons.people, '$totalStudents', 'Students'),
          _buildSummaryItem(Icons.class_, '$totalClasses', 'Classes'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TeacherTextStyles.statValue.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: TeacherTextStyles.statLabel.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildSubjectsList() {
    if (subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects available',
          style: TeacherTextStyles.cardSubtitle,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final color = subject['color'] as Color? ?? TeacherColors.primaryAccent;
    final students = subject['students'] as int? ?? 0;
    final classes = subject['classes'] as List<dynamic>? ?? [];
    final schedule = subject['schedule'] as String? ?? 'Schedule not available';
    final year = subject['year'] as String? ?? 'NA';
    final icon = subject['icon'] as IconData? ?? Icons.school;

    return Container(
      decoration: BoxDecoration(
        color: TeacherColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherColors.cardBorder, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToSubjectDetail(subject),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['name'] as String? ?? 'NA',
                          style: TeacherTextStyles.cardTitle,
                        ),
                        Text(
                          subject['code'] as String? ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$students students',
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: TeacherColors.secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    schedule,
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.class_, size: 16, color: TeacherColors.secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    classes.join(', '),
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: TeacherColors.secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    'Grade $year',
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: TeacherColors.primaryAccent))
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TeacherTextStyles.listItemSubtitle.copyWith(color: TeacherColors.dangerAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildSubjectSummaryCard(),
            const SizedBox(height: 24),
            _buildSubjectsList(),
            const SizedBox(height: 24),
            _buildAnnouncementsSection(),
            const SizedBox(height: 24),
            _buildScheduleViewsSection(),
            const SizedBox(height: 24),
            _buildTodaysScheduleSection(),
          ],
        ),
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
              teacherProfile['name']?.toString() ?? 'Professor',
              style: TeacherTextStyles.headerTitle,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          ),
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
                teacherProfile['name']?.toString().isNotEmpty == true
                    ? teacherProfile['name'].toString().substring(0, 1)
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

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.campaign_outlined,
          title: 'ANNOUNCEMENTS',
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: TeacherColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TeacherColors.announcementColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAnimatedButton(
                  icon: Icons.notifications,
                  label: 'VIEW ALL ANNOUNCEMENTS',
                  color: TeacherColors.primaryAccent,
                  onTap: () {


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
                },
              ),
              _buildScheduleViewCard(
                icon: Icons.view_week,
                label: "Week",
                description: "Week view",
                color: TeacherColors.scheduleColor,
                onTap: () {
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
                },
              ),
              _buildScheduleViewCard(
                icon: Icons.view_day,
                label: "Day",
                description: "Day view",
                color: TeacherColors.classColor,
                onTap: () {
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
            ? Container(
          decoration: BoxDecoration(
            color: TeacherColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TeacherColors.scheduleColor.withOpacity(0.3)),
          ),
          child: Column(
            children: todaysSchedule.map((schedule) {
              final subjectColor = _getColorForSubject(schedule['subject_id']);
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.schedule, color: subjectColor),
                    ),
                    title: Text(
                      (schedule['subject_name'] as String?) ?? 'NA',
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
                          (schedule['time'] as String?) ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: subjectColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (schedule['room'] as String?) ?? 'NA',
                          style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (schedule != todaysSchedule.last)
                    Divider(
                        height: 1,
                        color: TeacherColors.cardBorder,
                        indent: 16),
                ],
              );
            }).toList(),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            color: TeacherColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TeacherColors.scheduleColor.withOpacity(0.3)),
          ),
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

  Widget _buildScheduleViewCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TeacherColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
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
                  style: TeacherTextStyles.primaryButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}