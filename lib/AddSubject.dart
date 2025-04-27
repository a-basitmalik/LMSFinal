import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddSubjectScreen extends StatefulWidget {
  final int campusId;
  final String campusName;

  const AddSubjectScreen({
    Key? key,
    required this.campusId,
    required this.campusName,
  }) : super(key: key);

  @override
  _AddSubjectScreenState createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  List<Teacher> _teachers = [];
  Teacher? _selectedTeacher;
  List<TimeSlot> _timeSlots = [];
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
    _loadTeachers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subjectNameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://193.203.162.232:5050/subject/api/teachers');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _teachers = data.map((teacher) => Teacher.fromJson(teacher)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load teachers');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading teachers: ${e.toString()}');
    }
  }

  Future<void> _showAddTimeSlotDialog() async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final selectedDays = <String>[];
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) => HolographicDialog(
        title: 'Add Time Slot',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Days:', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: selectedDays.contains(day),
                  onSelected: (selected) {
                    if (selected) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  },
                  selectedColor: Colors.cyanAccent,
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(
                    color: selectedDays.contains(day) ? Colors.black : Colors.white,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Select Time:', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  selectedTime = time;
                }
              },
              child: Text(
                selectedTime != null
                    ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select Time',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        buttonText: 'Add',
        onPressed: () {
          if (selectedDays.isEmpty) {
            _showErrorDialog('Please select at least one day');
            return;
          }
          if (selectedTime == null) {
            _showErrorDialog('Please select a time');
            return;
          }

          final timeStr = '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}';
          for (final day in selectedDays) {
            _addTimeSlot(day, timeStr);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addTimeSlot(String day, String time) {
    setState(() {
      _timeSlots.add(TimeSlot(day: day, time: time));
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacher == null) {
      _showErrorDialog('Please select a teacher');
      return;
    }
    if (_timeSlots.isEmpty) {
      _showErrorDialog('Please add at least one time slot');
      return;
    }

    setState(() => _isLoading = true);

    final subjectData = {
      "subject_name": _subjectNameController.text,
      "time_slots": _timeSlots.map((slot) => {
        "day": slot.day,
        "time": slot.time,
      }).toList(),
      "teacher_id": _selectedTeacher!.id,
      "teacher_name": _selectedTeacher!.name,
      "campus_id": widget.campusId,
      "campus_name": widget.campusName,
      "year": int.parse(_yearController.text),
    };

    final url = Uri.parse('http://193.203.162.232:5050/subject/api/add_subject');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(subjectData),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog('Subject added successfully!');
        Navigator.pop(context);
      } else {
        throw Exception('Failed to add subject');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error adding subject: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => HolographicDialog(
        title: 'Error',
        content: message,
        buttonText: 'OK',
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => HolographicDialog(
        title: 'Success',
        content: message,
        buttonText: 'OK',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        'ADD NEW SUBJECT',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Name
                        GlassInputField(
                          controller: _subjectNameController,
                          label: 'Subject Name',
                          icon: Icons.book,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter subject name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Teacher Dropdown
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TEACHER',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                DropdownButtonFormField<Teacher>(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  items: _teachers.map((teacher) {
                                    return DropdownMenuItem<Teacher>(
                                      value: teacher,
                                      child: Text(
                                        teacher.name,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (teacher) {
                                    setState(() {
                                      _selectedTeacher = teacher;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a teacher';
                                    }
                                    return null;
                                  },
                                  hint: Text(
                                    'Select teacher',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  dropdownColor: Colors.grey[900],
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                  value: _selectedTeacher,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Year
                        GlassInputField(
                          controller: _yearController,
                          label: 'Year',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter year';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 1 || year > 4) {
                              return 'Year must be between 1 and 4';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 24),

                        // Time Slots Section
                        Text(
                          'TIME SLOTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                        if (_timeSlots.isEmpty)
                          Text(
                            'No time slots added yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_timeSlots.length, (index) {
                            final slot = _timeSlots[index];
                            return Chip(
                              label: Text('${slot.day} at ${slot.time}'),
                              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                              deleteIcon: Icon(Icons.close, size: 18),
                              onDeleted: () => _removeTimeSlot(index),
                              labelStyle: TextStyle(color: Colors.white),
                            );
                          }),
                        ),

                        SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _showAddTimeSlotDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.cyanAccent,
                            minimumSize: Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.cyanAccent, width: 1),
                          ),
                          child: Text(
                            'ADD DAY AND TIME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _submitForm,
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
                            'ADD SUBJECT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    );
  }
}

// Models
class Teacher {
  final int id;
  final String name;

  Teacher({required this.id, required this.name});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      name: json['name'],
    );
  }
}

class TimeSlot {
  final String day;
  final String time;

  TimeSlot({required this.day, required this.time});
}

// Custom Widgets
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

class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const GlassInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            icon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

class HolographicDialog extends StatelessWidget {
  final String title;
  final dynamic content;
  final String buttonText;
  final VoidCallback? onPressed;

  const HolographicDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonText,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              if (content is String)
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (content is Widget)
                content,
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onPressed ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  minimumSize: Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}