import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import '../../Teacher/SubjectDetails.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../utils/theme.dart';
import 'attendance_screen.dart';
import 'chat_rooms_screen.dart';
import 'syllabus_screen.dart';
import 'assessments_screen.dart';
import 'timetable_screen.dart';
import 'announcements_screen.dart';
import '../services/notification_service.dart';
import '../screens/queries_screen.dart';
import '../screens/assignments_screen.dart';

DateTime? _safeParseDate(String? dateStr) {
  try {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    return DateTime.parse(dateStr);
  } catch (_) {
    return null;
  }
}

class HomeScreenContent extends StatefulWidget {
  final String rfid;

  const HomeScreenContent({super.key, required this.rfid});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final data = await fetchStudentData(widget.rfid);
      setState(() {
        studentData = data;
        isLoading = false;
      });

      final notificationService = NotificationService();
      notificationService.addNotification('assessment', count: 2);
      notificationService.addNotification('chat');
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching student data: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> fetchStudentData(String rfid) async {
    final response = await http.post(
      Uri.parse('http://193.203.162.232:5050/student/student_dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rfid': rfid}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load student data: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
        ),
      );
    }

    if (hasError || studentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: TeacherColors.dangerAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load student data',
              style: TeacherTextStyles.cardSubtitle,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudentData,
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
      );
    }

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'DASHBOARD',
                style: TeacherTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TeacherColors.primaryAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildStatsRow(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildTimetableSection(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildQuickActionsSection(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildAnnouncementsConsoleSection(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildAssignmentsSection(context),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: TeacherColors.glassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: TeacherTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 8),
              Text(
                studentData?['name'] ?? 'Student',
                style: TeacherTextStyles.sectionHeader.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TeacherColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Grade ${studentData?['grade']} - Section ${studentData?['section']}',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TeacherColors.primaryAccent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: TeacherColors.primaryAccent.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: studentData?['profile_image'] != null
                  ? NetworkImage(studentData!['profile_image'])
                  : const AssetImage('assets/default_profile.png')
              as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Container(
      decoration: TeacherColors.glassDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatsCard(
              context,
              icon: Icons.calendar_today_rounded,
              value: '${studentData?['attendance_percentage'] ?? '0'}%',
              label: 'Attendance',
              color: TeacherColors.primaryAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatsCard(
              context,
              icon: Icons.assignment_rounded,
              value: '${studentData?['average_score'] ?? '0'}%',
              label: 'Avg. Score',
              color: TeacherColors.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TeacherTextStyles.statValue.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TeacherTextStyles.cardSubtitle.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSection(BuildContext context) {
    final timetable = (studentData?['timetable'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "TODAY'S CLASSES",
            style: TeacherTextStyles.sectionHeader,
          ),
        ),
        Container(
          decoration: TeacherColors.glassDecoration(),
          child: timetable.isNotEmpty && timetable[0] != null
              ? Column(
            children: [
              for (var i = 0; i < timetable.length; i++)
                if (timetable[i] != null)
                  _buildClassItem(
                    subject: timetable[i]['subject'] ?? 'No Subject',
                    time: timetable[i]['time'] ?? '--:--',
                    room: timetable[i]['room'] ?? '--',
                    isLast: i == timetable.length - 1,
                  ),
            ],
          )
              : Padding(
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

  Widget _buildClassItem({
    required String subject,
    required String time,
    required String room,
    required bool isLast,
  }) {
    final IconData subjectIcon = _getSubjectIcon(subject);
    final Color subjectColor = _getSubjectColor(subject);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      subjectColor.withOpacity(0.3),
                      subjectColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  subjectIcon,
                  color: subjectColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TeacherTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room,
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: subjectColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Divider(
                height: 1,
                color: TeacherColors.cardBorder.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final quickActions = [
      {
        'icon': Icons.calendar_today,
        'label': 'Attendance',
        'color': TeacherColors.primaryAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(rfid: widget.rfid),
          ),
        ),
      },
      {
        'icon': Icons.book,
        'label': 'Syllabus',
        'color': TeacherColors.secondaryAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SyllabusScreen()),
        ),
      },
      {
        'icon': Icons.assignment,
        'label': 'Assignments',
        'color': TeacherColors.infoAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentsScreen(studentRfid: widget.rfid),
          ),
        ),
      },
      {
        'icon': Icons.chat,
        'label': 'Chat Rooms',
        'color': TeacherColors.successAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomsScreen(rfid: widget.rfid),
          ),
        ),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Queries',
        'color': TeacherColors.warningAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QueriesScreen(studentRfid: widget.rfid),
          ),
        ),
      },
      {
        'icon': Icons.assessment,
        'label': 'Assessments',
        'color': TeacherColors.dangerAccent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentsScreen(rfid: widget.rfid),
          ),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'QUICK ACCESS',
            style: TeacherTextStyles.sectionHeader,
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: quickActions.map((action) {
            return _buildQuickActionButton(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: TeacherColors.glassDecoration(
          borderColor: color.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsConsoleSection(BuildContext context) {
    final announcements = studentData?['announcements'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'ANNOUNCEMENT CONSOLE',
            style: TeacherTextStyles.sectionHeader,
          ),
        ),
        Container(
          decoration: TeacherColors.glassDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildConsoleOption(
                      icon: Icons.campaign_rounded,
                      label: 'General',
                      subLabel: 'Announcements',
                      color: TeacherColors.primaryAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildConsoleOption(
                      icon: Icons.announcement_outlined,
                      label: 'Subject',
                      subLabel: 'Annoucement',
                      color: TeacherColors.secondaryAccent,
                      onTap: () {
                        // Subject announcement action
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAnimatedButton(
                icon: Icons.add_rounded,
                label: 'CREATE NEW QUERY',
                color: TeacherColors.primaryAccent,
                onTap: () => _showAddQueryModal(context),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildConsoleOption(
                      icon: Icons.report_problem,
                      label: 'View',
                      subLabel: 'Complaint',
                      color: TeacherColors.dangerAccent,
                      onTap: () => _showAddComplaintModal(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildConsoleOption(
                      icon: Icons.phone_android,
                      label: 'Call',
                      subLabel: 'Logs',
                      color: TeacherColors.infoAccent,
                      onTap: () {
                        // Call log navigation
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleOption({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subLabel,
              style: TeacherTextStyles.cardSubtitle.copyWith(
                color: color,
                fontSize: 10,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsSection(BuildContext context) {
    final assignments = studentData?['assignments'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "UPCOMING ASSIGNMENTS",
            style: TeacherTextStyles.sectionHeader,
          ),
        ),
        Container(
          decoration: TeacherColors.glassDecoration(),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAssignmentStatItem(
                icon: Icons.check_circle,
                value: assignments.where((a) => a['status'] == 'completed').length.toString(),
                label: 'Completed',
                color: TeacherColors.successAccent,
              ),
              _buildAssignmentStatItem(
                icon: Icons.pending_actions,
                value: assignments.where((a) => a['status'] == 'pending').length.toString(),
                label: 'Pending',
                color: TeacherColors.warningAccent,
              ),
              _buildAssignmentStatItem(
                icon: Icons.calendar_today,
                value: assignments.length.toString(),
                label: 'Upcoming',
                color: TeacherColors.dangerAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: TeacherColors.glassDecoration(
            borderColor: TeacherColors.primaryAccent.withOpacity(0.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignmentsScreen(studentRfid: widget.rfid),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TeacherColors.primaryAccent.withOpacity(0.3),
                          TeacherColors.primaryAccent.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.upload,
                      color: TeacherColors.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUBMIT YOUR ASSIGNMENT',
                          style: TeacherTextStyles.cardTitle.copyWith(
                            color: TeacherColors.primaryAccent,
                          ),
                        ),
                        Text(
                          'Upload your completed work',
                          style: TeacherTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (assignments.isNotEmpty)
          Container(
            decoration: TeacherColors.glassDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < (assignments.length > 2 ? 2 : assignments.length); i++)
                  _buildAssignmentListItem(
                    subject: assignments[i]['subject'],
                    title: assignments[i]['title'],
                    dueDate: assignments[i]['due'],
                    isLast: i == (assignments.length > 2 ? 1 : assignments.length - 1),
                  ),
              ],
            ),
          ),
        if (assignments.isEmpty)
          Container(
            decoration: TeacherColors.glassDecoration(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No upcoming assignments',
                style: TeacherTextStyles.cardSubtitle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentListItem({
    required String subject,
    required String title,
    required String dueDate,
    required bool isLast,
  }) {
    final subjectColor = _getSubjectColor(subject);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      subjectColor.withOpacity(0.3),
                      subjectColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    subject[0],
                    style: TeacherTextStyles.statValue.copyWith(
                      color: subjectColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeacherTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subject • Due in $dueDate',
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: TeacherColors.secondaryText,
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Divider(
                height: 1,
                color: TeacherColors.cardBorder.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TeacherTextStyles.cardTitle.copyWith(
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _showAddQueryModal(BuildContext context) {
    final subjectController = TextEditingController();
    final questionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: TeacherColors.cardBorder,
            width: 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TeacherColors.glassEffectLight,
              TeacherColors.glassEffectDark,
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

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Query',
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: subjectController,
                style: TeacherTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                maxLines: 4,
                style: TeacherTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Your Question',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: TeacherColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (subjectController.text.isEmpty ||
                            questionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        try {
                          // Submit query logic here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Query submitted successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TeacherTextStyles.primaryButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddComplaintModal(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: TeacherColors.cardBorder,
            width: 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TeacherColors.glassEffectLight,
              TeacherColors.glassEffectDark,
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

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Complaint',
                style: TeacherTextStyles.sectionHeader.copyWith(
                  color: TeacherColors.dangerAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TeacherTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                style: TeacherTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TeacherColors.cardBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: TeacherColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        try {
                          // Submit complaint logic here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Complaint submitted successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.dangerAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TeacherTextStyles.primaryButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    final subjectIcons = {
      'Mathematics': Icons.calculate,
      'Physics': Icons.science,
      'Chemistry': Icons.science,
      'Biology': Icons.eco,
      'English': Icons.menu_book,
      'History': Icons.history,
      'Geography': Icons.public,
      'Computer Science': Icons.computer,
      'Physical Education': Icons.sports,
      'Art': Icons.palette,
    };

    return subjectIcons[subject] ?? Icons.class_;
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': TeacherColors.primaryAccent,
      'Physics': TeacherColors.secondaryAccent,
      'Chemistry': TeacherColors.infoAccent,
      'Biology': TeacherColors.successAccent,
      'English': TeacherColors.warningAccent,
      'History': TeacherColors.dangerAccent,
    };
    return colors[subject] ?? TeacherColors.primaryAccent;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}