import 'dart:convert';
import 'package:newapp/admin/AddStudent.dart';
import 'package:newapp/admin/alumni_profile_view.dart';
import 'package:newapp/admin/FineList.dart';
import 'package:newapp/admin/AttendanceDashboard.dart';
import 'package:newapp/admin/MarkAttendance.dart';
import 'package:newapp/admin/shared_list.dart';
import 'package:newapp/admin/TrackPayment.dart';
import 'package:newapp/admin/ViewAttendance.dart';
import 'package:newapp/admin/FeeDashboard.dart';
import 'package:newapp/Teacher/AnnouncementsScreen.dart';
import 'package:newapp/Teacher/teacher_main.dart';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/Announcement.dart';
import 'package:newapp/admin/AttendanceDashboard.dart';
import 'package:newapp/admin/results_list.dart';
import 'package:newapp/admin/shared_list.dart';
import 'package:newapp/admin/subjects.dart';
import 'AcademicCalendar.dart';
import 'AdminDashboard.dart';
import 'DownloadReportsScreen.dart';

class AdminMain extends StatelessWidget {
  final String userId;

  const AdminMain({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(

          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
          surface: Color(0xFF121212),
        ),
      ),
      home: SelectCampus(userId: userId),
      routes: {
        '/studentList': (context) => SharedList(type: 'students', campusID: 1),
        '/teacherList': (context) => SharedList(type: 'teachers', campusID: 1),
        '/alumniList': (context) => SharedList(type: 'alumni', campusID: 1),
        '/subjects': (context) => SubjectDashboard(campusId: 1),
        '/result': (context) => ResultListScreen(campusId: 1),
    '/downloadReports': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final campusID = args?['campusID'] ?? 0;
    final campusName = args?['campusName'] ?? 'Unknown';

    return  DownloadReportsScreen (
    campusID: campusID,    // Keep this if you need campusID
    campusName: campusName,// Keep this if you need campusName
    );
    },
        '/attendance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          final campusId = args?['campusID'] ?? 1; // Default to 1 if not provided
          final campusName = args?['campusName'] ?? 'Campus $campusId'; // Default name

          return AttendanceDashboard(
            campusId: campusId,
            campusName: campusName,
          );
        },
        '/announcements': (context) => AnnouncementCreator(campusID: 1),
        '/fees': (context) => FeeDashboard(),
        '/calendar': (context) => AcademicCalendarScreen(),
      },
    );
  }
}

class SelectCampus extends StatefulWidget {
  final String userId;

  const SelectCampus({Key? key, required this.userId}) : super(key: key);

  @override
  _SelectCampusState createState() => _SelectCampusState();
}

class _SelectCampusState extends State<SelectCampus> {
  final String baseUrl = "http://193.203.162.232:5050";
  List<Map<String, dynamic>> campuses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCampusesFromDatabase();
  }

  Future<void> loadCampusesFromDatabase() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/campus/get_campuses'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          campuses = data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        showErrorToast("Failed to load campuses: ${response.statusCode}");
      }
    } catch (e) {
      showErrorToast("Failed to load campuses");
    }
  }

  void showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  void navigateToDashboard(int campusID, String campusName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            AdminDashboard(
              campusID: campusID,
              campusName: campusName,
            ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget buildCampusCard(Map<String, dynamic> campus) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueAccent.withOpacity(0.2),
            Colors.indigoAccent.withOpacity(0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              navigateToDashboard(campus['CampusID'], campus['CampusName']),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campus['CampusName'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${campus['CampusID']}',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Select Campus',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
          ),
        )
            : ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: campuses.length,
          itemBuilder: (context, index) {
            return buildCampusCard(campuses[index]);
          },
        ),
      ),
    );
  }
}