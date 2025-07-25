import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'dart:convert';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    if (isLoading) {
      return Scaffold(
        backgroundColor: TeacherColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'ATTENDANCE',
            style: TeacherTextStyles.sectionHeader,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
          ),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: TeacherColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'ATTENDANCE',
            style: TeacherTextStyles.sectionHeader,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  color: TeacherColors.dangerAccent,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
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
        ),
      );
    }

    final subjects = List<Map<String, dynamic>>.from(attendanceData['subjects'] ?? []);
    final overallAttendance = attendanceData['overall_attendance'] ?? 0;
    final totalPresent = attendanceData['total_present'] ?? 0;
    final totalAbsent = attendanceData['total_absent'] ?? 0;
    final totalClasses = attendanceData['total_classes'] ?? 0;
    final monthlySummary = List<Map<String, dynamic>>.from(attendanceData['monthly_summary'] ?? []);

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ATTENDANCE',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
        color: TeacherColors.primaryAccent,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'SUBJECT-WISE ATTENDANCE',
                  style: TeacherTextStyles.sectionHeader,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: subjects.isEmpty
                  ? SliverToBoxAdapter(
                child: Container(
                  decoration: TeacherColors.glassDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No attendance data available',
                      style: TeacherTextStyles.cardSubtitle,
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
                  childCount: subjects.length,
                ),
              ),
            ),
          ],
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Container(
      decoration: TeacherColors.glassDecoration(
        borderColor: TeacherColors.primaryAccent.withOpacity(0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                    Icons.bar_chart,
                    color: TeacherColors.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Overall Attendance',
                    style: TeacherTextStyles.cardTitle,
                  ),
                ),
                Text(
                  '$overallPercentage%',
                  style: TeacherTextStyles.statValue.copyWith(
                    color: TeacherColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AttendanceProgressBar(percentage: overallPercentage),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', '$totalPresent', TeacherColors.successAccent),
                _buildStatItem('Absent', '$totalAbsent', TeacherColors.dangerAccent),
                _buildStatItem('Total', '$totalClasses', TeacherColors.primaryAccent),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.primaryAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: TeacherColors.primaryAccent.withOpacity(0.3),
                    ),
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
                  'VIEW ALL RECORDS',
                  style: TeacherTextStyles.primaryButton.copyWith(
                    color: TeacherColors.primaryAccent,
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
    final textStyles = context.teacherTextStyles;

    return Column(
      children: [
        Text(
          label,
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TeacherTextStyles.cardTitle.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final color = _getSubjectColor(subject['name']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                  _getSubjectIcon(subject['name']),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name']?.toString() ?? 'Unknown',
                      style: TeacherTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    AttendanceProgressBar(percentage: subject['percentage'] ?? 0),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${subject['percentage'] ?? 0}%',
                style: TeacherTextStyles.statValue.copyWith(
                  color: color,
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
      'Maths': TeacherColors.primaryAccent,
      'Physics': TeacherColors.secondaryAccent,
      'Chemistry': TeacherColors.infoAccent,
      'English': TeacherColors.warningAccent,
      'Computer Science': TeacherColors.successAccent,
    };
    return colors[subjectName] ?? TeacherColors.primaryAccent;
  }

  List<DateTime> _parseAbsenceDates(List<dynamic>? dates) {
    if (dates == null) return [];
    return dates.map((dateStr) {
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        return DateTime.now();
      }
    }).toList();
  }
}