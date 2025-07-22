import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';

class CreateAssessmentScreen extends StatefulWidget {
  final int subjectId;
  final Color subjectColor;

  const CreateAssessmentScreen({
    super.key,
    required this.subjectId,
    required this.subjectColor,
  });

  @override
  _CreateAssessmentScreenState createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends State<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalMarksController = TextEditingController();
  final TextEditingController _createdAtController = TextEditingController();
  final Map<String, TextEditingController> _gradeControllers = {
    'A*': TextEditingController(text: '90'),
    'A': TextEditingController(text: '80'),
    'B': TextEditingController(text: '70'),
    'C': TextEditingController(text: '60'),
    'D': TextEditingController(text: '50'),
    'E': TextEditingController(text: '40'),
    'F': TextEditingController(text: '30'),
  };

  String _assessmentType = 'Monthly';
  bool _isLoading = false;
  DateTime? _selectedDate;

  final String baseUrl = 'http://193.203.162.232:5050/SubjectAssessment/api';
  final String createAssessmentEndpoint = '/assessments';

  @override
  void initState() {
    super.initState();
    _createdAtController.text = DateFormat('yyyy-MM-ddTHH:mm').format(DateTime.now());
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.subjectColor,
              onPrimary: TeacherColors.primaryText,
              onSurface: TeacherColors.primaryText,
            ),
            dialogBackgroundColor: TeacherColors.primaryBackground,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: widget.subjectColor,
                onPrimary: TeacherColors.primaryText,
                onSurface: TeacherColors.primaryText,
              ),
              dialogBackgroundColor: TeacherColors.primaryBackground,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _createdAtController.text = DateFormat('yyyy-MM-ddTHH:mm').format(_selectedDate!);
        });
      }
    }
  }

  Future<void> _createAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare grading criteria
      final gradingCriteria = {
        for (var entry in _gradeControllers.entries)
          entry.key: int.tryParse(entry.value.text) ?? 0
      };

      final response = await http.post(
        Uri.parse('$baseUrl$createAssessmentEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject_id': widget.subjectId,
          'assessment_type': _assessmentType,
          'total_marks': int.tryParse(_totalMarksController.text) ??
              (_assessmentType == 'Quiz' ? 15 :
              _assessmentType == 'Monthly' ? 35 : 0),
          'grading_criteria': gradingCriteria,
          'created_at': _createdAtController.text,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Return success
      } else {
        throw Exception('Failed to create assessment: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Create Assessment',
          style: TeacherTextStyles.sectionHeader.copyWith(
            color: TeacherColors.primaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subjectColor,
                widget.subjectColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TeacherColors.primaryBackground.withOpacity(0.97),
              TeacherColors.primaryBackground.withOpacity(0.95),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with futuristic design
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.subjectColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_add,
                        color: widget.subjectColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Assessment Details',
                        style: TeacherTextStyles.sectionHeader.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: widget.subjectColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Assessment Type Dropdown - Futuristic Card
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Assessment Type',
                          style: TeacherTextStyles.listItemSubtitle.copyWith(
                            color: TeacherColors.secondaryText.withOpacity(0.8),
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _assessmentType,
                        dropdownColor: TeacherColors.secondaryBackground,
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          color: TeacherColors.primaryText,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: widget.subjectColor,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Send Up', child: Text('Send Up')),
                          DropdownMenuItem(value: 'Mocks', child: Text('Mocks')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                          DropdownMenuItem(value: 'Test Session', child: Text('Test Session')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'Half Book', child: Text('Half Book')),
                          DropdownMenuItem(value: 'Full Book', child: Text('Full Book')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _assessmentType = value!;
                            if (_assessmentType == 'Quiz' && _totalMarksController.text.isEmpty) {
                              _totalMarksController.text = '15';
                            } else if (_assessmentType == 'Monthly' && _totalMarksController.text.isEmpty) {
                              _totalMarksController.text = '35';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Total Marks Field - Futuristic Card
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Total Marks',
                          style: TeacherTextStyles.listItemSubtitle.copyWith(
                            color: TeacherColors.secondaryText.withOpacity(0.8),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _totalMarksController,
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          color: TeacherColors.primaryText,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: _assessmentType == 'Quiz' ? '15' :
                          _assessmentType == 'Monthly' ? '35' : '',
                          hintStyle: TeacherTextStyles.listItemSubtitle,
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.score,
                            color: widget.subjectColor.withOpacity(0.7),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            if (_assessmentType == 'Quiz') return 'Default is 15';
                            if (_assessmentType == 'Monthly') return 'Default is 35';
                            return 'Please enter total marks';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Date and Time Picker - Futuristic Card
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Date and Time',
                          style: TeacherTextStyles.listItemSubtitle.copyWith(
                            color: TeacherColors.secondaryText.withOpacity(0.8),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _createdAtController,
                        style: TeacherTextStyles.listItemTitle.copyWith(
                          color: TeacherColors.primaryText,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: widget.subjectColor,
                            ),
                            onPressed: () => _selectDateTime(context),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDateTime(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select date and time';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Grading Criteria Section - Futuristic Header
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.subjectColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grading,
                        color: widget.subjectColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Grading Criteria',
                        style: TeacherTextStyles.sectionHeader.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: widget.subjectColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Grading Criteria Inputs - Grid Layout
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: _gradeControllers.entries.map((entry) {
                    return _buildGradeInputCard(entry.key, entry.value);
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Submit Button - Futuristic Design
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.subjectColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.subjectColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: TeacherColors.primaryText,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          Icon(
                            Icons.add_task,
                            color: TeacherColors.primaryText,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Create Assessment',
                            style: TeacherTextStyles.primaryButton.copyWith(
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: TeacherColors.secondaryBackground.withOpacity(0.4),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _buildGradeInputCard(String grade, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TeacherColors.secondaryBackground.withOpacity(0.6),
            TeacherColors.secondaryBackground.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                grade,
                style: TeacherTextStyles.listItemTitle.copyWith(
                  color: widget.subjectColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                style: TeacherTextStyles.listItemTitle,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: TeacherColors.primaryBackground.withOpacity(0.7),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.subjectColor,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _totalMarksController.dispose();
    _createdAtController.dispose();
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}