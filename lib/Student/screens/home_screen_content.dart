import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

      // Add notifications after data loads
      final notificationService = NotificationService();
      notificationService.addNotification('assessment', count: 2);
      notificationService.addNotification('chat');
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching student data: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> fetchStudentData(String rfid) async {
    final response = await http.post(
      Uri.parse('http://193.203.162.232:5050/student/student_dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rfid': rfid}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load student data: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError || studentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            Text(
              'Failed to load student data',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            ElevatedButton(
              onPressed: _fetchStudentData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchStudentData,
        backgroundColor: AppColors.primary.withOpacity(0.2),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: AppTheme.defaultPadding,
              sliver: SliverToBoxAdapter(child: _buildStatsRow(context)),
            ),
            SliverPadding(
              padding: AppTheme.defaultPadding,
              sliver: SliverToBoxAdapter(child: _buildTimetableSection(context)),
            ),
            SliverPadding(
              padding: AppTheme.defaultPadding,
              sliver: SliverToBoxAdapter(
                child: _buildAnnouncementsSection(context),
              ),
            ),
            SliverPadding(
              padding: AppTheme.defaultPadding,
              sliver: SliverToBoxAdapter(
                child: _buildAssignmentsSection(context),
              ),
            ),
            SliverPadding(
              padding: AppTheme.defaultPadding,
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.defaultSpacing,
                  mainAxisSpacing: AppTheme.defaultSpacing,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildListDelegate([
                  _buildQuickActionButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Attendance',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScreen(rfid: widget.rfid),
                      ),
                    ),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.book,
                    label: 'Syllabus',
                    color: AppColors.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SyllabusScreen()),
                    ),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.assignment,
                    label: 'Assignments',
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentsScreen(studentRfid: widget.rfid),
                      ),
                    ),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.chat,
                    label: 'Chat Rooms',
                    color: AppColors.primaryLight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomsScreen(rfid: widget.rfid),
                      ),
                    ),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.help_outline,
                    label: 'Queries',
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QueriesScreen(studentRfid: widget.rfid),
                      ),
                    ),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.assessment,
                    label: 'Assessments',
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentsScreen(rfid: widget.rfid),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: AppTheme.defaultPadding,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient(AppColors.primary),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.defaultBorderRadius * 2),
          bottomRight: Radius.circular(AppTheme.defaultBorderRadius * 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppTheme.defaultSpacing / 2),
              Text(
                studentData?['name'] ?? 'Student',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.defaultSpacing),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.defaultSpacing,
                  vertical: AppTheme.defaultSpacing / 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassEffectLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grade ${studentData?['grade']} - Section ${studentData?['section']}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textPrimary,
                width: 2,
              ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            value: '${studentData?['attendance_percentage'] ?? '0'}%',
            label: 'Attendance',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppTheme.defaultSpacing),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.assignment,
            value: '${studentData?['average_score'] ?? '0'}%',
            label: 'Avg. Score',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      child: Container(
        decoration: AppColors.glassDecoration(borderColor: color),
        padding: AppTheme.defaultPadding,
        child: Column(
          children: [
            Container(
              padding: AppTheme.defaultPadding,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: AppTheme.defaultIconSize,
              ),
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSection(BuildContext context) {
    final timetable = studentData?['timetable'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Classes",
                style: Theme.of(context).textTheme.sectionHeader,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimetableScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.accentText(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
          ),
          child: Padding(
            padding: AppTheme.defaultPadding,
            child: Column(
              children: [
                for (var i = 0; i < timetable.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppTheme.defaultSpacing,
                      thickness: 1,
                      color: AppColors.cardBorder,
                    ),
                  _buildClassItem(
                    context,
                    time: timetable[i]['time'],
                    subject: timetable[i]['subject'],
                    room: timetable[i]['room'],
                    color: _getSubjectColor(timetable[i]['subject']),
                  ),
                ],
                if (timetable.isEmpty)
                  Padding(
                    padding: AppTheme.defaultPadding,
                    child: Text(
                      'No classes today',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': AppColors.primary,
      'Physics': AppColors.secondary,
      'Chemistry': AppColors.info,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      'History': AppColors.warning,
    };
    return colors[subject] ?? AppColors.primary;
  }

  Widget _buildClassItem(
      BuildContext context, {
        required String time,
        required String subject,
        required String room,
        required Color color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.defaultSpacing / 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppTheme.defaultSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  subject,
                  style: Theme.of(context).textTheme.cardTitle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.defaultSpacing / 2,
              vertical: AppTheme.defaultSpacing / 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
            ),
            child: Text(
              room,
              style: Theme.of(context).textTheme.accentText(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    final announcements = studentData?['announcements'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Latest Announcements",
              style: Theme.of(context).textTheme.sectionHeader,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.accentText(AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.defaultSpacing),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
          ),
          child: Padding(
            padding: AppTheme.defaultPadding,
            child: Column(
              children: [
                for (var i = 0;
                i < (announcements.length > 2 ? 2 : announcements.length);
                i++) ...[
                  if (i > 0)
                    const SizedBox(height: AppTheme.defaultSpacing),
                  _buildAnnouncementItem(
                    title: announcements[i]['title'],
                    message: announcements[i]['message'],
                    time: announcements[i]['date'],
                    color: _getRandomColor(i),
                  ),
                ],
                if (announcements.isEmpty)
                  Padding(
                    padding: AppTheme.defaultPadding,
                    child: Text(
                      'No announcements available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getRandomColor(int index) {
    final colors = [
      AppColors.secondary.withOpacity(0.2),
      AppColors.primary.withOpacity(0.2),
      AppColors.info.withOpacity(0.2),
      AppColors.primaryLight.withOpacity(0.2),
    ];
    return colors[index % colors.length];
  }

  Widget _buildAnnouncementItem({
    required String title,
    required String message,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.cardTitle,
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: onTap,
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppTheme.defaultIconSize,
                color: color,
              ),
              const SizedBox(height: AppTheme.defaultSpacing),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming Assignments",
              style: Theme.of(context).textTheme.sectionHeader,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AssignmentsScreen(studentRfid: widget.rfid),
                  ),
                );
              },
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.accentText(AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.defaultSpacing),
        if (assignments.isNotEmpty)
          for (var i = 0;
          i < (assignments.length > 2 ? 2 : assignments.length);
          i++)
            _buildAssignmentItem(
              context,
              subject: assignments[i]['subject'],
              title: assignments[i]['title'],
              dueIn: assignments[i]['due'],
              color: _getSubjectColor(assignments[i]['subject']),
            ),
        if (assignments.isEmpty)
          Card(
            elevation: 0,
            child: Padding(
              padding: AppTheme.defaultPadding,
              child: Text(
                'No upcoming assignments',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentItem(
      BuildContext context, {
        required String subject,
        required String title,
        required String dueIn,
        required Color color,
      }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: () {
          // Navigate to assignment detail
        },
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    subject[0],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.defaultSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.cardTitle,
                    ),
                    const SizedBox(height: AppTheme.defaultSpacing / 4),
                    Text(
                      '$subject • Due in $dueIn',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}