import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';

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

class _AddSubjectScreenState extends State<AddSubjectScreen> {
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
    _loadTeachers();
  }

  @override
  void dispose() {
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
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.primaryBackground,
        title: Text(
          'Add Time Slot',
          style: AdminTextStyles.sectionHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Days:', style: AdminTextStyles.cardSubtitle),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: selectedDays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: AdminColors.primaryAccent,
                  checkmarkColor: AdminColors.primaryBackground,
                  labelStyle: AdminTextStyles.cardSubtitle.copyWith(
                    color: selectedDays.contains(day)
                        ? AdminColors.primaryBackground
                        : AdminColors.primaryText,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Select Time:', style: AdminTextStyles.cardSubtitle),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
              child: Text(
                selectedTime != null
                    ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select Time',
                style: AdminTextStyles.primaryButton,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryAccent,
                foregroundColor: AdminColors.primaryBackground,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AdminTextStyles.secondaryButton),
          ),
          ElevatedButton(
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
            child: Text('Add', style: AdminTextStyles.primaryButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primaryAccent,
              foregroundColor: AdminColors.primaryBackground,
            ),
          ),
        ],
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
        _subjectNameController.clear();
        _yearController.clear();
        setState(() {
          _selectedTeacher = null;
          _timeSlots.clear();
        });
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
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.primaryBackground,
        title: Text('Error', style: AdminTextStyles.sectionHeader),
        content: Text(message, style: AdminTextStyles.cardSubtitle),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style:AdminTextStyles.primaryButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.dangerAccent,
              foregroundColor: AdminColors.primaryBackground,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.primaryBackground,
        title: Text('Success', style: AdminTextStyles.sectionHeader),
        content: Text(message, style: AdminTextStyles.cardSubtitle),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AdminTextStyles.primaryButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.successAccent,
              foregroundColor: AdminColors.primaryBackground,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Add New Subject',
          style: AdminTextStyles.sectionHeader.copyWith(color: AdminColors.primaryText),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminColors.curriculumColor.withOpacity(0.2),
                AdminColors.primaryAccent.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Name
                  Container(
                    decoration: AdminColors.glassDecoration(),
                    child: TextFormField(
                      controller: _subjectNameController,
                      style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Subject Name',
                        labelStyle: AdminTextStyles.cardSubtitle,
                        prefixIcon: Icon(Icons.book, color: AdminColors.secondaryText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subject name';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // Teacher Dropdown
                  Container(
                    decoration: AdminColors.glassDecoration(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEACHER',
                            style: AdminTextStyles.cardSubtitle,
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
                                  style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
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
                              style: AdminTextStyles.cardSubtitle,
                            ),
                            dropdownColor: AdminColors.secondaryBackground,
                            icon: Icon(Icons.arrow_drop_down, color: AdminColors.primaryText),
                            value: _selectedTeacher,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Year
                  Container(
                    decoration: AdminColors.glassDecoration(),
                    child: TextFormField(
                      controller: _yearController,
                      style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: AdminTextStyles.cardSubtitle,
                        prefixIcon: Icon(Icons.calendar_today, color: AdminColors.secondaryText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
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
                  ),

                  SizedBox(height: 24),

                  // Time Slots Section
                  Text(
                    'TIME SLOTS',
                    style: AdminTextStyles.sectionHeader,
                  ),
                  SizedBox(height: 8),

                  if (_timeSlots.isEmpty)
                    Text(
                      'No time slots added yet',
                      style: AdminTextStyles.cardSubtitle,
                    ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_timeSlots.length, (index) {
                      final slot = _timeSlots[index];
                      return Chip(
                        label: Text('${slot.day} at ${slot.time}'),
                        backgroundColor: AdminColors.primaryAccent.withOpacity(0.2),
                        deleteIcon: Icon(Icons.close, size: 18, color: AdminColors.primaryText),
                        onDeleted: () => _removeTimeSlot(index),
                        labelStyle: AdminTextStyles.cardSubtitle,
                      );
                    }),
                  ),

                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _showAddTimeSlotDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AdminColors.primaryAccent,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AdminColors.primaryAccent, width: 1),
                    ),
                    child: Text(
                      'ADD DAY AND TIME',
                      style: AdminTextStyles.primaryButton.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primaryAccent,
                      foregroundColor: AdminColors.primaryBackground,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AdminColors.primaryBackground),
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      'ADD SUBJECT',
                      style: AdminTextStyles.primaryButton.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
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