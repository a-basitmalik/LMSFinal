import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';


class AddTeacherScreen extends StatefulWidget {
  final int campusId;

  const AddTeacherScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _AddTeacherScreenState createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://193.203.162.232:5050/teacher/register_teacher');
      final email = '${_nameController.text.trim().toLowerCase().replaceAll(' ', '')}@lgscolleges.edu.pk';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim(),
          'campus_id': widget.campusId,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher registered successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: AdminColors.successAccent.withOpacity(0.8),
          ),
        );
        _nameController.clear();
        _passwordController.clear();
        _phoneController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register teacher'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: AdminColors.dangerAccent.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: AdminColors.dangerAccent.withOpacity(0.8),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Add New Teacher',
          style: AdminTextStyles.sectionHeader.copyWith(color: AdminColors.primaryText),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminColors.facultyColor.withOpacity(0.2),
                AdminColors.primaryAccent.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              // Bulk Upload Card
              Container(
                decoration: AdminColors.glassDecoration(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Implement bulk upload functionality
                  },
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: AdminColors.primaryAccent,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Bulk Upload Teachers',
                          style: AdminTextStyles.sectionHeader,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload Excel or CSV file',
                          style: AdminTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Upload Button
              ElevatedButton(
                onPressed: () {
                  // Implement bulk upload functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.facultyColor,
                  foregroundColor: AdminColors.primaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'UPLOAD',
                  style: AdminTextStyles.primaryButton.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: 24),
              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AdminColors.cardBorder,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: AdminTextStyles.cardSubtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AdminColors.cardBorder,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Teacher Name Field
              TextFormField(
                controller: _nameController,
                style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Teacher Name',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.person, color: AdminColors.secondaryText),
                  filled: true,
                  fillColor: AdminColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AdminColors.primaryAccent, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Teacher name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.lock, color: AdminColors.secondaryText),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AdminColors.secondaryText,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: AdminColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AdminColors.primaryAccent, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AdminTextStyles.primaryButton.copyWith(color: AdminColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.phone, color: AdminColors.secondaryText),
                  filled: true,
                  fillColor: AdminColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AdminColors.primaryAccent, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              // Add Teacher Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primaryAccent,
                  foregroundColor: AdminColors.primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                  shadowColor: AdminColors.primaryAccent.withOpacity(0.3),
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
                  'ADD TEACHER',
                  style: AdminTextStyles.primaryButton.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}