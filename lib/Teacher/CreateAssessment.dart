import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
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
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assessment Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Assessment Type Dropdown
              DropdownButtonFormField<String>(
                value: _assessmentType,
                decoration: InputDecoration(
                  labelText: 'Assessment Type',
                  border: const OutlineInputBorder(),
                  filled: true,
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
                    // Set default marks based on type
                    if (_assessmentType == 'Quiz' && _totalMarksController.text.isEmpty) {
                      _totalMarksController.text = '15';
                    } else if (_assessmentType == 'Monthly' && _totalMarksController.text.isEmpty) {
                      _totalMarksController.text = '35';
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // Total Marks Field
              TextFormField(
                controller: _totalMarksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Marks',
                  hintText: _assessmentType == 'Quiz' ? '15' :
                  _assessmentType == 'Monthly' ? '35' : '',
                  border: const OutlineInputBorder(),
                  filled: true,
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

              const SizedBox(height: 16),

              // Date and Time Picker
              TextFormField(
                controller: _createdAtController,
                decoration: InputDecoration(
                  labelText: 'Date and Time',
                  border: const OutlineInputBorder(),
                  filled: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
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

              const SizedBox(height: 24),

              // Grading Criteria Section
              Text(
                'Grading Criteria',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ..._gradeControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${entry.key}:',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Create Assessment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
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