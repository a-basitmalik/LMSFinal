// lib/screens/home_screen_content.dart
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
        SnackBar(content: Text('Error fetching student data: $e')),
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
      print("Profile image URL: ${studentData?['profile_image']}");
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load student data: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError || studentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load student data'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudentData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchStudentData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(child: _buildStatsRow(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(child: _buildTimetableSection(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _buildAnnouncementsSection(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _buildAssignmentsSection(context),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
                  color: AppColors.accentPink,
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
                  color: AppColors.accentBlue,
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
                  color: AppColors.accentAmber,
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentData?['name'] ?? 'Student',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grade ${studentData?['grade']} - Section ${studentData?['section']}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: CircleAvatar(
              radius: 32,

              backgroundImage: studentData?['profile_image'] != null
                  ? NetworkImage(studentData!['profile_image'])
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
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
        const SizedBox(width: 16),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Classes",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
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
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < timetable.length; i++) ...[
                  if (i > 0) const Divider(height: 16, thickness: 1),
                  _buildClassItem(
                    context,
                    time: timetable[i]['time'],
                    subject: timetable[i]['subject'],
                    room: timetable[i]['room'],
                    color: _getSubjectColor(timetable[i]['subject']),
                  ),
                ],
                if (timetable.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No classes today'),
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
      'Chemistry': AppColors.accentBlue,
      'Biology': AppColors.success,
      'English': AppColors.accentPink,
      'History': AppColors.accentAmber,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  subject,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(room, style: TextStyle(color: color)),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
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
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < (announcements.length > 2 ? 2 : announcements.length); i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _buildAnnouncementItem(
                    title: announcements[i]['title'],
                    message: announcements[i]['message'],
                    time: announcements[i]['date'],
                    color: _getRandomColor(i),
                  ),
                ],
                if (announcements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No announcements available'),
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
      AppColors.accentBlue.withOpacity(0.2),
      AppColors.accentPink.withOpacity(0.2),
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(Icons.notifications, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: TextStyle(color: AppColors.textSecondary)),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  AssignmentsScreen(studentRfid: widget.rfid),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (assignments.isNotEmpty)
          for (var i = 0; i < (assignments.length > 2 ? 2 : assignments.length); i++)
            _buildAssignmentItem(
              context,
              subject: assignments[i]['subject'],
              title: assignments[i]['title'],
              dueIn: assignments[i]['due'],
              color: _getSubjectColor(assignments[i]['subject']),
            ),
        if (assignments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to assignment detail
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subject • Due in $dueIn',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}