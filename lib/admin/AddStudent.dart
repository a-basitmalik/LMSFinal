import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:math';


class AddStudentScreen extends StatefulWidget {
  final int campusId;

  const AddStudentScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  File? _profileImage;
  List<String> _subjects = [];
  List<String> _selectedSubjects = [];
  bool _isLoading = false;
  bool _showBulkUpload = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rfidController.dispose();
    _passwordController.dispose();
    _yearController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://193.203.162.232:5050/subject/get_subjects?campus_id=${widget.campusId}&year=1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _subjects = List<String>.from(data['subjects']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  String _generateStudentId(int count) {
    return "LGSC${widget.campusId}${count.toString().padLeft(3, '0')}";
  }

  String _generateRandomPassword() {
    final random = Random();
    return "LGSC${random.nextInt(9000) + 1000}";
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      _showErrorDialog('Please select at least one subject');
      return;
    }

    setState(() => _isLoading = true);

    final studentData = {
      "absentee_id": "", // Will be generated server-side
      "campus_id": widget.campusId,
      "fee_amount": int.parse(_feeController.text),
      "password": _generateRandomPassword(),
      "phone_number": _phoneController.text,
      "rfid": int.parse(_rfidController.text),
      "student_id": _generateStudentId(1), // Should get count from server
      "student_name": _nameController.text,
      "year": int.parse(_yearController.text),
      "subjects": _selectedSubjects,
    };

    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes();
      studentData["profile_image"] = base64Encode(bytes);
    }

    final url = Uri.parse('http://193.203.162.232:5050/student/add_student');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(studentData),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog('Student added successfully!');
        _formKey.currentState!.reset();
        setState(() {
          _profileImage = null;
          _selectedSubjects.clear();
        });
      } else {
        throw Exception('Failed to add student');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error adding student: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AdminDialog(
        title: 'Error',
        content: message,
        buttonText: 'OK',
        accentColor: AdminColors.dangerAccent,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AdminDialog(
        title: 'Success',
        content: message,
        buttonText: 'OK',
        accentColor: AdminColors.successAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: AdminColors.secondaryBackground,
            elevation: 4,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'ADD NEW STUDENT',
                style: AdminTextStyles.sectionHeader.copyWith(
                  color: AdminColors.primaryText,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AdminColors.secondaryBackground,
                      AdminColors.primaryBackground,
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
                  children: [
                    // Toggle between bulk and single upload
                    Container(
                      decoration: AdminColors.glassDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildUploadOption(
                              icon: Icons.person_add,
                              label: 'Single Entry',
                              selected: !_showBulkUpload,
                              onTap: () => setState(() => _showBulkUpload = false),
                            ),
                            _buildUploadOption(
                              icon: Icons.upload_file,
                              label: 'Bulk Upload',
                              selected: _showBulkUpload,
                              onTap: () => setState(() => _showBulkUpload = true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_showBulkUpload) _buildBulkUploadSection(),
                    if (!_showBulkUpload) _buildSingleUploadForm(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? AdminColors.accentGradient(AdminColors.primaryAccent) : null,
          border: Border.all(
            color: selected ? AdminColors.primaryAccent : AdminColors.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AdminColors.primaryText : AdminColors.secondaryText),
            SizedBox(height: 8),
            Text(
              label,
              style: AdminTextStyles.cardTitle.copyWith(
                color: selected ? AdminColors.primaryText : AdminColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Column(
      children: [
        Container(
          decoration: AdminColors.glassDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.upload, size: 48, color: AdminColors.primaryAccent),
                SizedBox(height: 16),
                Text(
                  'BULK UPLOAD STUDENTS',
                  style: AdminTextStyles.sectionHeader,
                ),
                SizedBox(height: 8),
                Text(
                  'Upload Excel or CSV file with student data',
                  style: AdminTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            _showSuccessDialog('Bulk upload feature will be implemented soon');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryAccent,
            foregroundColor: AdminColors.primaryBackground,
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'UPLOAD FILE',
            style: AdminTextStyles.primaryButton,
          ),
        ),
        SizedBox(height: 24),
        Divider(color: AdminColors.cardBorder),
        SizedBox(height: 16),
        Text(
          'OR',
          style: AdminTextStyles.sectionHeader,
        ),
        SizedBox(height: 16),
        Divider(color: AdminColors.cardBorder),
      ],
    );
  }

  Widget _buildSingleUploadForm() {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Column(
      children: [
        // Profile Picture
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: AdminColors.glassDecoration(borderRadius: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_profileImage != null)
                  ClipOval(
                    child: Image.file(
                      _profileImage!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(Icons.person, size: 48, color: AdminColors.secondaryText),
                Positioned(
                  bottom: 8,
                  child: Text(
                    _profileImage != null ? 'CHANGE PHOTO' : 'UPLOAD PHOTO',
                    style: AdminTextStyles.cardSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        // Student Name
        _buildInputField(
          controller: _nameController,
          label: 'Student Name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter student name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
              return 'Name should only contain letters';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        // Phone Number
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
              return 'Enter a valid 10-digit number';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        // Subjects Dropdown
        Container(
          decoration: AdminColors.glassDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBJECTS',
                  style: AdminTextStyles.cardSubtitle,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(
                        subject,
                        style: AdminTextStyles.cardTitle,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedSubjects.contains(value)) {
                      setState(() {
                        _selectedSubjects.add(value);
                      });
                    }
                  },
                  validator: (value) {
                    if (_selectedSubjects.isEmpty) {
                      return 'Please select at least one subject';
                    }
                    return null;
                  },
                  hint: Text(
                    _selectedSubjects.isEmpty
                        ? 'Select subjects'
                        : _selectedSubjects.join(', '),
                    style: AdminTextStyles.cardTitle,
                  ),
                  dropdownColor: AdminColors.secondaryBackground,
                  icon: Icon(Icons.arrow_drop_down, color: AdminColors.primaryText),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // RFID
        _buildInputField(
          controller: _rfidController,
          label: 'RFID',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter RFID';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        // Password
        _buildInputField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Must contain at least one uppercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Must contain at least one number';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        // Year
        _buildInputField(
          controller: _yearController,
          label: 'Year',
          icon: Icons.calendar_today,
          keyboardType: TextInputType.number,
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
        SizedBox(height: 16),
        // Fee Amount
        _buildInputField(
          controller: _feeController,
          label: 'Fee Amount',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter fee amount';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
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
            elevation: 4,
          ),
          child: Text(
            'ADD STUDENT',
            style: AdminTextStyles.primaryButton,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Container(
      decoration: AdminColors.glassDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AdminTextStyles.cardTitle,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AdminTextStyles.cardSubtitle,
            border: InputBorder.none,
            icon: Icon(icon, color: AdminColors.secondaryText),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

class AdminDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final Color accentColor;

  const AdminDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonText,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: AdminColors.glassDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AdminTextStyles.sectionHeader.copyWith(color: accentColor),
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: AdminTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AdminColors.primaryBackground,
                  minimumSize: Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: AdminTextStyles.primaryButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}