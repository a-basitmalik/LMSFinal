import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:newapp/admin/themes/theme_colors.dart';import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';


class AttendanceDashboard2 extends StatefulWidget {
  final int campusID;

  const AttendanceDashboard2({Key? key, required this.campusID}) : super(key: key);

  @override
  _AttendanceDashboardState2 createState() => _AttendanceDashboardState2();
}

class _AttendanceDashboardState2 extends State<AttendanceDashboard2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<StudentAttendance> attendanceList = [];
  int presentCount = 0;
  int absentCount = 0;
  bool isLoading = true;
  bool isRefreshing = false;
  final String baseUrl = "http://193.203.162.232:5050/attendance/get_attendance_data_view_attendance?";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    fetchAttendanceData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      final url = '${baseUrl}campus_id=${widget.campusID}';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<StudentAttendance> newList = [];
          final attendanceArray = data['attendance_data'] as List;

          for (var student in attendanceArray) {
            newList.add(StudentAttendance(
              rfid: student['rfid'],
              name: student['student_name'],
              id: student['rfid'].toString(),
              isPresent: student['status'] == 'Present',
              time: 'Unknown',
            ));
          }

          setState(() {
            attendanceList = newList;
            presentCount = data['present_count'];
            absentCount = data['absent_count'];
            isLoading = false;
            isRefreshing = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() {
        isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch attendance data'),
          backgroundColor: AdminColors.dangerAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AdminColors.secondaryBackground,
      highlightColor: AdminColors.cardBackground,
      child: Column(
        children: List.generate(
          5,
              (index) => Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: AdminColors.glassDecoration(),
            height: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(String title, int count, Color color) {
    final textStyles = context.adminTextStyles;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: Container(
        decoration: color.toGlassDecoration(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdminTextStyles.cardSubtitle,
              ),
              SizedBox(height: 8),
              Text(
                count.toString(),
                style: AdminTextStyles.statValue.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentAttendance student) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    final statusColor = student.isPresent ? AdminColors.successAccent : AdminColors.dangerAccent;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: AdminColors.glassDecoration(
        borderColor: statusColor.withOpacity(0.2),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: statusColor.toCircleDecoration(),
          child: Center(
            child: Text(
              student.name.substring(0, 1).toUpperCase(),
              style: AdminTextStyles.statValue,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: AdminTextStyles.cardTitle.copyWith(fontSize: 14),
        ),
        subtitle: Text(
          'ID: ${student.rfid}',
          style: AdminTextStyles.cardSubtitle,
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AdminColors.accentGradient(statusColor),
          ),
          child: Text(
            student.isPresent ? 'PRESENT' : 'ABSENT',
            style: AdminTextStyles.primaryButton.copyWith(fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'ATTENDANCE DASHBOARD',
                  style: AdminTextStyles.portalTitle.copyWith(fontSize: 16),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AdminColors.primaryBackground,
                        AdminColors.secondaryBackground,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: AdminColors.primaryAccent),
                  onPressed: fetchAttendanceData,
                ),
              ],
            ),
          ];
        },
        body: isLoading
            ? _buildShimmerLoading()
            : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY\'S SUMMARY',
                style: AdminTextStyles.sectionHeader,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceCard(
                      'PRESENT',
                      presentCount,
                      AdminColors.successAccent,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildAttendanceCard(
                      'ABSENT',
                      absentCount,
                      AdminColors.dangerAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'STUDENT RECORDS',
                style: AdminTextStyles.sectionHeader,
              ),
              SizedBox(height: 16),
              ...attendanceList.map((student) => _buildStudentCard(student)).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchAttendanceData,
        child: isRefreshing
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryText),
        )
            : Icon(Icons.refresh, size: 28),
        backgroundColor: AdminColors.primaryAccent,
        elevation: 8,
      ),
    );
  }
}

class StudentAttendance {
  final int rfid;
  final String name;
  final String id;
  final bool isPresent;
  final String time;

  StudentAttendance({
    required this.rfid,
    required this.name,
    required this.id,
    required this.isPresent,
    required this.time,
  });
}