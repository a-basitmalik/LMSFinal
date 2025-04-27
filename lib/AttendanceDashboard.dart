import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/animation.dart';
import 'dart:math';
import 'MarkAttendance.dart';
import 'ViewAttendance.dart';
import 'EditAttendance.dart';


class AttendanceDashboard extends StatefulWidget {
  final int campusId;

  const AttendanceDashboard({Key? key, required this.campusId}) : super(key: key);

  @override
  _AttendanceDashboardState createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> with SingleTickerProviderStateMixin {
  String _userType = 'Student';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Student data
  int _studentPresent = 0;
  int _studentOnLeave = 0;
  int _studentAbsent = 0;
  int _totalStudents = 0;

  // Teacher data
  int _teacherPresent = 0;
  int _teacherOnLeave = 0;
  int _teacherAbsent = 0;
  int _totalTeachers = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _fetchAttendanceData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    final url = 'http://193.203.162.232:5050/attendance/get_attendance?campusId=${widget.campusId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Parse student data
          final studentData = data['student_data'];
          setState(() {
            _studentPresent = studentData['present_students'];
            _studentOnLeave = studentData['on_leave_students'];
            _studentAbsent = studentData['absent_students'];
            _totalStudents = studentData['total_students'];

            // Parse teacher data
            final teacherData = data['teacher_data'];
            _teacherPresent = teacherData['present_teachers'];
            _teacherOnLeave = teacherData['on_leave_teachers'];
            _teacherAbsent = teacherData['absent_teachers'];
            _totalTeachers = teacherData['total_teachers'];

            _isLoading = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load attendance data');
        }
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
  }

  void _handleMarkAttendance() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: MarkAttendanceScreen(
            campusId: widget.campusId,
            //userType: _userType,
          ),
        ),
      ),
    );
  }

  void _handleViewRecords() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: AttendanceDashboard2(
            campusID: widget.campusId,
            //userType: _userType,
          ),
        ),
      ),
    );
  }

  void _handleEditAttendance() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: EditAttendanceScreen(
            campusID: widget.campusId,
            userType: _userType,
          ),
        ),
      ),
    );
  }

  void _printAttendanceSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20), // ✅ Moved padding here
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withOpacity(0.9),
              Colors.indigo.shade900.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 40, color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text(
              'Generating $_userType Attendance Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    ); // ✅ This closing parenthesis was missing
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background with animated particles
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.blue.shade900.withOpacity(_fadeAnimation.value * 0.3),
                      Colors.indigo.shade900.withOpacity(_fadeAnimation.value * 0.3),
                      Colors.black,
                    ],
                    stops: [0.1, 0.5, 1.0],
                  ),
                ),
                child: CustomPaint(
                  painter: _ParticlePainter(animation: _animationController),
                ),
              );
            },
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        'ATTENDANCE DASHBOARD',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(_fadeAnimation.value),
                          shadows: [
                            Shadow(
                              blurRadius: 10 * _fadeAnimation.value,
                              color: Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade900.withOpacity(0.7),
                          Colors.indigo.shade800.withOpacity(0.7),
                          Colors.purple.shade900.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // User Type Selection
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECT USER TYPE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedChoiceChip(
                                      label: 'Student',
                                      selected: _userType == 'Student',
                                      onSelected: (selected) {
                                        setState(() {
                                          _userType = 'Student';
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: AnimatedChoiceChip(
                                      label: 'Teacher',
                                      selected: _userType == 'Teacher',
                                      onSelected: (selected) {
                                        setState(() {
                                          _userType = 'Teacher';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Action Buttons
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildHolographicButton(
                            icon: Icons.fingerprint,
                            label: 'Mark\nAttendance',
                            onTap: _handleMarkAttendance,
                            color: Colors.blueAccent,
                          ),
                          _buildHolographicButton(
                            icon: Icons.calendar_today,
                            label: 'View\nRecords',
                            onTap: _handleViewRecords,
                            color: Colors.purpleAccent,
                          ),
                          _buildHolographicButton(
                            icon: Icons.edit,
                            label: 'Edit\nAttendance',
                            onTap: _handleEditAttendance,
                            color: Colors.greenAccent,
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      // Student Overview
                      _buildOverviewSection(
                        title: 'STUDENT OVERVIEW',
                        present: _studentPresent,
                        onLeave: _studentOnLeave,
                        absent: _studentAbsent,
                        total: _totalStudents,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(height: 24),
                      // Teacher Overview
                      _buildOverviewSection(
                        title: 'TEACHER OVERVIEW',
                        present: _teacherPresent,
                        onLeave: _teacherOnLeave,
                        absent: _teacherAbsent,
                        total: _totalTeachers,
                        color: Colors.purpleAccent,
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _printAttendanceSummary,
        icon: Icon(Icons.print, color: Colors.black),
        label: Text('PRINT SUMMARY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.cyanAccent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildHolographicButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fadeAnimation.value,
          child: GlassCard(
            borderColor: color.withOpacity(0.5),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color.withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4 * _fadeAnimation.value),
                            blurRadius: 10 * _fadeAnimation.value,
                            spreadRadius: 2 * _fadeAnimation.value,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: color.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewSection({
    required String title,
    required int present,
    required int onLeave,
    required int absent,
    required int total,
    required Color color,
  }) {
    final presentPercentage = total > 0 ? (present / total * 100).round() : 0;
    final onLeavePercentage = total > 0 ? (onLeave / total * 100).round() : 0;
    final absentPercentage = total > 0 ? (absent / total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _buildHolographicStatCard(
              value: presentPercentage,
              label: 'PRESENT',
              count: '$present/$total',
              color: Colors.greenAccent,
            ),
            SizedBox(width: 12),
            _buildHolographicStatCard(
              value: onLeavePercentage,
              label: 'ON LEAVE',
              count: '$onLeave/$total',
              color: Colors.orangeAccent,
            ),
            SizedBox(width: 12),
            _buildHolographicStatCard(
              value: absentPercentage,
              label: 'ABSENT',
              count: '$absent/$total',
              color: Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHolographicStatCard({
    required int value,
    required String label,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        borderColor: color.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedCircularProgress(
                      value: value / 100,
                      color: color,
                      animation: _animationController,
                    ),
                    Text(
                      '$value%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: color.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Widgets for Futuristic Design
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderColor,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class AnimatedChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const AnimatedChoiceChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: selected
            ? LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.7),
            Colors.blueAccent.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        border: Border.all(
          color: selected ? Colors.cyanAccent : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCircularProgress extends StatelessWidget {
  final double value;
  final Color color;
  final Animation<double> animation;

  const AnimatedCircularProgress({
    Key? key,
    required this.value,
    required this.color,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 * animation.value),
                blurRadius: 10 * animation.value,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = Random(42);
    final particleCount = 30;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 2;
      final opacity = 0.2 + random.nextDouble() * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + 0.4 * animation.value),
        paint..color = Colors.cyanAccent.withOpacity(opacity * animation.value),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// // Placeholder screens with futuristic design
// class MarkAttendanceScreen extends StatelessWidget {
//   final int campusId;
//   final String userType;
//
//   const MarkAttendanceScreen({
//     Key? key,
//     required this.campusId,
//     required this.userType,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'Mark $userType Attendance',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: RadialGradient(
//             center: Alignment.center,
//             radius: 1.5,
//             colors: [
//               Colors.blue.shade900.withOpacity(0.7),
//               Colors.indigo.shade900.withOpacity(0.7),
//               Colors.black,
//             ],
//           ),
//         ),
//         child: Center(
//           child: GlassCard(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Text(
//                 'Mark $userType Attendance Screen',
//                 style: TextStyle(color: Colors.white, fontSize: 20),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ViewAttendanceScreen extends StatelessWidget {
//   final int campusId;
//   final String userType;
//
//   const ViewAttendanceScreen({
//     Key? key,
//     required this.campusId,
//     required this.userType,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'View $userType Records',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: RadialGradient(
//             center: Alignment.center,
//             radius: 1.5,
//             colors: [
//               Colors.blue.shade900.withOpacity(0.7),
//               Colors.indigo.shade900.withOpacity(0.7),
//               Colors.black,
//             ],
//           ),
//         ),
//         child: Center(
//           child: GlassCard(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Text(
//                 'View $userType Records Screen',
//                 style: TextStyle(color: Colors.white, fontSize: 20),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class EditAttendanceScreen extends StatelessWidget {
//   final int campusId;
//   final String userType;
//
//   const EditAttendanceScreen({
//     Key? key,
//     required this.campusId,
//     required this.userType,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'Edit $userType Attendance',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: RadialGradient(
//             center: Alignment.center,
//             radius: 1.5,
//             colors: [
//               Colors.blue.shade900.withOpacity(0.7),
//               Colors.indigo.shade900.withOpacity(0.7),
//               Colors.black,
//             ],
//           ),
//         ),
//         child: Center(
//           child: GlassCard(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Text(
//                 'Edit $userType Attendance Screen',
//                 style: TextStyle(color: Colors.white, fontSize: 20),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }