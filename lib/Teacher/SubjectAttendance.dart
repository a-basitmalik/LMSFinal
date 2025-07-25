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

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  bool isLoading = true;
  bool isSubmitting = false;
  DateTime selectedDate = DateTime.now();
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://193.203.162.232:5050/SubjectAttendance/api';
  // Dummy data for students
  final List<Map<String, dynamic>> _dummyStudents = [
    {'id': '101', 'name': 'Alice Johnson', 'avatar': '👩'},
    {'id': '102', 'name': 'Bob Smith', 'avatar': '👨'},
    {'id': '103', 'name': 'Charlie Brown', 'avatar': '👦'},
    {'id': '104', 'name': 'Diana Prince', 'avatar': '👩'},
    {'id': '105', 'name': 'Ethan Hunt', 'avatar': '👨'},
    {'id': '106', 'name': 'Fiona Green', 'avatar': '👩'},
    {'id': '107', 'name': 'George Wilson', 'avatar': '👨'},
    {'id': '108', 'name': 'Hannah Baker', 'avatar': '👩'},
    {'id': '109', 'name': 'Ian Cooper', 'avatar': '👨'},
    {'id': '110', 'name': 'Jessica Lee', 'avatar': '👩'},
  ];

  // Dummy attendance data for different dates
  final Map<String, List<Map<String, dynamic>>> _dummyAttendanceData = {
    '2023-06-15': [
      {'student_id': '101', 'status': 'present'},
      {'student_id': '102', 'status': 'absent'},
      {'student_id': '103', 'status': 'present'},
      {'student_id': '104', 'status': 'present'},
      {'student_id': '105', 'status': 'absent'},
      {'student_id': '106', 'status': 'present'},
      {'student_id': '107', 'status': 'present'},
      {'student_id': '108', 'status': 'absent'},
      {'student_id': '109', 'status': 'present'},
      {'student_id': '110', 'status': 'present'},
    ],
    '2023-06-16': [
      {'student_id': '101', 'status': 'present'},
      {'student_id': '102', 'status': 'present'},
      {'student_id': '103', 'status': 'absent'},
      {'student_id': '104', 'status': 'present'},
      {'student_id': '105', 'status': 'present'},
      {'student_id': '106', 'status': 'absent'},
      {'student_id': '107', 'status': 'present'},
      {'student_id': '108', 'status': 'present'},
      {'student_id': '109', 'status': 'absent'},
      {'student_id': '110', 'status': 'present'},
    ],
    '2023-06-17': [
      {'student_id': '101', 'status': 'absent'},
      {'student_id': '102', 'status': 'present'},
      {'student_id': '103', 'status': 'present'},
      {'student_id': '104', 'status': 'absent'},
      {'student_id': '105', 'status': 'present'},
      {'student_id': '106', 'status': 'present'},
      {'student_id': '107', 'status': 'absent'},
      {'student_id': '108', 'status': 'present'},
      {'student_id': '109', 'status': 'present'},
      {'student_id': '110', 'status': 'absent'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentsForSubject();
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

          // Initialize all as absent by default
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

  void _loadDummyAttendanceForDate() {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    if (_dummyAttendanceData.containsKey(dateKey)) {
      setState(() {
        for (var record in _dummyAttendanceData[dateKey]!) {
          attendanceStatus[record['student_id']] = record['status'];
        }
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

        // Initialize with all absent first
        final newStatus = <String, String>{};
        for (var student in students) {
          newStatus[student['rfid'].toString()] = 'absent';
        }

        // Update with fetched data
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
        // No attendance records for this date
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
        // Fallback to all absent if there's an error
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
      } else {
        throw Exception('Failed to save attendance: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _fetchAttendanceForDate();
    });
  }

  void _setAllStatus(String status) {
    setState(() {
      attendanceStatus.updateAll((key, value) => status);
    });
  }
  @override
  Widget build(BuildContext context) {
    final presentCount = attendanceStatus.values.where((status) => status == 'present').length;
    final absentCount = students.length - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Attendance',
          style: TeacherTextStyles.className.copyWith(color: TeacherColors.primaryText),
        ),
        backgroundColor: TeacherColors.chatColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: TeacherColors.primaryAccent,
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
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
              onPressed: _fetchStudentsForSubject,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildDateSelector(),
          _buildAttendanceSummary(presentCount, absentCount),
          _buildQuickActions(),
          Expanded(
            child: students.isEmpty
                ? Center(
              child: Text(
                'No students enrolled in this subject',
                style: TeacherTextStyles.cardSubtitle,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: students.length,
              itemBuilder: (context, index) => _buildStudentCard(students[index]),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }


  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: TeacherColors.glassDecoration(
        borderColor: TeacherColors.cardBorder,
        borderRadius: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: TeacherColors.primaryAccent,
            onPressed: () => _changeDate(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: TeacherTextStyles.sectionHeader,
              ),
              Text(
                DateFormat('MMMM d, y').format(selectedDate),
                style: TeacherTextStyles.cardSubtitle,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: TeacherColors.primaryAccent,
            onPressed: () => _changeDate(1),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: TeacherColors.primaryAccent,
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2025),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: TeacherColors.chatColor,
                        onPrimary: TeacherColors.primaryText,
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
    );
  }

  Widget _buildAttendanceSummary(int present, int absent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: TeacherColors.accentGradient(TeacherColors.chatColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Present', present, Icons.check_circle, TeacherColors.successAccent),
          _buildSummaryItem('Absent', absent, Icons.cancel, TeacherColors.dangerAccent),
          _buildSummaryItem('Total', students.length, Icons.people, TeacherColors.primaryAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TeacherColors.glassEffectLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TeacherTextStyles.statValue.copyWith(color: color),
        ),
        Text(
          label,
          style: TeacherTextStyles.statLabel,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.check_circle, color: TeacherColors.successAccent),
              label: Text(
                'All Present',
                style: TeacherTextStyles.secondaryButton.copyWith(color: TeacherColors.successAccent),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: TeacherColors.successAccent),
              ),
              onPressed: () => _setAllStatus('present'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.cancel, color: TeacherColors.dangerAccent),
              label: Text(
                'All Absent',
                style: TeacherTextStyles.secondaryButton.copyWith(color: TeacherColors.dangerAccent),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: TeacherColors.dangerAccent),
              ),
              onPressed: () => _setAllStatus('absent'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isPresent = attendanceStatus[student['rfid'].toString()] == 'present';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: TeacherColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: TeacherColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: TeacherColors.accentGradient(TeacherColors.chatColor),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                student['name'].isNotEmpty ? student['name'][0] : '?',
                style: TeacherTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? 'Unknown Student',
                    style: TeacherTextStyles.listItemTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${student['id'] ?? 'N/A'}',
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                ],
              ),
            ),
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
              isSelected: [isPresent, !isPresent],
              onPressed: (index) {
                setState(() {
                  attendanceStatus[student['rfid'].toString()] = index == 0 ? 'present' : 'absent';
                });
              },
              fillColor: isPresent
                  ? TeacherColors.successAccent.withOpacity(0.1)
                  : TeacherColors.dangerAccent.withOpacity(0.1),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherColors.chatColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryText),
            ),
          )
              : Text(
            'Submit Attendance',
            style: TeacherTextStyles.primaryButton.copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}