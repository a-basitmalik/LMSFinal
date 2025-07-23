import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';


class AddPlannerScreen extends StatefulWidget {
  final int subjectId;

  const AddPlannerScreen({
    required this.subjectId,
    Key? key,
  }) : super(key: key);

  @override
  _AddPlannerScreenState createState() => _AddPlannerScreenState();
}

class _AddPlannerScreenState extends State<AddPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedSubjectId;
  String? _selectedSubjectName;

  List<Map<String, dynamic>> _subjects = [];
  List<File> _attachments = [];
  bool _isLoadingSubjects = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeController.text = _selectedTime.format(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _subjectController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/Planner/subjects?campus_id=${widget.subjectId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(data['subjects']);
          _isLoadingSubjects = false;
        });
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading subjects: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
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
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _selectedTime.format(context);
      });
    }
  }

  Future<void> _selectSubject(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AdminColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SELECT SUBJECT',
                style: AdminTextStyles.sectionHeader.copyWith(
                  color: AdminColors.primaryAccent,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search subjects...',
                  hintStyle: AdminTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.search, color: AdminColors.secondaryText),
                  filled: true,
                  fillColor: AdminColors.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: AdminTextStyles.primaryButton,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return ListTile(
                      title: Text(
                        subject['name'],
                        style: AdminTextStyles.primaryButton,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSubjectId = subject['id'];
                          _selectedSubjectName = subject['name'];
                          _subjectController.text = subject['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.map((path) => File(path!)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _removeAttachment(int index) async {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitPlanner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final plannedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final plannerResponse = await http.post(
        Uri.parse('http://193.203.162.232:5050/Planner/planners'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'planned_date': DateFormat('yyyy-MM-dd HH:mm').format(plannedDateTime),
          'subject_id': _selectedSubjectId,
          'campus_id': widget.subjectId,
        }),
      );

      if (plannerResponse.statusCode != 201) {
        final errorData = json.decode(plannerResponse.body);
        throw Exception(errorData['error'] ?? 'Failed to create planner');
      }

      final plannerData = json.decode(plannerResponse.body);
      final plannerId = plannerData['planner_id'];

      if (_attachments.isNotEmpty) {
        await _uploadAttachments(plannerId);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planner created successfully'),
          backgroundColor: AdminColors.successAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _uploadAttachments(int plannerId) async {
    try {
      for (final file in _attachments) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://193.203.162.232:5050/Planner/attachments'),
        );

        request.fields['planner_id'] = plannerId.toString();
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: file.path.split('/').last,
          ),
        );

        var response = await request.send();
        if (response.statusCode != 201) {
          throw Exception('Failed to upload attachment');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading attachments: ${e.toString()}'),
          backgroundColor: AdminColors.warningAccent,
        ),
      );
    }
  }

  Widget _buildAttachmentPreview() {
    if (_attachments.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'ATTACHMENTS',
          style: AdminTextStyles.cardSubtitle.copyWith(
            color: AdminColors.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _attachments.length,
          itemBuilder: (context, index) {
            final file = _attachments[index];
            return Card(
              color: AdminColors.cardBackground,
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AdminColors.cardBorder,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _getAttachmentIcon(file.path.split('.').last),
                  color: AdminColors.primaryAccent,
                ),
                title: Text(
                  file.path.split('/').last,
                  style: AdminTextStyles.cardTitle,
                ),
                subtitle: Text(
                  '${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  style: AdminTextStyles.cardSubtitle,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: AdminColors.dangerAccent),
                  onPressed: () => _removeAttachment(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return InkWell(
      onTap: _pickFiles,
      child: Container(
        height: 100,
        decoration: AdminColors.glassDecoration(
          borderRadius: 12,
          borderColor: AdminColors.cardBorder,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AdminColors.secondaryText),
              SizedBox(height: 8),
              Text(
                'Add files or links',
                style: AdminTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'CREATE LESSON PLAN',
          style: AdminTextStyles.sectionHeader,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AdminColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _submitPlanner,
              child: Text(
                'SAVE',
                style: AdminTextStyles.primaryButton.copyWith(
                  color: AdminColors.primaryAccent,
                ),
              ),
            ),
          if (_isSubmitting)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminColors.primaryAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingSubjects
          ? Center(
        child: CircularProgressIndicator(color: AdminColors.primaryAccent),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_drop_down,
                        color: AdminColors.secondaryText),
                    onPressed: () => _selectSubject(context),
                  ),
                ),
                style: AdminTextStyles.primaryButton,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                ),
                style: AdminTextStyles.primaryButton,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                ),
                style: AdminTextStyles.primaryButton,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: AdminTextStyles.cardSubtitle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today,
                              color: AdminColors.secondaryText),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      style: AdminTextStyles.primaryButton,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        labelStyle: AdminTextStyles.cardSubtitle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.access_time,
                              color: AdminColors.secondaryText),
                          onPressed: () => _selectTime(context),
                        ),
                      ),
                      style: AdminTextStyles.primaryButton,
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildAddAttachmentButton(),
              _buildAttachmentPreview(),
              SizedBox(height: 32),
              if (!_isSubmitting)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitPlanner,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AdminColors.primaryBackground,
                      backgroundColor: AdminColors.primaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SAVE PLAN',
                      style: AdminTextStyles.primaryButton.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (_isSubmitting)
                Center(
                  child: CircularProgressIndicator(
                      color: AdminColors.primaryAccent),
                ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}