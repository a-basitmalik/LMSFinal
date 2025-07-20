import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
class MarkAttendanceScreen extends StatefulWidget {
  final int campusId;

  const MarkAttendanceScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final String _baseUrl = "http://193.203.162.232:5050/attendance/get_unmarked_attendees";

  List<String> _classes = ["First Year", "Second Year"];
  String? _selectedClass;
  DateTime? _selectedDate;
  List<StudentAttendance> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _loadUnmarkedStudents(int year) async {
    setState(() => _isLoading = true);

    final url = Uri.parse('$_baseUrl?campus_id=${widget.campusId}&year=$year');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<StudentAttendance> students = [];
          for (var student in data['unmarked_students']) {
            students.add(StudentAttendance(
              rfid: student['rfid'],
              name: student['student_name'],
              isPresent: false,
            ));
          }
          setState(() => _students = students);
        } else {
          _showError('Failed to load students');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markPresent() async {
    final presentStudents = _students.where((s) => s.isPresent).map((s) => s.rfid).toList();

    if (presentStudents.isEmpty) {
      _showError('No students marked as present');
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('http://193.203.162.232:5050/attendance/mark_present');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'students': presentStudents}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccess('Attendance marked successfully!');
          Navigator.pop(context);
        } else {
          _showError('Failed to mark attendance');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AdminColors.primaryAccent,
              onPrimary: AdminColors.primaryBackground,
              surface: AdminColors.secondaryBackground,
              onSurface: AdminColors.primaryText,
            ),
            dialogBackgroundColor: AdminColors.primaryBackground,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.successAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text('Mark Attendance', style: AdminTextStyles.sectionHeader),
        backgroundColor: AdminColors.secondaryBackground,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background with subtle gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AdminColors.primaryBackground,
                  AdminColors.secondaryBackground,
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Class Selection Card
                Container(
                  decoration: AdminColors.glassDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Date Picker
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'DATE',
                                labelStyle: AdminTextStyles.cardSubtitle,
                                prefixIcon: Icon(Icons.calendar_today,
                                    color: AdminColors.secondaryText),
                                filled: true,
                                fillColor: AdminColors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: TextEditingController(
                                text: _selectedDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                    : 'Select Date',
                              ),
                              style: AdminTextStyles.cardTitle,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Class Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'CLASS',
                            labelStyle: AdminTextStyles.cardSubtitle,
                            prefixIcon: Icon(Icons.class_,
                                color: AdminColors.secondaryText),
                            filled: true,
                            fillColor: AdminColors.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: _selectedClass,
                          items: _classes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: AdminTextStyles.cardTitle,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedClass = value);
                            final year = value == "First Year" ? 1 : 2;
                            _loadUnmarkedStudents(year);
                          },
                          dropdownColor: AdminColors.secondaryBackground,
                          icon: Icon(Icons.arrow_drop_down,
                              color: AdminColors.primaryText),
                          hint: Text(
                            'Select Class',
                            style: AdminTextStyles.cardSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Students List Header
                if (_students.isNotEmpty)
                  Text(
                    'STUDENTS LIST',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.attendanceColor,
                    ),
                  ),

                const SizedBox(height: 16),

                // Students List
                if (_students.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AdminColors.glassDecoration(),
                          child: ListTile(
                            title: Text(
                              student.name,
                              style: AdminTextStyles.cardTitle,
                            ),
                            subtitle: Text(
                              'RFID: ${student.rfid}',
                              style: AdminTextStyles.cardSubtitle,
                            ),
                            trailing: Switch(
                              value: student.isPresent,
                              activeColor: AdminColors.attendanceColor,
                              inactiveThumbColor: AdminColors.disabledText,
                              inactiveTrackColor: AdminColors.cardBackground,
                              onChanged: (value) {
                                setState(() {
                                  _students[index] = student.copyWith(isPresent: value);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Save Button (positioned at bottom)
          if (_students.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _markPresent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.attendanceColor,
                  foregroundColor: AdminColors.primaryText,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'SAVE ATTENDANCE',
                  style: AdminTextStyles.primaryButton,
                ),
              ),
            ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AdminColors.primaryAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class StudentAttendance {
  final int rfid;
  final String name;
  final bool isPresent;

  StudentAttendance({
    required this.rfid,
    required this.name,
    this.isPresent = false,
  });

  StudentAttendance copyWith({
    int? rfid,
    String? name,
    bool? isPresent,
  }) {
    return StudentAttendance(
      rfid: rfid ?? this.rfid,
      name: name ?? this.name,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}