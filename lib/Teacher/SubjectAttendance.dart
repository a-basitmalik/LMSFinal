import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SubjectAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectAttendanceScreen({super.key, required this.subject});

  @override
  _SubjectAttendanceScreenState createState() =>
      _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  bool isLoading = true;
  bool isSubmitting = false;
  DateTime selectedDate = DateTime.now();

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
    _loadDummyData();
  }

  void _loadDummyData() {
    setState(() {
      students = _dummyStudents;
      // Initialize all as present by default
      attendanceStatus = {
        for (var student in students) student['id']: 'present',
      };
      isLoading = false;
    });
    _loadDummyAttendanceForDate();
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

  void _submitAttendance() {
    setState(() => isSubmitting = true);

    // Simulate API call delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Update our dummy data with the new attendance
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      _dummyAttendanceData[dateKey] =
          attendanceStatus.entries.map((entry) {
            return {'student_id': entry.key, 'status': entry.value};
          }).toList();
    });
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _loadDummyAttendanceForDate();
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
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
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: students.length,
                      itemBuilder:
                          (context, index) => _buildStudentCard(
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
            onPressed: () => _changeDate(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMMM d, y').format(selectedDate),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () => _changeDate(1),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2025),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                  _loadDummyAttendanceForDate();
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
    final isPresent = attendanceStatus[student['id']] == 'present';

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
              child: Text(student['avatar'], style: TextStyle(fontSize: 16)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ID: ${student['id']}',
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
                  attendanceStatus[student['id']] =
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
