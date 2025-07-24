import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/student_model.dart';
import '../widgets/base_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Student _student;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _student = Student.empty();
    _nameController.text = _student.name;
    _emailController.text = _student.email;
    _phoneController.text = _student.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BaseScreen(
      title: 'Edit Profile',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _student.profileImage != null
                          ? NetworkImage(_student.profileImage!)
                          : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: AppColors.textPrimary,
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: textTheme.labelMedium,
                prefixIcon: Icon(Icons.person, color: AppColors.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: textTheme.labelMedium,
                prefixIcon: Icon(Icons.email, color: AppColors.primary),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: textTheme.labelMedium,
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text(
                'Save Changes',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // TODO: Implement image picking logic
    // Example implementation:
    /*
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _student = _student.copyWith(profileImage: pickedFile.path);
      });
    }
    */
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _student = _student.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );
      });

      // TODO: Save to backend
      // Example:
      // await AuthService().updateStudentProfile(_student);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, _student);
    }
  }
}