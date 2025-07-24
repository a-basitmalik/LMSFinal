import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../login_screen.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/base_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String rfid;

  const SettingsScreen({super.key, required this.rfid});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLogoutTime = '30 minutes';

  final List<String> _logoutTimes = [
    '15 minutes',
    '30 minutes',
    '1 hour',
    'Never',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return BaseScreen(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Settings
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
            child: SwitchListTile(
              title: Text(
                'Notifications',
                style: textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Enable or disable app notifications',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Dark Mode Settings
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
            child: SwitchListTile(
              title: Text(
                'Dark Mode',
                style: textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Switch between light and dark theme',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Auto Logout Time
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Logout Time',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLogoutTime,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    dropdownColor: AppColors.secondaryBackground,
                    style: textTheme.bodyMedium,
                    items: _logoutTimes.map((time) {
                      return DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLogoutTime = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Edit Profile
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
              child: ListTile(
                leading: Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Edit Profile',
                  style: textTheme.bodyLarge,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _logout,
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
                title: Text(
                  'Logout',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to logout?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text(
                      'Logout',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }
}