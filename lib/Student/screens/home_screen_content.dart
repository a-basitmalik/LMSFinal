import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../Teacher/SubjectDetails.dart';
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

  // Add this in your HomeScreenContent widget (replace the existing announcements section)
  Widget _buildAnnouncementsConsoleSection(BuildContext context) {
    final cyberBlue = Color(0xFF00E0FF);
    final matrixGreen = Color(0xFF00FF9D);
    final announcements = studentData?['announcements'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.announcement,
          title: 'ANNOUNCEMENT CONSOLE',
          color: cyberBlue,
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 16,
          borderColor: cyberBlue.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildConsoleOption(
                        icon: Icons.campaign_rounded,
                        label: 'General',
                        subLabel: 'Announcements',
                        color: cyberBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConsoleOption(
                        icon: Icons.announcement_outlined,
                        label: 'Subject',
                        subLabel: 'Annoucement',
                        color: cyberBlue,
                        onTap: () {
                          // Navigate to call history if needed
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAnimatedButton(
                  icon: Icons.add_rounded,
                  label: 'CREATE NEW QUERY',
                  color: cyberBlue,
                  onTap: () => _showAddQueryModal(context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildConsoleOption(
                        icon: Icons.report_problem,
                        label: 'View',
                        subLabel: 'Complaint',
                        color: cyberBlue,
                        onTap: () => _showAddComplaintModal(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConsoleOption(
                        icon: Icons.phone_android,
                        label: 'Call',
                        subLabel: 'Logs',
                        color: cyberBlue,
                        onTap: () {
                          // Navigate to complaints screen if needed
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// Helper widget for console options
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
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add query modal
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
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Query',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
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
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text('Submit'),
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

// Add complaint modal
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
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Complaint',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
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
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text('Submit'),
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

// Section header widget
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color ?? Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
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
              sliver: SliverToBoxAdapter(child: _buildQuickActionsSection(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _buildAnnouncementsConsoleSection(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(child: _buildAssignmentsSection(context)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark
        ? [AppColors.primaryDark, AppColors.primary]
        : [AppColors.primary, AppColors.primaryLight];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerGradient,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
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
                  : const AssetImage('assets/default_profile.png')
              as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildGlowingStatCard( // Changed to glowing version
            context,
            icon: Icons.calendar_today,
            value: '${studentData?['attendance_percentage'] ?? '0'}%',
            label: 'Attendance',
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlowingStatCard( // Changed to glowing version
            context,
            icon: Icons.assignment,
            value: '${studentData?['average_score'] ?? '0'}%',
            label: 'Avg. Score',
            color: isDark ? AppColors.secondaryLight : AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingStatCard( // New glowing stat card version
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? color.withOpacity(0.8) : color;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onBackground;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(0.15),
                baseColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      baseColor.withOpacity(0.3),
                      baseColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolographicActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.white.withOpacity(0.9);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard( // Changed back to GlassCard for glow effect
          borderRadius: 20,
          borderColor: color.withOpacity(0.3),
          glowColor: color.withOpacity(0.2),
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
        SectionHeader(
          title: "UPCOMING ASSIGNMENTS",
          titleColor: AppColors.accentAmberLight,
                onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssignmentsScreen(studentRfid: widget.rfid),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        GlassCard( // Added GlassCard for assignments stats
          borderRadius: 20,
          borderColor: AppColors.accentAmberLight.withOpacity(0.3),
          glowColor: AppColors.accentAmberLight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAssignmentStatItem(
                  icon: Icons.check_circle,
                  value: assignments.where((a) => a['status'] == 'completed').length.toString(),
                  label: 'Completed',
                ),
                _buildAssignmentStatItem(
                  icon: Icons.pending_actions,
                  value: assignments.where((a) => a['status'] == 'pending').length.toString(),
                  label: 'Pending',
                ),
                _buildAssignmentStatItem(
                  icon: Icons.calendar_today,
                  value: assignments.length.toString(),
                  label: 'Upcoming',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        GlassCard( // Added GlassCard for submit button
          borderRadius: 12,
          borderColor: AppColors.accentAmberLight.withOpacity(0.5),
          glowColor: AppColors.accentAmberLight,
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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmberLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.upload,
                      color: AppColors.accentAmberLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBMIT YOUR ASSIGNMENT',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:AppColors.accentAmberLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Upload your completed work',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accentAmberLight.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (assignments.isNotEmpty)
          GlassCard( // Added GlassCard for assignments list
            borderRadius: 20,
            borderColor: AppColors.accentAmberLight.withOpacity(0.3),
            glowColor: AppColors.accentAmberLight,
            child: Column(
              children: [
                for (var i = 0; i < (assignments.length > 2 ? 2 : assignments.length); i++)
                  _buildAssignmentListItem(
                    subject: assignments[i]['subject'],
                    title: assignments[i]['title'],
                    dueDate: assignments[i]['due'],
                    isLast: i == (assignments.length > 2 ? 1 : assignments.length - 1),
                    color: AppColors.accentAmberLight,
                  ),
              ],
            ),
          ),
        if (assignments.isEmpty)
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.accentAmberLight.withOpacity(0.3),
            glowColor: AppColors.accentAmberLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No upcoming assignments',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentAmberLight.withOpacity(0.6),
                ),
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
    required Color color,
  }) {
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
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    subject[0],
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
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
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subject • Due in $dueDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Divider(
                height: 1,
                color: color.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? color.withOpacity(0.8) : color;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onBackground;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(0.15),
                baseColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      baseColor.withOpacity(0.3),
                      baseColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableSection(BuildContext context) {
    final timetable = (studentData?['timetable'] as List?) ?? [];
    debugPrint('Timetable data: $timetable');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "TODAY'S CLASSES",
          titleColor: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimetableScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        if (timetable.isNotEmpty && timetable[0] != null)
          HolographicCard(
            borderColor: AppColors.primary.withOpacity(0.3),
            child: Column(
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
            ),
          ),
        if (timetable.isEmpty || timetable[0] == null)
          HolographicCard(
            borderColor: AppColors.primary.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No classes today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
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
              CircleAvatar(
                backgroundColor: subjectColor.withOpacity(0.2),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subjectColor,
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
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final quickActions = [
      {
        'icon': Icons.calendar_today,
        'label': 'Attendance',
        'color': isDark ? AppColors.primaryLight : AppColors.primary,
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
        'color': isDark ? AppColors.secondaryLight : AppColors.secondary,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SyllabusScreen()),
        ),
      },
      {
        'icon': Icons.assignment,
        'label': 'Assignments',
        'color': isDark ? AppColors.accentPinkLight : AppColors.accentPink,
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
        'color': isDark ? AppColors.accentBlueLight : AppColors.accentBlue,
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
        'color': isDark ? AppColors.accentAmberLight : AppColors.accentAmber,
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
        'color': isDark ? AppColors.successLight : AppColors.success,
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
        SectionHeader(
          title: 'QUICK ACCESS',
          titleColor: AppColors.accentBlue,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return _buildHolographicActionButton(
                context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback,
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildAnnouncementsSection(BuildContext context) {
    final announcements = studentData?['announcements'] ?? [];
    final cyberBlue = Color(0xFF00E0FF);
    final matrixGreen = Color(0xFF00FF9D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'ANNOUNCEMENTS',
          titleColor: cyberBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnnouncementsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        HolographicCard(
          borderColor: cyberBlue.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (announcements.isNotEmpty)
                  for (var i = 0; i < (announcements.length > 2 ? 2 : announcements.length); i++)
                    Column(
                      children: [
                        if (i > 0) const SizedBox(height: 12),
                        _buildAnnouncementItem(
                          title: announcements[i]['title'],
                          message: announcements[i]['message'],
                          time: announcements[i]['date'],
                          color: [cyberBlue, matrixGreen][i % 2],
                        ),
                      ],
                    ),
                if (announcements.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No announcements available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  icon: Icons.arrow_forward,
                  label: 'SEE ALL',
                  color: cyberBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
                style: TextStyle(
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

  Widget _buildAnnouncementItem({
    required String title,
    required String message,
    required String time,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAssignmentStatsRow({
    required int completed,
    required int pending,
    required int upcoming,
  }) {
    return HolographicCard(
      borderColor: Colors.red.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAssignmentStatItem(
              icon: Icons.check_circle,
              value: completed.toString(),
              label: 'Completed',
            ),
            _buildAssignmentStatItem(
              icon: Icons.pending_actions,
              value: pending.toString(),
              label: 'Pending',
            ),
            _buildAssignmentStatItem(
              icon: Icons.calendar_today,
              value: upcoming.toString(),
              label: 'Upcoming',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.red.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitAssignmentButton() {
    return HolographicCard(
      borderColor: Colors.red.withOpacity(0.5),
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
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBMIT YOUR ASSIGNMENT',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Upload your completed work',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
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
      'Mathematics': AppColors.primary,
      'Physics': AppColors.secondary,
      'Chemistry': AppColors.accentBlue,
      'Biology': AppColors.success,
      'English': AppColors.accentPink,
      'History': AppColors.accentAmber,
    };
    return colors[subject] ?? AppColors.primary;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class HolographicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double? width;
  final double? height;

  const HolographicCard({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.borderColor = Colors.white,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor.withOpacity(isDark ? 0.05 : 0.1),
            borderColor.withOpacity(isDark ? 0.02 : 0.05),
          ],
        ),
        border: Border.all(
          color: borderColor.withOpacity(isDark ? 0.1 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: titleColor ?? Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: titleColor ?? Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}