import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/app_design_system.dart';
import 'attendance_screen.dart';
import 'assignments_screen.dart';
import 'chat_rooms_screen.dart';
import 'settings_screen.dart';
import 'home_screen_content.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Home center
  final NotificationService _notificationService = NotificationService();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AttendanceScreen(rfid: widget.userId),
      AssignmentsScreen(studentRfid: widget.userId),
      HomeScreenContent(rfid: widget.userId),
      ChatRoomsScreen(rfid: widget.userId),
      SettingsScreen(rfid: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: StreamBuilder<Map<String, int>>(
        stream: _notificationService.notificationStream,
        initialData: const {
          'attendance': 0,
          'assignments': 0,
          'chat': 0,
          'settings': 0,
          'queries': 0,
        },
        builder: (context, snapshot) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 0) {
                _notificationService.clearNotifications('attendance');
              }
              if (index == 1) {
                _notificationService.clearNotifications('assignments');
              }
              if (index == 3) {
                _notificationService.clearNotifications('chat');
              }
              if (index == 4) {
                _notificationService.clearNotifications('settings');
              }
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.secondaryBackground,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: Theme.of(context).textTheme.labelSmall,
            unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: Icons.calendar_today,
                  notificationCount: snapshot.data!['attendance'] ?? 0,
                ),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: Icons.assignment,
                  notificationCount: snapshot.data!['assignments'] ?? 0,
                ),
                label: 'Assignments',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: Icons.home,
                  notificationCount: 0,
                  isHome: true,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: Icons.chat,
                  notificationCount: snapshot.data!['chat'] ?? 0,
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: Icons.settings,
                  notificationCount: snapshot.data!['settings'] ?? 0,
                ),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required int notificationCount,
    bool isHome = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isHome ? 48 : 24,
          height: isHome ? 48 : 24,
          decoration: isHome
              ? BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          )
              : null,
          child: Icon(
            icon,
            size: isHome ? 24 : 20,
            color: isHome ? Colors.black : null,
          ),
        ),
        if (notificationCount > 0 && !isHome)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                notificationCount > 9 ? '9+' : '$notificationCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}