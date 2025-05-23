import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:shimmer/shimmer.dart';


void main() {
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoAttendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0A0E21),
        primaryColor: Color(0xFF00D1FF),
        colorScheme: ColorScheme.dark(
          secondary: Color(0xFF00D1FF),
          surface: Color(0xFF1D1E33),
        ),
        cardTheme: CardTheme(
          elevation: 8,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
      home: AttendanceDashboard2(campusID: 1),
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

class AttendanceDashboard2 extends StatefulWidget {
  final int campusID;

  const AttendanceDashboard2({Key? key, required this.campusID}) : super(key: key);

  @override
  _AttendanceDashboardState2 createState() => _AttendanceDashboardState2();
}

class _AttendanceDashboardState2 extends State<AttendanceDashboard2> with SingleTickerProviderStateMixin {
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
          backgroundColor: Colors.redAccent,
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
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Column(
        children: List.generate(
          5,
              (index) => Card(
            child: Container(
              height: 80,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(String title, int count, Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        color: Color(0xFF1D1E33),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
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

  Widget _buildStudentCard(StudentAttendance student) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: student.isPresent
              ? Colors.greenAccent.withOpacity(0.2)
              : Colors.redAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: student.isPresent
                  ? [Color(0xFF00D1FF), Color(0xFF00FFA3)]
                  : [Color(0xFFFF416C), Color(0xFFFF4B2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              student.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          student.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'ID: ${student.rfid}',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: student.isPresent
                  ? [Color(0xFF00D1FF), Color(0xFF00FFA3)]
                  : [Color(0xFFFF416C), Color(0xFFFF4B2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            student.isPresent ? 'PRESENT' : 'ABSENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A0E21),
                        Color(0xFF1A1C2E),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceCard(
                      'PRESENT',
                      presentCount,
                      Color(0xFF00FFA3),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildAttendanceCard(
                      'ABSENT',
                      absentCount,
                      Color(0xFFFF416C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'STUDENT RECORDS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 1.5,
                ),
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : Icon(Icons.refresh, size: 28),
        backgroundColor: Color(0xFF00D1FF),
        elevation: 8,
      ),
    );
  }
}