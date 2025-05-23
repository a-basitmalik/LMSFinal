import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminSingleStudentView extends StatefulWidget {
  final int studentRfid;

  const AdminSingleStudentView({Key? key, required this.studentRfid}) : super(key: key);

  @override
  _AdminSingleStudentViewState createState() => _AdminSingleStudentViewState();
}

class _AdminSingleStudentViewState extends State<AdminSingleStudentView> {
  String currentPhotoUrl = "";
  late TextEditingController studentNameController;
  late TextEditingController studentPhoneController;
  late TextEditingController studentEmailController;
  late TextEditingController studentYearController;
  List<String> subjects = [];
  int totalClasses = 0;
  int attendedClasses = 0;
  int absences = 0;
  double attendancePercentage = 0.0;
  String results = "No results available.";
  String fines = "No fines or dues pending.";

  @override
  void initState() {
    super.initState();
    studentNameController = TextEditingController();
    studentPhoneController = TextEditingController();
    studentEmailController = TextEditingController();
    studentYearController = TextEditingController();
    fetchStudentData();
    fetchSubjects();
    fetchAttendance();
    fetchResults();
    fetchFines();
  }

  Future<void> fetchStudentData() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/details?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        studentNameController.text = data["student_name"];
        studentPhoneController.text = data["phone_number"];
        studentEmailController.text = data["email"] ?? "${data["student_name"].toLowerCase().replaceAll(" ", ".")}@university.edu";
        studentYearController.text = "Year: ${data["year"]}";
        currentPhotoUrl = data["picture_url"] ?? "";
      });
    } else {
      Fluttertoast.showToast(msg: "Error fetching student data");
    }
  }

  Future<void> fetchSubjects() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/subjects?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        subjects = data.map((subject) => subject.toString()).toList();
      });
    } else {
      Fluttertoast.showToast(msg: "Error fetching subjects");
    }
  }

  Future<void> fetchAttendance() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/attendance?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalClasses = data["TotalDays"];
        attendedClasses = data["DaysAttended"];
        absences = totalClasses - attendedClasses;
        attendancePercentage = data["AttendancePercentage"];
      });
    } else {
      Fluttertoast.showToast(msg: "Error fetching attendance");
    }
  }

  Future<void> fetchResults() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/results?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (data is Map && data.isNotEmpty) {
          // Format the results nicely
          results = "RESULTS\n" +
              data.entries.map((e) =>
              "${e.key}: ${e.value.toString()}%").join("\n");
        } else {
          results = "No results available.";
        }
      });
    } else {
      Fluttertoast.showToast(msg: "Error fetching results");
      setState(() {
        results = "No results available.";
      });
    }
  }

  Future<void> fetchFines() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/fines?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (data is Map && data.isNotEmpty) {
          // Format the fines nicely
          fines = "FINANCIAL\n" +
              data.entries.map((e) =>
              "${e.key}: ${e.value.toString()}Rs").join("\n");
        } else {
          fines = "No fines or dues pending.";
        }
      });
    } else {
      Fluttertoast.showToast(msg: "Error fetching fines");
      setState(() {
        fines = "No fines or dues pending.";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      uploadStudentPhoto(imageFile);
    }
  }

  Future<void> uploadStudentPhoto(File imageFile) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://193.203.162.232:5050/student/upload_photo?rfid=${widget.studentRfid}"),
    );

    final imageBytes = await imageFile.readAsBytes();

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: "photo.jpg",
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final jsonResponse = json.decode(data);
      if (jsonResponse["success"]) {
        setState(() {
          currentPhotoUrl = jsonResponse["photo_url"];
        });
        Fluttertoast.showToast(msg: "Photo uploaded successfully");
      } else {
        Fluttertoast.showToast(msg: "Failed to upload photo");
      }
    } else {
      Fluttertoast.showToast(msg: "Error uploading photo");
    }
  }
  @override
  Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: Colors.black,
  body: CustomScrollView(
  slivers: [
  SliverAppBar(
  expandedHeight: 350,
  floating: false,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
  title: Text(
  studentNameController.text,
  style: TextStyle(
  color: Colors.white,
  fontSize: 24,
  fontWeight: FontWeight.bold,
  shadows: [
  Shadow(
  blurRadius: 10,
  color: Colors.black.withOpacity(0.5),
  ),
  ],
  ),
  ),
  background: Stack(
  fit: StackFit.expand,
  children: [
  Container(
  decoration: BoxDecoration(
  gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
  Colors.blue.shade900,
  Colors.indigo.shade800,
  ],
  ),
  ),
  ),
  Container(
  decoration: BoxDecoration(
  gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
  Colors.transparent,
  Colors.black.withOpacity(0.7),
  ],
  ),
  ),
  ),
  Center(
  child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  SizedBox(height: 80),
  Container(
  width: 140,
  height: 140,
  decoration: BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(
  color: Colors.white.withOpacity(0.3),
  width: 2,
  ),
  boxShadow: [
  BoxShadow(
  color: Colors.blue.withOpacity(0.4),
  blurRadius: 20,
  spreadRadius: 5,
  ),
  ],
  ),
  child: ClipOval(
  child: currentPhotoUrl.isNotEmpty
  ? CachedNetworkImage(
  imageUrl: currentPhotoUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
  color: Colors.grey[900],
  child: Center(
  child: CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
  ),
  ),
  ),
  errorWidget: (context, url, error) => Icon(
  Icons.person,
  size: 60,
  color: Colors.white,
  ),
  )
      : Icon(
  Icons.person,
  size: 60,
  color: Colors.white,
  ),
  ),
  ),
  ],
  ),
  ),
  ],
  ),
  ),
  ),
  SliverToBoxAdapter(
  child: Padding(
  padding: const EdgeInsets.all(20.0),
  child: Column(
  children: [
  // Contact Information
  _buildFuturisticCard(
  title: 'CONTACT',
  icon: Icons.contact_mail_outlined,
  children: [
  _buildInfoRow(Icons.email_outlined, 'Email', studentEmailController.text),
  _buildInfoRow(Icons.phone_iphone_outlined, 'Phone', studentPhoneController.text),
  ],
  ),

  SizedBox(height: 20),

  // Academic Information
  _buildFuturisticCard(
  title: 'ACADEMICS',
  icon: Icons.school_outlined,
  children: [
  _buildInfoRow(Icons.badge_outlined, 'Student ID', widget.studentRfid.toString()),
  _buildInfoRow(Icons.calendar_today_outlined, 'Year', studentYearController.text.replaceAll('Year: ', '')),
  ],
  ),

  SizedBox(height: 20),

  // Subjects Enrolled
  _buildFuturisticCard(
  title: 'SUBJECTS',
  icon: Icons.menu_book_outlined,
  children: [
  ConstrainedBox(
  constraints: BoxConstraints(maxHeight: 150),
  child: Scrollbar(
  child: ListView.builder(
  shrinkWrap: true,
  physics: ClampingScrollPhysics(),
  itemCount: subjects.length,
  itemBuilder: (context, index) {
  return Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
  children: [
  Icon(Icons.circle, size: 8, color: Colors.blueAccent),
  SizedBox(width: 12),
  Expanded(
  child: Text(
  subjects[index],
  style: TextStyle(
  color: Colors.white.withOpacity(0.8),
  fontSize: 16,
  ),
  ),
  ),
  ],
  ),
  );
  },
  ),
  ),
  ),
  ],
  ),

  SizedBox(height: 20),

  // Attendance
  _buildFuturisticCard(
  title: 'ATTENDANCE',
  icon: Icons.assessment_outlined,
  children: [
  _buildStatRow('Total Classes', totalClasses.toString(), Colors.blueAccent),
  _buildStatRow('Present', attendedClasses.toString(), Colors.greenAccent),
  _buildStatRow('Absent', absences.toString(), Colors.redAccent),
  _buildStatRow(
  'Percentage',
  '${attendancePercentage.toStringAsFixed(1)}%',
  _getPercentageColor(attendancePercentage),
  ),
  ],
  ),

  SizedBox(height: 20),

  // Results
    _buildFuturisticCard(
      title: 'RESULTS',
      icon: Icons.bar_chart_outlined,
      children: [
        if (results.contains("\n"))
          ...results.split("\n").map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          )).toList()
        else
          Text(
            results,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
      ],
    ),


  SizedBox(height: 20),

  // Fines
    _buildFuturisticCard(
      title: 'FINANCIAL',
      icon: Icons.attach_money_outlined,
      children: [
        if (fines.contains("\n"))
          ...fines.split("\n").map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: TextStyle(
                color: line.startsWith("Total") ?
                Colors.redAccent : Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          )).toList()
        else
          Text(
            fines,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
      ],
    ),

  SizedBox(height: 40),
  ],
  ),
  ),
  ),
  ],
  ),
  floatingActionButton: FloatingActionButton(
  onPressed: () {
  // Edit functionality
  },
  child: Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
  shape: BoxShape.circle,
  gradient: LinearGradient(
  colors: [Colors.blueAccent, Colors.indigoAccent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  ),
  boxShadow: [
  BoxShadow(
  color: Colors.blueAccent.withOpacity(0.4),
  blurRadius: 15,
  spreadRadius: 2,
  ),
  ],
  ),
  child: Icon(Icons.edit_outlined, color: Colors.white),
  ),
  backgroundColor: Colors.transparent,
  elevation: 0,
  ),
  );
  }

  Widget _buildFuturisticCard({
  required String title,
  required IconData icon,
  required List<Widget> children,
  }) {
  return Container(
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
  Colors.grey[900]!,
  Colors.grey[850]!,
  ],
  ),
  boxShadow: [
  BoxShadow(
  color: Colors.blue.withOpacity(0.1),
  blurRadius: 20,
  spreadRadius: 2,
  ),
  ],
  ),
  child: Padding(
  padding: const EdgeInsets.all(20.0),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
  color: Colors.blueAccent.withOpacity(0.2),
  borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, color: Colors.blueAccent),
  ),
  SizedBox(width: 12),
  Text(
  title,
  style: TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.2,
  ),
  ),
  ],
  ),
  SizedBox(height: 16),
  ...children,
  ],
  ),
  ),
  );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Icon(icon, size: 24, color: Colors.blueAccent),
  SizedBox(width: 12),
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(
  label,
  style: TextStyle(
  color: Colors.white.withOpacity(0.6),
  fontSize: 14,
  ),
  ),
  SizedBox(height: 4),
  Text(
  value,
  style: TextStyle(
  color: Colors.white,
  fontSize: 16,
  ),
  ),
  ],
  ),
  ),
  ],
  ),
  );
  }

  Widget _buildStatRow(String label, String value, Color color) {
  return Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
  children: [
  Expanded(
  flex: 2,
  child: Text(
  label,
  style: TextStyle(
  color: Colors.white.withOpacity(0.8),
  fontSize: 16,
  ),
  ),
  ),
  Expanded(
  flex: 1,
  child: Text(
  value,
  textAlign: TextAlign.end,
  style: TextStyle(
  color: color,
  fontSize: 16,
  fontWeight: FontWeight.bold,
  ),
  ),
  ),
  ],
  ),
  );
  }

  Color _getPercentageColor(double percentage) {
  if (percentage >= 75) return Colors.greenAccent;
  if (percentage >= 50) return Colors.amber;
  return Colors.redAccent;
  }
  }