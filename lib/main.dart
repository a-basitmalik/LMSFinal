import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'AdminDashboard.dart';
import 'shared_list.dart';
import 'subjects.dart';
import 'results_list.dart';
import 'AttendanceDashboard.dart';
import 'Announcement.dart';
import 'FeeDashboard.dart';
import 'AcademicCalendar.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Select Campus',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
          surface: Color(0xFF121212),
        ),
      ),
      home: SelectCampus(),
      routes: {
        '/studentList': (context) => SharedList(type: 'students', campusID: 1),
        '/teacherList': (context) => SharedList(type: 'teachers', campusID: 1),
        '/alumniList': (context) => SharedList(type: 'alumni', campusID: 1),
        '/subjects': (context) => SubjectDashboard(campusId: 1),
        '/result': (context) => ResultListScreen(campusId: 1),
        '/attendance': (context) => AttendanceDashboard(campusId: 1),
        '/announcements': (context) => AnnouncementCreator(campusID: 1),
        '/fees': (context) => FeeDashboard(),
        '/calendar': (context) => AcademicCalendarScreen(),
      }
    );
  }
}

class SelectCampus extends StatefulWidget {
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
        pageBuilder: (_, __, ___) => AdminDashboard(
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
          onTap: () => navigateToDashboard(campus['CampusID'], campus['CampusName']),
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