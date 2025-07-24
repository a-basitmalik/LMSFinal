import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_design_system.dart';
import '../utils/theme.dart';
import '../widgets/attendance_progress_bar.dart';
import '../screens/attendance_records_screen.dart';
import '../models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  final String rfid;

  const AttendanceScreen({super.key, required this.rfid});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic> attendanceData = {};
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/attendance/student/attendance_summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rfid': widget.rfid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          attendanceData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Failed to load attendance data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    await _fetchAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppDesignSystem.appBar(context, 'Attendance'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppDesignSystem.appBar(context, 'Attendance'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error
                  )
              ),
              const SizedBox(height: AppTheme.defaultSpacing),
              ElevatedButton(
                onPressed: _refreshData,
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
        ),
      );
    }

    // Extract all data from attendanceData with proper null checks
    final subjects = List<Map<String, dynamic>>.from(attendanceData['subjects'] ?? []);
    final overallAttendance = attendanceData['overall_attendance'] ?? 0;
    final totalPresent = attendanceData['total_present'] ?? 0;
    final totalAbsent = attendanceData['total_absent'] ?? 0;
    final totalClasses = attendanceData['total_classes'] ?? 0;
    final monthlySummary = List<Map<String, dynamic>>.from(attendanceData['monthly_summary'] ?? []);

    return Scaffold(
      appBar: AppDesignSystem.appBar(context, 'Attendance'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient(AppColors.primary),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppTheme.defaultPadding,
                  child: _buildSummaryCard(
                    context,
                    overallAttendance,
                    totalPresent,
                    totalAbsent,
                    totalClasses,
                    monthlySummary,
                    subjects,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                    left: AppTheme.defaultSpacing,
                    top: AppTheme.defaultSpacing,
                    right: AppTheme.defaultSpacing
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Subject-wise Attendance',
                    style: Theme.of(context).textTheme.sectionHeader,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.defaultSpacing,
                    vertical: AppTheme.defaultSpacing / 2
                ),
                sliver: subjects.isEmpty
                    ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: AppTheme.defaultPadding,
                      child: Text(
                        'No attendance data available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final subject = subjects[index];
                        return _buildSubjectCard(context, subject);
                      },
                      childCount: subjects.length
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      int overallPercentage,
      int totalPresent,
      int totalAbsent,
      int totalClasses,
      List<Map<String, dynamic>> monthlySummary,
      List<Map<String, dynamic>> subjects,
      ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        ),
        padding: AppTheme.defaultPadding,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: AppTheme.defaultPadding,
                  decoration: BoxDecoration(
                    color: AppColors.glassEffectLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: AppColors.textPrimary,
                    size: AppTheme.defaultIconSize,
                  ),
                ),
                const SizedBox(width: AppTheme.defaultSpacing),
                Expanded(
                  child: Text(
                    'Overall Attendance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$overallPercentage%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            AttendanceProgressBar(percentage: overallPercentage),
            const SizedBox(height: AppTheme.defaultSpacing / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', '$totalPresent', AppColors.success),
                _buildStatItem('Absent', '$totalAbsent', AppColors.error),
                _buildStatItem('Total', '$totalClasses', AppColors.primary),
              ],
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.glassEffectLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceRecordsScreen(
                        summary: AttendanceSummary(
                          overallPercentage: overallPercentage,
                          totalPresent: totalPresent,
                          totalAbsent: totalAbsent,
                          totalClasses: totalClasses,
                          monthlyData: monthlySummary.map((month) {
                            return MonthlyAttendance(
                              month: month['month']?.toString() ?? 'Unknown',
                              present: month['present'] ?? 0,
                              absent: month['absent'] ?? 0,
                            );
                          }).toList(),
                          subjects: subjects.map((subject) {
                            return SubjectAttendance(
                              name: subject['name']?.toString() ?? 'Unknown',
                              percentage: subject['percentage'] ?? 0,
                              present: subject['present'] ?? 0,
                              absent: subject['absent'] ?? 0,
                              totalClasses: subject['total_classes'] ?? 0,
                              recentAbsences: _parseAbsenceDates(subject['recent_absences']),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  'View All Records',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
    final color = _getSubjectColor(subject['name']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceRecordsScreen(
                summary: AttendanceSummary(
                  overallPercentage: attendanceData['overall_attendance'] ?? 0,
                  totalPresent: attendanceData['total_present'] ?? 0,
                  totalAbsent: attendanceData['total_absent'] ?? 0,
                  totalClasses: attendanceData['total_classes'] ?? 0,
                  monthlyData: List<Map<String, dynamic>>.from(attendanceData['monthly_summary'] ?? [])
                      .map((month) => MonthlyAttendance(
                    month: month['month']?.toString() ?? 'Unknown',
                    present: month['present'] ?? 0,
                    absent: month['absent'] ?? 0,
                  ))
                      .toList(),
                  subjects: [SubjectAttendance(
                    name: subject['name']?.toString() ?? 'Unknown',
                    percentage: subject['percentage'] ?? 0,
                    present: subject['present'] ?? 0,
                    absent: subject['absent'] ?? 0,
                    totalClasses: subject['total_classes'] ?? 0,
                    recentAbsences: _parseAbsenceDates(subject['recent_absences']),
                  )],
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                    _getSubjectIcon(subject['name']),
                    color: color,
                    size: AppTheme.defaultIconSize
                ),
              ),
              const SizedBox(width: AppTheme.defaultSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name']?.toString() ?? 'Unknown',
                      style: Theme.of(context).textTheme.cardTitle,
                    ),
                    const SizedBox(height: AppTheme.defaultSpacing / 2),
                    AttendanceProgressBar(percentage: subject['percentage'] ?? 0),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.defaultSpacing),
              Text(
                '${subject['percentage'] ?? 0}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  IconData _getSubjectIcon(String? subjectName) {
    final icons = {
      'Maths': Icons.calculate,
      'Physics': Icons.science,
      'Chemistry': Icons.emoji_objects,
      'English': Icons.menu_book,
      'Computer Science': Icons.computer,
    };
    return icons[subjectName] ?? Icons.subject;
  }

  Color _getSubjectColor(String? subjectName) {
    final colors = {
      'Maths': AppColors.secondary,
      'Physics': AppColors.info,
      'Chemistry': AppColors.primaryLight,
      'English': AppColors.primary,
      'Computer Science': AppColors.warning,
    };
    return colors[subjectName] ?? AppColors.primaryDark;
  }

  List<DateTime> _parseAbsenceDates(List<dynamic>? dates) {
    if (dates == null) return [];
    return dates.map((dateStr) {
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        return DateTime.now(); // Return current date as fallback
      }
    }).toList();
  }
}