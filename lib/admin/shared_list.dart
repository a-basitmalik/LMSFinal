import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';
import 'student_view.dart';
import 'AddStudent.dart';
import 'AddTeacher.dart';
import 'TeacherProfile.dart';

class SharedList extends StatefulWidget {
  final String type;
  final int campusID;

  const SharedList({Key? key, required this.type, required this.campusID})
      : super(key: key);

  @override
  _SharedListState createState() => _SharedListState();
}

class _SharedListState extends State<SharedList> {
  late List<String> namesList;
  late List<String> fullNamesList;
  late List<int> idsList;
  late List<int> fullIdsList;
  late String headerText;
  late String baseUrl;
  late TextEditingController searchController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    namesList = [];
    fullNamesList = [];
    idsList = [];
    fullIdsList = [];
    searchController = TextEditingController();

    // Initialize based on type
    if (widget.type == "students") {
      headerText = "STUDENT PORTAL";
      baseUrl = "http://193.203.162.232:5050/shared/get_students";
    } else if (widget.type == "teachers") {
      headerText = "FACULTY PORTAL";
      baseUrl = "http://193.203.162.232:5050/shared/get_teachers";
    } else {
      headerText = "ALUMNI NETWORK";
      baseUrl = "http://193.203.162.232:5050/shared/get_alumni";
    }

    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    final url = "$baseUrl?campusID=${widget.campusID}";

    try {
      final response = await http.get(Uri.parse(url));
      print('API Response: ${response.body}'); // Debugging

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            if (widget.type == "students") {
              namesList = decodedData.map<String>((item) =>
              item['student_name']?.toString() ?? 'Unknown').toList();
              idsList = decodedData.map<int>((item) =>
              item['rfid'] as int? ?? -1).toList();
            } else if (widget.type == "teachers") {
              namesList = decodedData.map<String>((item) =>
              item['teacher_name']?.toString() ??
                  item['name']?.toString() ?? 'Unknown').toList();
              idsList = decodedData.map<int>((item) =>
              item['teacher_id'] as int? ??
                  item['id'] as int? ?? -1).toList();
            } else {
              namesList = decodedData.map<String>((item) =>
              item['name']?.toString() ?? 'Unknown').toList();
              idsList = decodedData.map<int>((item) =>
              item['id'] as int? ?? -1).toList();
            }

            fullNamesList = List.from(namesList);
            fullIdsList = List.from(idsList);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: AdminColors.dangerAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
        ),
      );
    }
  }

  void navigateToDetailView(int id, String name) {
    if (widget.type == "students") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AdminSingleStudentView(studentRfid: id),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    } else if (widget.type == "teachers") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TeacherProfileScreen(teacherId: id,),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
    // Handle other types if needed
  }

  void filterItems(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        namesList = List.from(fullNamesList);
        idsList = List.from(fullIdsList);
      } else {
        final filteredIndices = fullNamesList
            .asMap()
            .entries
            .where((entry) => entry.value
            .toLowerCase()
            .contains(searchText.toLowerCase()))
            .map((entry) => entry.key)
            .toList();

        namesList = filteredIndices.map((i) => fullNamesList[i]).toList();
        idsList = filteredIndices.map((i) => fullIdsList[i]).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.type == "students"
        ? AdminColors.studentColor
        : widget.type == "teachers"
        ? AdminColors.facultyColor
        : AdminColors.announcementColor;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with glass morphism effect
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: AdminColors.glassDecoration(
                borderColor: accentColor,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.type == "students"
                        ? Icons.school_outlined
                        : widget.type == "teachers"
                        ? Icons.people_alt_outlined
                        : Icons.workspaces_outlined,
                    color: AdminColors.primaryText,
                    size: 28,
                  ),
                  SizedBox(width: 15),
                  Text(
                    headerText,
                    style: AdminTextStyles.sectionTitle(accentColor),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AdminColors.secondaryText),
                    onPressed: fetchData,
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: AdminColors.glassDecoration(
                  borderRadius: 12,
                ),
                child: TextField(
                  controller: searchController,
                  style: AdminTextStyles.sectionHeader.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AdminColors.primaryAccent,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: AdminColors.disabledText),
                      onPressed: () {
                        searchController.clear();
                        filterItems('');
                      },
                    )
                        : null,
                    hintText: 'Search ${widget.type}...',
                    hintStyle: AdminTextStyles.cardSubtitle,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: filterItems,
                ),
              ),
            ),

            // Main content
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AdminColors.primaryAccent),
                  strokeWidth: 3,
                ),
              )
                  : namesList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: AdminColors.disabledText,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No ${widget.type} found',
                      style: AdminTextStyles.sectionHeader.copyWith(
                        color: AdminColors.disabledText,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: fetchData,
                      child: Text(
                        'Refresh',
                        style: AdminTextStyles.accentText(
                            AdminColors.primaryAccent),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.only(bottom: 80),
                itemCount: namesList.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: AdminColors.glassDecoration(
                      borderColor: accentColor.withOpacity(0.3),
                      borderRadius: 12,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            namesList[index].isNotEmpty
                                ? namesList[index][0].toUpperCase()
                                : '?',
                            style: AdminTextStyles.statValue.copyWith(
                              color: AdminColors.primaryText,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        namesList[index],
                        style: AdminTextStyles.cardTitle.copyWith(
                          fontSize: 16,
                          color: AdminColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        "ID: ${idsList[index]}",
                        style: AdminTextStyles.cardSubtitle,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: accentColor,
                        size: 16,
                      ),
                      onTap: () => navigateToDetailView(
                          idsList[index], namesList[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.type == "students" || widget.type == "teachers"
          ? FloatingActionButton(
        onPressed: () {
          if (widget.type == "students") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddStudentScreen(campusId: widget.campusID),
              ),
            );
          } else if (widget.type == "teachers") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTeacherScreen(campusId: widget.campusID),
              ),
            );
          }
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AdminColors.primaryAccent,
                AdminColors.secondaryAccent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primaryAccent.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: AdminColors.primaryText,
            size: 28,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      )
          : null,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}