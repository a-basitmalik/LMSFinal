import 'package:flutter/material.dart';
import 'SubjectDetails.dart';
import 'Subjects.dart';
import 'teacher_dashboard_ui.dart';
import 'package:newapp/Teacher/AnnouncementsScreen.dart';
import 'package:newapp/Teacher/FullSchedule.dart';
import 'package:newapp/Teacher/TeacherProfile.dart';

class TeacherRoutes {
  static const String dashboard = '/teacher/dashboard';
  static const String schedule = '/teacher/schedule';
  static const String announcements = '/teacher/announcements';
  static const String profile = '/teacher/profile';
  static const String subjects = '/teacher/subjects';

  static MaterialPageRoute getRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/teacher/dashboard':
        return MaterialPageRoute(
          builder: (context) =>
              TeacherMain(userId: settings.arguments as String),
        );

      case '/teacher/schedule':
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments as Map<String, dynamic>;
            return FullScheduleScreen(
              teacherId: args['teacherId'],
              schedule: args['schedule'],
              subject: Map<String, Object>.from(args['subject'] ?? {}),
              initialView: args['view'] ?? 'month', // Added view parameter
            );
          },
        );

      case '/teacher/announcements':
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments as Map<String, dynamic>;
            return AnnouncementScreen(
              announcements: args['announcements'],
            );
          },
        );

      case '/teacher/profile':
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(),
        );
      case subjects:
        final String teacherId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SubjectsScreen(teacherId: teacherId),
        );

      default:
        return MaterialPageRoute(
          builder: (context) =>
              Scaffold(
                body: Center(child: Text('Route not found')),
              ),
        );
    }
  }

  // Updated to include view parameter
  static void navigateToSchedule(BuildContext context,
      String teacherId,
      List<Map<String, dynamic>> schedule,
      Map<String, dynamic> params,) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScheduleScreen(
              teacherId: teacherId,
              schedule: schedule,
              subject: Map<String, Object>.from(params),
              initialView: params['view'] ?? 'month',
              tabIndex: params['tabIndex'] ?? 1, // Pass the view type
            ),
      ),
    );
  }

  static void navigateToAnnouncements(BuildContext context,
      List<Map<String, dynamic>> announcements) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementScreen(announcements: announcements),
      ),
    );
  }

  // Updated to include view parameter
  static void navigateToFullSchedule(BuildContext context,
      String userId,
      List<Map<String, dynamic>> schedule, {
        String initialView = 'month', // Default to month view
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScheduleScreen(
              schedule: schedule,
              teacherId: userId,
              subject: {}, // Add your subject data here if needed
              initialView: initialView, // Pass the initial view
            ),
      ),
    );
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  static void navigateToSubjects(BuildContext context, String teacherId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectsScreen(teacherId: teacherId),
      ),
    );
  }
}