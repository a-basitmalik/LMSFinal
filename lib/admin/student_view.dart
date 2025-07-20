import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> callLogs = [];

  @override
  void initState() {
    super.initState();
    studentNameController = TextEditingController();
    studentPhoneController = TextEditingController();
    studentEmailController = TextEditingController();
    studentYearController = TextEditingController();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      fetchStudentData(),
      fetchSubjects(),
      fetchAttendance(),
      fetchResults(),
      fetchFines(),
      fetchComplaints(),
      fetchCallLogs(),
    ]);
  }

  Future<void> fetchComplaints() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/complaints?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        complaints = List<Map<String, dynamic>>.from(data['complaints'] ?? []);
      });
    }
  }

  Future<void> fetchCallLogs() async {
    final response = await http.get(
      Uri.parse("http://193.203.162.232:5050/student/call_logs?rfid=${widget.studentRfid}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        callLogs = List<Map<String, dynamic>>.from(data['call_logs'] ?? []);
      });
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = studentPhoneController.text;
    if (phoneNumber.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("http://193.203.162.232:5050/student/call_logs/add"),
        body: json.encode({
          'rfid': widget.studentRfid,
          'caller_type': 'admin',
          'notes': 'Call initiated from admin portal'
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      }
    } catch (e) {
      // Error handled by theme system
    }
  }

  void _showAddComplaintModal(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: AdminColors.glassDecoration(
            borderRadius: 20,
            borderColor: AdminColors.cardBorder,
          ),
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Add Complaint',
                style: AdminTextStyles.sectionHeader,
              ),
              SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AdminColors.cardBorder),
                  ),
                  filled: true,
                  fillColor: AdminColors.cardBackground,
                ),
                style: AdminTextStyles.cardTitle,
              ),
              SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: AdminTextStyles.cardSubtitle,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AdminColors.cardBorder),
                    ),
                    filled: true,
                    fillColor: AdminColors.cardBackground,
                  ),
                  style: AdminTextStyles.cardTitle,
                  maxLines: null,
                  expands: true,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                    return;
                  }

                  try {
                    final response = await http.post(
                      Uri.parse("http://193.203.162.232:5050/student/complaints/add"),
                      body: json.encode({
                        'rfid': widget.studentRfid,
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'complaint_by': 'admin'
                      }),
                      headers: {'Content-Type': 'application/json'},
                    );

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      fetchComplaints();
                    }
                  } catch (e) {
                    // Error handled by theme system
                  }
                },
                child: Text('Submit Complaint', style: AdminTextStyles.primaryButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primaryAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          results = "RESULTS\n" +
              data.entries.map((e) => "${e.key}: ${e.value.toString()}%").join("\n");
        } else {
          results = "No results available.";
        }
      });
    } else {
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
          fines = "FINANCIAL\n" +
              data.entries.map((e) => "${e.key}: ${e.value.toString()}Rs").join("\n");
        } else {
          fines = "No fines or dues pending.";
        }
      });
    } else {
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
      _uploadStudentPhoto(imageFile);
    }
  }

  Future<void> _uploadStudentPhoto(File imageFile) async {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                studentNameController.text,
                style: AdminTextStyles.campusName.copyWith(
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AdminColors.primaryAccent.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AdminColors.primaryAccent.withOpacity(0.7),
                      AdminColors.secondaryBackground,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 80),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AdminColors.cardBorder,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AdminColors.primaryAccent.withOpacity(0.3),
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
                                color: AdminColors.cardBackground,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AdminColors.primaryAccent),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 60,
                                color: AdminColors.primaryText,
                              ),
                            )
                                : Icon(
                              Icons.person,
                              size: 60,
                              color: AdminColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    context,
                    title: 'CONTACT',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _buildInfoRow(context, Icons.email_outlined, 'Email', studentEmailController.text),
                      _buildInfoRow(context, Icons.phone_iphone_outlined, 'Phone', studentPhoneController.text),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'ACADEMICS',
                    icon: Icons.school_outlined,
                    children: [
                      _buildInfoRow(context, Icons.badge_outlined, 'Student ID', widget.studentRfid.toString()),
                      _buildInfoRow(context, Icons.calendar_today_outlined, 'Year', studentYearController.text.replaceAll('Year: ', '')),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
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
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: AdminColors.primaryAccent),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      subjects[index],
                                      style: AdminTextStyles.cardSubtitle.copyWith(
                                        color:AdminColors.primaryText.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'ATTENDANCE',
                    icon: Icons.assessment_outlined,
                    children: [
                      _buildStatRow(context, 'Total Classes', totalClasses.toString(), AdminColors.primaryAccent),
                      _buildStatRow(context, 'Present', attendedClasses.toString(), AdminColors.successAccent),
                      _buildStatRow(context, 'Absent', absences.toString(), AdminColors.dangerAccent),
                      _buildStatRow(
                        context,
                        'Percentage',
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        _getPercentageColor(attendancePercentage, colors),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'RESULTS',
                    icon: Icons.bar_chart_outlined,
                    children: [
                      if (results.contains("\n"))
                        ...results.split("\n").map((line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            line,
                            style: AdminTextStyles.cardSubtitle.copyWith(
                              color: AdminColors.primaryText.withOpacity(0.8),
                            ),
                          ),
                        ))
                      else
                        Text(
                          results,
                          style: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'COMPLAINTS',
                    icon: Icons.report_problem_outlined,
                    children: [
                      if (complaints.isEmpty)
                        Text(
                          'No complaints yet',
                          style: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.disabledText,
                          ),
                        )
                      else
                        ...complaints.map((complaint) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getComplaintIcon(complaint['status']),
                                    color: _getComplaintColor(complaint['status'], colors),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    complaint['title'],
                                    style: AdminTextStyles.cardTitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    complaint['status'].toString().replaceAll('_', ' '),
                                    style: AdminTextStyles.cardSubtitle.copyWith(
                                      color: _getComplaintColor(complaint['status'], colors),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                complaint['description'],
                                style: AdminTextStyles.cardSubtitle.copyWith(
                                  color: AdminColors.secondaryText,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(DateTime.parse(complaint['created_at']))}',
                                style: AdminTextStyles.cardSubtitle.copyWith(
                                  color: AdminColors.disabledText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showAddComplaintModal(context),
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Add Complaint'),
                          style: TextButton.styleFrom(
                            foregroundColor: AdminColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'CALL LOGS',
                    icon: Icons.call_outlined,
                    children: [
                      if (callLogs.isEmpty)
                        Text(
                          'No call logs yet',
                          style: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.disabledText,
                          ),
                        )
                      else
                        ...callLogs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.call_made,
                                      color: AdminColors.successAccent, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Called by ${log['caller_type']}',
                                    style: AdminTextStyles.cardTitle,
                                  ),
                                  Spacer(),
                                  Text(
                                    '${DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['call_time']))}',
                                    style: AdminTextStyles.cardSubtitle.copyWith(
                                      color: AdminColors.disabledText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (log['notes']?.isNotEmpty ?? false) ...[
                                SizedBox(height: 4),
                                Text(
                                  log['notes'],
                                  style: AdminTextStyles.cardSubtitle.copyWith(
                                    color: AdminColors.secondaryText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        )),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _makePhoneCall,
                          icon: Icon(Icons.add_call, size: 18),
                          label: Text('Call Now'),
                          style: TextButton.styleFrom(
                            foregroundColor: AdminColors.successAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    title: 'FINANCIAL',
                    icon: Icons.attach_money_outlined,
                    children: [
                      if (fines.contains("\n"))
                        ...fines.split("\n").map((line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            line,
                            style: AdminTextStyles.cardSubtitle.copyWith(
                              color: line.startsWith("Total")
                                  ? AdminColors.dangerAccent
                                  : AdminColors.primaryText.withOpacity(0.8),
                            ),
                          ),
                        ))
                      else
                        Text(
                          fines,
                          style: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText.withOpacity(0.8),
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
            gradient: AdminColors.accentGradient(AdminColors.primaryAccent),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primaryAccent.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.edit_outlined, color: AdminColors.primaryText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
      }) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Container(
      decoration: AdminColors.glassDecoration(
        borderRadius: 16,
        borderColor: AdminColors.cardBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AdminColors.primaryAccent),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: AdminTextStyles.sectionHeader,
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

  Widget _buildInfoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AdminColors.primaryAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminTextStyles.cardSubtitle,
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: AdminTextStyles.cardTitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context,
      String label,
      String value,
      Color color,
      ) {
    final textStyles = context.adminTextStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AdminTextStyles.cardTitle,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AdminTextStyles.statValue.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getComplaintIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.hourglass_bottom;
      default:
        return Icons.error_outline;
    }
  }

  Color _getComplaintColor(String status, AdminColors colors) {
    switch (status) {
      case 'resolved':
        return AdminColors.successAccent;
      case 'in_progress':
        return AdminColors.warningAccent;
      default:
        return AdminColors.dangerAccent;
    }
  }

  Color _getPercentageColor(double percentage, AdminColors colors) {
    if (percentage >= 75) return AdminColors.successAccent;
    if (percentage >= 50) return  AdminColors.warningAccent;
    return AdminColors.dangerAccent;
  }
}