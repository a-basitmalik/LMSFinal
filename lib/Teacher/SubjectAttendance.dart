import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';

class SubjectAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectAttendanceScreen({super.key, required this.subject});

  @override
  _SubjectAttendanceScreenState createState() => _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  bool isLoading = true;
  bool isSubmitting = false;
  DateTime selectedDate = DateTime.now();
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String baseUrl = 'http://193.203.162.232:5050/SubjectAttendance/api';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _fetchStudentsForSubject();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentsForSubject() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/students'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          students = data.map((student) {
            return {
              'rfid': student['rfid']?.toString() ?? '',
              'name': student['student_name']?.toString() ?? 'Unknown Student',
              'id': student['student_id']?.toString() ?? 'N/A',
            };
          }).toList();

          attendanceStatus = {
            for (var student in students)
              student['rfid'].toString(): 'absent',
          };
        });
        await _fetchAttendanceForDate();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading students: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAttendanceForDate() async {
    if (students.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await http.get(
        Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/attendance?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final newStatus = <String, String>{};
        for (var student in students) {
          newStatus[student['rfid'].toString()] = 'absent';
        }

        for (var record in data) {
          final rfid = record['rfid']?.toString();
          if (rfid != null && newStatus.containsKey(rfid)) {
            newStatus[rfid] = record['attendance_status'] ?? 'absent';
          }
        }

        setState(() {
          attendanceStatus = newStatus;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          attendanceStatus = {
            for (var student in students)
              student['rfid'].toString(): 'absent'
          };
        });
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading attendance: ${e.toString()}';
        attendanceStatus = {
          for (var student in students)
            student['rfid'].toString(): 'absent'
        };
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => isSubmitting = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final attendanceRecords = attendanceStatus.entries.map((entry) {
        return {
          'rfid': int.parse(entry.key),
          'subject_id': widget.subject['subject_id'],
          'date': dateStr,
          'attendance_status': entry.value,
          'time': DateFormat('HH:mm:ss').format(DateTime.now()),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'date': dateStr,
          'records': attendanceRecords,
        }),
      );

      if (response.statusCode == 200) {
        _showAnimatedSnackBar(
          'Attendance saved successfully!',
          TeacherColors.successAccent,
          Icons.check_circle,
        );
      } else {
        throw Exception('Failed to save attendance: ${response.statusCode}');
      }
    } catch (e) {
      _showAnimatedSnackBar(
        'Failed to save attendance: ${e.toString()}',
        TeacherColors.dangerAccent,
        Icons.error,
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showAnimatedSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 10,
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _fetchAttendanceForDate();
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _setAllStatus(String status) {
    setState(() {
      attendanceStatus.updateAll((key, value) => status);
    });
  }

// Replace the entire build method with this corrected version
  @override
  Widget build(BuildContext context) {
    final presentCount = attendanceStatus.values.where((status) => status == 'present').length;
    final absentCount = students.length - presentCount;
    final subjectColor = _getColorForSubject(widget.subject['subject_id']);

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          );
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.subject['name']} Attendance',
                  style: TeacherTextStyles.className.copyWith(
                    color: TeacherColors.primaryText,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        subjectColor.withOpacity(0.8),
                        subjectColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: subjectColor,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else if (errorMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: GlassCard(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: TeacherColors.dangerAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: TeacherColors.dangerAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildAnimatedButton(
                          icon: Icons.refresh,
                          label: 'Retry',
                          color: subjectColor,
                          onTap: _fetchStudentsForSubject,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildDateSelector(subjectColor),
                      const SizedBox(height: 16),
                      _buildAttendanceSummary(presentCount, absentCount, subjectColor),
                      const SizedBox(height: 16),
                      _buildQuickActions(subjectColor),
                      const SizedBox(height: 8),
                      if (students.isEmpty)
                        GlassCard(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No students enrolled in this subject',
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (students.isNotEmpty) _buildStudentList(subjectColor),
                SliverToBoxAdapter(
                  child: _buildSubmitButton(subjectColor),
                ),
              ],
          ],
        ),
      ),
    );
  }

// Replace the _buildStudentList method with this version
  Widget _buildStudentList(Color subjectColor) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final student = students[index];
          return _buildStudentCard(student, subjectColor);
        },
        childCount: students.length,
      ),
    );
  }

  Widget _buildDateSelector(Color subjectColor) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: subjectColor,
              onPressed: () => _changeDate(-1),
            ),
            Column(
              children: [
                Text(
                  DateFormat('EEEE').format(selectedDate),
                  style: TeacherTextStyles.sectionHeader.copyWith(color: TeacherColors.primaryText),
                ),
                Text(
                  DateFormat('MMMM d, y').format(selectedDate),
                  style: TeacherTextStyles.cardSubtitle.copyWith(color: TeacherColors.primaryText),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: subjectColor,
              onPressed: () => _changeDate(1),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: subjectColor,
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2025),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: subjectColor,
                          onPrimary: TeacherColors.primaryBackground,
                          surface: TeacherColors.secondaryBackground,
                          onSurface: TeacherColors.primaryText,
                        ),
                        dialogBackgroundColor: TeacherColors.primaryBackground,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                    _fetchAttendanceForDate();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary(int present, int absent, Color subjectColor) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Present', present, Icons.check_circle, TeacherColors.successAccent),
            _buildSummaryItem('Absent', absent, Icons.cancel, TeacherColors.dangerAccent),
            _buildSummaryItem('Total', students.length, Icons.people, subjectColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TeacherTextStyles.statValue.copyWith(color: color),
        ),
        Text(
          label,
          style: TeacherTextStyles.statLabel.copyWith(color:TeacherColors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildAnimatedButton(
              icon: Icons.check_circle,
              label: 'All Present',
              color: TeacherColors.successAccent,
              onTap: () => _setAllStatus('present'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAnimatedButton(
              icon: Icons.cancel,
              label: 'All Absent',
              color: TeacherColors.dangerAccent,
              onTap: () => _setAllStatus('absent'),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildStudentCard(Map<String, dynamic> student, Color subjectColor) {
    final isPresent = attendanceStatus[student['rfid'].toString()] == 'present';

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    subjectColor.withOpacity(0.8),
                    subjectColor.withOpacity(0.4),
                  ],
                ),
              ),
              child: Text(
                student['name'].isNotEmpty ? student['name'][0] : '?',
                style: TeacherTextStyles.cardTitle.copyWith(
                  fontSize: 16,
                  color: TeacherColors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? 'Unknown Student',
                    style: TeacherTextStyles.listItemTitle.copyWith(color: TeacherColors.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${student['id'] ?? 'N/A'}',
                    style: TeacherTextStyles.listItemSubtitle.copyWith(color: TeacherColors.secondaryText),
                  ),
                ],
              ),
            ),
            GlassCard(
              borderRadius: 8,
              borderColor: isPresent
                  ? TeacherColors.successAccent.withOpacity(0.3)
                  : TeacherColors.dangerAccent.withOpacity(0.3),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                isSelected: [isPresent, !isPresent],
                onPressed: (index) {
                  setState(() {
                    attendanceStatus[student['rfid'].toString()] = index == 0 ? 'present' : 'absent';
                  });
                },
                fillColor: Colors.transparent,
                selectedColor: isPresent ? TeacherColors.successAccent : TeacherColors.dangerAccent,
                color: TeacherColors.secondaryText,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 16),
                        const SizedBox(width: 4),
                        Text('Present', style: TeacherTextStyles.secondaryButton),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 16),
                        const SizedBox(width: 4),
                        Text('Absent', style: TeacherTextStyles.secondaryButton),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildAnimatedButton(
        icon: Icons.save,
        label: 'Submit Attendance',
        color: color,
        onTap: isSubmitting ? null : _submitAttendance,
      ),
    );
  }

  Widget _buildAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isDisabled ? 0.1 : 0.3),
              color.withOpacity(isDisabled ? 0.05 : 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDisabled ? 0.2 : 0.5),
            width: 1,
          ),
          boxShadow: isDisabled
              ? []
              : [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: color.withOpacity(0.2),
            highlightColor: color.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDisabled)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  else
                    Icon(icon, color: color.withOpacity(isDisabled ? 0.5 : 1.0), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TeacherTextStyles.primaryButton.copyWith(
                      color: color.withOpacity(isDisabled ? 0.5 : 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForSubject(int subjectId) {
    final colors = [
      TeacherColors.classColor,
      TeacherColors.studentColor,
      TeacherColors.assignmentColor,
      TeacherColors.gradeColor,
      TeacherColors.scheduleColor,
      TeacherColors.announcementColor,
    ];
    return colors[subjectId % colors.length];
  }
}

class GlassCard extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    Key? key,
    this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor?.withOpacity(0.3) ?? Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
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