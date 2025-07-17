// lib/admin/admin_routes.dart

import 'package:flutter/material.dart';
import 'package:newapp/admin/AddStudent.dart';
import 'package:newapp/admin/FineManagementScreen.dart';
import 'package:newapp/admin/alumni_profile_view.dart';
import 'package:newapp/admin/FineList.dart';
import 'package:newapp/admin/AttendanceDashboard.dart';
import 'package:newapp/admin/MarkAttendance.dart';
import 'package:newapp/admin/shared_list.dart';
import 'package:newapp/admin/TrackPayment.dart';
import 'package:newapp/admin/ViewAttendance.dart';
import 'package:newapp/admin/FeeDashboard.dart';
import 'package:newapp/admin/Announcement.dart';
import 'package:newapp/admin/results_list.dart';
import 'package:newapp/admin/subjects.dart';
import 'package:newapp/admin/DownloadReportsScreen.dart';
import 'package:newapp/admin/AcademicCalendar.dart';

import 'HolographicCalendarScreen.dart';
import 'PlannerListScreen.dart';

class AdminRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    final campusID = args?['campusID'] ?? 0;
    final campusName = args?['campusName'] ?? 'Campus $campusID';

    switch (settings.name) {
      case '/studentList':
        return MaterialPageRoute(
          builder: (_) => SharedList(type: 'students', campusID: campusID),
        );
      case '/teacherList':
        return MaterialPageRoute(
          builder: (_) => SharedList(type: 'teachers', campusID: campusID),
        );
      /*case '/alumniList':
        return MaterialPageRoute(
          builder: (_) => SharedList(type: 'alumni', campusID: campusID),
        );*/
      case '/subjects':
        return MaterialPageRoute(
          builder: (_) => SubjectDashboard(campusId: campusID),
        );
      case '/result':
        return MaterialPageRoute(
          builder: (_) => ResultListScreen(campusId: campusID),
        );
      case '/downloadReports':
        return MaterialPageRoute(
          builder: (_) => DownloadReportsScreen(
            campusID: campusID,
            campusName: campusName,
            initialTab: args!['initialTab'] ?? 0,
          ),
        );
      case '/attendance':
        return MaterialPageRoute(
          builder: (_) => AttendanceDashboard(
            campusId: campusID,
            campusName: campusName,
          ),
        );
      case '/announcements':
        return MaterialPageRoute(
          builder: (_) => AnnouncementCreator(campusID: campusID),
        );
      case '/planner':
        return MaterialPageRoute(
          builder: (_) => PlannerListScreen(
            campusID: args!['campusID'],
          ),
        );
      case '/fees':
        return MaterialPageRoute(builder: (_) => FineManagementScreen());
      /*case '/calendar':
        return MaterialPageRoute(builder: (_) => AcademicCalendarScreen());*/
      case '/calendar':  // Add this case for the calendar route
        return MaterialPageRoute(
          builder: (_) => HolographicCalendarScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}