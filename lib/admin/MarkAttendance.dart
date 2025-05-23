import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final int campusId;

  const MarkAttendanceScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String _baseUrl = "http://193.203.162.232:5050/attendance/get_unmarked_attendees";

  List<String> _classes = ["First Year", "Second Year"];
  String? _selectedClass;
  DateTime? _selectedDate;
  List<StudentAttendance> _students = [];
  bool _isLoading = false;

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
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
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
        backgroundColor: Colors.redAccent,
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
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF121212),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Animated Background
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
                          'MARK ATTENDANCE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 10 * _fadeAnimation.value,
                                color: Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                              ),
                            ],
                            color: Colors.white.withOpacity(_fadeAnimation.value),
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
                        // Date and Class Selection
                        GlassCard(
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
                                        labelStyle: TextStyle(color: Colors.grey[400]),
                                        prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[400]),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                      ),
                                      controller: TextEditingController(
                                        text: _selectedDate != null
                                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                            : 'Select Date',
                                      ),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Class Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'CLASS',
                                    labelStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(Icons.class_, color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                  ),
                                  value: _selectedClass,
                                  items: _classes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedClass = value);
                                    final year = value == "First Year" ? 1 : 2;
                                    _loadUnmarkedStudents(year);
                                  },
                                  dropdownColor: Colors.grey[900],
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                  hint: Text(
                                    'Select Class',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Students List
                        if (_students.isNotEmpty)
                          Text(
                            'STUDENTS LIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (_students.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final student = _students[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: GlassCard(
                            child: ListTile(
                              title: Text(
                                student.name,
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'RFID: ${student.rfid}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: Transform.scale(
                                scale: 1.3,
                                child: Switch(
                                  value: student.isPresent,
                                  activeColor: Colors.cyanAccent,
                                  inactiveThumbColor: Colors.grey[600],
                                  inactiveTrackColor: Colors.grey[800],
                                  onChanged: (value) {
                                    setState(() {
                                      _students[index] = student.copyWith(isPresent: value);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _students.length,
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _markPresent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'SAVE ATTENDANCE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),

            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              ),
          ],
        ),
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

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? borderColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
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