import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';
import 'package:newapp/login_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // API Endpoints
  final String _baseUrl = 'https://your-api-endpoint.com/api';
  final String _profileEndpoint = '/profile';
  final String _logoutEndpoint = '/logout';
  final String _changePasswordEndpoint = '/change-password';

  // Sample data - will be replaced by API calls
  Map<String, dynamic> _userProfile = {
    'name': 'Dr. Asma Ali',
    'email': 'asma.ali@lgscolleges.edu.pk',
    'department': 'Mathematics, Physics',
    'avatar': 'assets/teacher_avatar.png',
    'joinDate': '2021-09-15',
    'lastLogin': '2023-06-15T14:30:00Z',
  };

  bool _isLoading = false;
  bool _showChangePassword = false;
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Uncomment when API is ready
    // _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_profileEndpoint'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TeacherTextStyles.sectionHeader,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TeacherTextStyles.cardSubtitle,
        ),
        backgroundColor: TeacherColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TeacherTextStyles.secondaryButton,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TeacherTextStyles.secondaryButton.copyWith(
                color: TeacherColors.dangerAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl$_logoutEndpoint'),
          headers: {'Authorization': 'Bearer YOUR_TOKEN'},
        );

        if (response.statusCode == 200) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          throw Exception('Logout failed');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_changePasswordEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
        setState(() => _showChangePassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        throw Exception(
          json.decode(response.body)['message'] ?? 'Password change failed',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'My Profile',
                style: TeacherTextStyles.className,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TeacherColors.primaryAccent.withOpacity(0.8),
                      TeacherColors.secondaryAccent.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.person_outline,
                          size: 150,
                          color: TeacherColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileCard(),
                  SizedBox(height: 24),
                  if (_showChangePassword) _buildChangePasswordForm(),
                  if (!_showChangePassword) _buildProfileActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: TeacherColors.glassDecoration(),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: TeacherColors.accentGradient(TeacherColors.primaryAccent),
                    image: DecorationImage(
                      image: AssetImage(_userProfile['avatar']),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: TeacherColors.primaryAccent,
                      width: 3,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TeacherColors.primaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: TeacherColors.primaryText, width: 2),
                  ),
                  child: Icon(Icons.edit, size: 18, color: TeacherColors.primaryText),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _userProfile['name'],
              style: TeacherTextStyles.className,
            ),
            SizedBox(height: 8),
            Text(
              _userProfile['email'],
              style: TeacherTextStyles.cardSubtitle,
            ),
            SizedBox(height: 16),
            Divider(color: TeacherColors.cardBorder),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileStat(
                  label: 'Department',
                  value: _userProfile['department'],
                  icon: Icons.school,
                ),
                _buildProfileStat(
                  label: 'Member Since',
                  value: _userProfile['joinDate'].split('-')[0],
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: TeacherColors.accentGradient(TeacherColors.primaryAccent),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: TeacherColors.primaryText),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TeacherTextStyles.statValue,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TeacherTextStyles.statLabel,
        ),
      ],
    );
  }

  Widget _buildProfileActions() {
    return Column(
      children: [
        _buildProfileActionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => setState(() => _showChangePassword = true),
        ),
        _buildProfileActionTile(
          icon: Icons.notifications_active_outlined,
          title: 'Notification Settings',
          onTap: () {},
        ),
        _buildProfileActionTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        _buildProfileActionTile(
          icon: Icons.info_outline,
          title: 'About',
          onTap: () {},
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.dangerAccent,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _logout,
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryText),
              ),
            )
                : Text(
              'Logout',
              style: TeacherTextStyles.primaryButton,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: TeacherColors.glassDecoration(),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: TeacherColors.accentGradient(TeacherColors.primaryAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: TeacherColors.primaryText),
        ),
        title: Text(
          title,
          style: TeacherTextStyles.listItemTitle,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: TeacherColors.secondaryText,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Container(
      decoration: TeacherColors.glassDecoration(),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Password',
                    style: TeacherTextStyles.sectionHeader,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: TeacherColors.primaryText),
                    onPressed: () => setState(() => _showChangePassword = false),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.lock_outline, color: TeacherColors.secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  filled: true,
                  fillColor: TeacherColors.cardBackground,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.lock_outline, color: TeacherColors.secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  filled: true,
                  fillColor: TeacherColors.cardBackground,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.lock_outline, color: TeacherColors.secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  filled: true,
                  fillColor: TeacherColors.cardBackground,
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.primaryAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TeacherColors.primaryText,
                      ),
                    ),
                  )
                      : Text(
                    'Update Password',
                    style: TeacherTextStyles.primaryButton,
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