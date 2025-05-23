import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:math';

class AddStudentScreen extends StatefulWidget {
  final int campusId;

  const AddStudentScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}
class _AddStudentScreenState extends State<AddStudentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _fetchSubjects();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                        'ADD NEW STUDENT',
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
                      children: [
                        // Toggle between bulk and single upload
                        GlassCard(
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

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? LinearGradient(
            colors: [
              Colors.cyanAccent.withOpacity(0.7),
              Colors.blueAccent.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          border: Border.all(
            color: selected ? Colors.cyanAccent : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.white.withOpacity(0.8)),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
    return Column(
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.upload, size: 48, color: Colors.cyanAccent),
                SizedBox(height: 16),
                Text(
                  'BULK UPLOAD STUDENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Upload Excel or CSV file with student data',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Implement bulk upload functionality
            _showSuccessDialog('Bulk upload feature will be implemented soon');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'UPLOAD FILE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(height: 24),
        Divider(color: Colors.white.withOpacity(0.3)),
        SizedBox(height: 16),
        Text(
          'OR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Divider(color: Colors.white.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildSingleUploadForm() {
    return Column(
      children: [
        // Profile Picture
        GestureDetector(
          onTap: _pickImage,
          child: GlassCard(
            width: 120,
            height: 120,
            borderRadius: 60,
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
                  Icon(Icons.person, size: 48, color: Colors.white.withOpacity(0.7)),

                Positioned(
                  bottom: 8,
                  child: Text(
                    _profileImage != null ? 'CHANGE PHOTO' : 'UPLOAD PHOTO',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),

        // Student Name
        GlassInputField(
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
        GlassInputField(
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
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBJECTS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
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
                        style: TextStyle(color: Colors.white),
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
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  dropdownColor: Colors.grey[900],
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // RFID
        GlassInputField(
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
        GlassInputField(
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
        GlassInputField(
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
        GlassInputField(
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
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
          ),
          child: Text(
            'ADD STUDENT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
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
  final String? Function(String?)? validator;

  const GlassInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
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
  final String content;
  final String buttonText;

  const HolographicDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonText,
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
              Text(
                content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
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