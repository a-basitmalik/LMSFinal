import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
          backgroundColor: Colors.redAccent,
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
          pageBuilder: (_, __, ___) => TeacherProfileScreen(),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                      widget.type == "students"
                          ? Icons.school_outlined
                          : widget.type == "teachers"
                          ? Icons.people_alt_outlined
                          : Icons.workspaces_outlined,
                      color: Colors.white,
                      size: 28
                  ),
                  SizedBox(width: 15),
                  Text(
                    headerText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white70),
                    onPressed: fetchData,
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        filterItems('');
                      },
                    )
                        : null,
                    hintText: 'Search ${widget.type}...',
                    hintStyle: TextStyle(color: Colors.grey),
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
                      Colors.blueAccent),
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
                        color: Colors.grey[700]
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No ${widget.type} found',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: fetchData,
                      child: Text(
                        'Refresh',
                        style: TextStyle(color: Colors.blueAccent),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[850]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
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
                              Colors.blueAccent,
                              Colors.indigoAccent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            namesList[index].isNotEmpty
                                ? namesList[index][0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        namesList[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "ID: ${idsList[index]}",
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blueAccent,
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
              colors: [Colors.blueAccent, Colors.indigoAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.add, color: Colors.white, size: 28),
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