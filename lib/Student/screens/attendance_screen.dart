import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        appBar: AppBar(
          title: const Text('Attendance'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
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
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.1), AppColors.background],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.only(left: 24, top: 16, right: 24),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Subject-wise Attendance',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: subjects.isEmpty
                    ? SliverToBoxAdapter(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No attendance data available'),
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final subject = subjects[index];
                    return _buildSubjectCard(context, subject);
                  }, childCount: subjects.length),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Overall Attendance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$overallPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AttendanceProgressBar(percentage: overallPercentage),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', '$totalPresent', Colors.green),
                _buildStatItem('Absent', '$totalAbsent', Colors.red),
                _buildStatItem('Total', '$totalClasses', AppColors.primaryDark),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                child: const Text(
                  'View All Records',
                  style: TextStyle(
                    color: Colors.white,
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_getSubjectIcon(subject['name']), color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name']?.toString() ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AttendanceProgressBar(percentage: subject['percentage'] ?? 0),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${subject['percentage'] ?? 0}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
      'Maths': AppColors.secondary,
      'Physics': AppColors.accentBlue,
      'Chemistry': AppColors.accentPink,
      'English': AppColors.primary,
      'Computer Science': AppColors.accentAmber,
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