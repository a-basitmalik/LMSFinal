// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/app_design_system.dart';
import 'attendance_screen.dart';
import 'assignments_screen.dart';
import 'chat_rooms_screen.dart';
import 'settings_screen.dart';
import 'home_screen_content.dart';

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
    // Initialize pages with the userId
    _pages = [
      AttendanceScreen(rfid: widget.userId),
      AssignmentsScreen(studentRfid: widget.userId),
      HomeScreenContent(rfid: widget.userId),
      ChatRoomsScreen(rfid:widget.userId),
      SettingsScreen(rfid:widget.userId),
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
          return AppDesignSystem.fancyBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 0)
                _notificationService.clearNotifications('attendance');
              if (index == 1)
                _notificationService.clearNotifications('assignments');
              if (index == 3) _notificationService.clearNotifications('chat');
              if (index == 4)
                _notificationService.clearNotifications('settings');
              setState(() => _currentIndex = index);
            },
            context: context,
            notificationCounts: snapshot.data!,
          );
        },
      ),
    );
  }
}