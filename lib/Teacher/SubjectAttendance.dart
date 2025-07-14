import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save attendance: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: ${e.toString()}'),
          backgroundColor: Colors.red,
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
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;
    final presentCount =
        attendanceStatus.values.where((status) => status == 'present').length;
    final absentCount = students.length - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Attendance',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudentsForSubject,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildDateSelector(theme, subjectColor),
          _buildAttendanceSummary(
            presentCount,
            absentCount,
            subjectColor,
          ),
          _buildQuickActions(theme, subjectColor),
          Expanded(
            child: students.isEmpty
                ? Center(
              child: Text(
                'No students enrolled in this subject',
                style: GoogleFonts.poppins(),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: students.length,
              itemBuilder: (context, index) =>
                  _buildStudentCard(
                    students[index],
                    theme,
                    subjectColor,
                  ),
            ),
          ),
          _buildSubmitButton(theme, subjectColor),
        ],
      ),
    );
  }
  Widget _buildDateSelector(ThemeData theme, Color subjectColor) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            color: subjectColor,
            onPressed: () => _changeDate(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                DateFormat('MMMM d, y').format(selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            color: subjectColor,
            onPressed: () => _changeDate(1),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
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
                      colorScheme: ColorScheme.light(
                        primary: subjectColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                      dialogBackgroundColor: Colors.white,
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

  Widget _buildAttendanceSummary(int present, int absent, Color subjectColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            subjectColor.withOpacity(0.8),
            subjectColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Present',
            present,
            Icons.check_circle,
            Colors.green,
          ),
          _buildSummaryItem('Absent', absent, Icons.cancel, Colors.red),
          _buildSummaryItem(
            'Total',
            students.length,
            Icons.people,
            subjectColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, Color subjectColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.check_circle, color: Colors.green),
              label: Text(
                'All Present',
                style: GoogleFonts.poppins(color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.green),
              ),
              onPressed: () => _setAllStatus('present'),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.cancel, color: Colors.red),
              label: Text(
                'All Absent',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.red),
              ),
              onPressed: () => _setAllStatus('absent'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
      Map<String, dynamic> student,
      ThemeData theme,
      Color subjectColor,
      ) {
    // Use rfid instead of id since that's what we used as the key
    final isPresent = attendanceStatus[student['rfid'].toString()] == 'present';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: subjectColor.withOpacity(0.2),
              radius: 20,
              child: Text(
                student['name'].isNotEmpty ? student['name'][0] : '?',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? 'Unknown Student',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ID: ${student['id'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              constraints: BoxConstraints(minWidth: 80, minHeight: 36),
              isSelected: [isPresent, !isPresent],
              onPressed: (index) {
                setState(() {
                  attendanceStatus[student['rfid'].toString()] =
                  index == 0 ? 'present' : 'absent';
                });
              },
              fillColor: isPresent ? Colors.green[50] : Colors.red[50],
              selectedColor: isPresent ? Colors.green : Colors.red,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16),
                      SizedBox(width: 4),
                      Text('Present'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 16),
                      SizedBox(width: 4),
                      Text('Absent'),
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

  Widget _buildSubmitButton(ThemeData theme, Color subjectColor) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: subjectColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              isSubmitting
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    'Submit Attendance',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }
}
