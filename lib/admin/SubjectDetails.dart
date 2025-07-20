import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';

class SubjectDetailsPage extends StatefulWidget {
  final int subjectId;
  final String year;
  final String subjectName;
  final int campusId;

  const SubjectDetailsPage({
    Key? key,
    required this.subjectId,
    required this.year,
    required this.subjectName,
    required this.campusId,
  }) : super(key: key);

  @override
  _SubjectDetailsPageState createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  List<Student> _students = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://193.203.162.232:5050/subject/students?subject_id=${widget.subjectId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _students = List<Student>.from(data['students'].map((student) => Student(
            id: student['id'],
            name: student['name'],
            rollNumber: student['roll_number'],
            avatarColor: _getRandomColor(),
          )));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getRandomColor() {
    final colors = [
      AdminColors.primaryAccent,
      AdminColors.secondaryAccent,
      AdminColors.successAccent,
      AdminColors.warningAccent,
      AdminColors.infoAccent,
    ];
    return colors[_students.length % colors.length];
  }

  void _filterStudents() {
    // Implement search filtering
  }

  Future<void> _removeStudent(int studentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(context),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse("http://193.203.162.232:5050/subject/remove_student"),
          body: json.encode({
            'subject_id': widget.subjectId,
            'student_id': studentId,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          setState(() {
            _students.removeWhere((student) => student.id == studentId);
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: AdminColors.glassDecoration(),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONFIRM REMOVAL',
              style: AdminTextStyles.sectionHeader,
            ),
            SizedBox(height: 16),
            Text(
              'Remove this student from ${widget.subjectName}?',
              style: AdminTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'CANCEL',
                    style: AdminTextStyles.secondaryButton,
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: AdminColors.cardBorder,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'REMOVE',
                    style: AdminTextStyles.secondaryButton.copyWith(
                      color: AdminColors.dangerAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStudentDialog() async {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: AdminColors.glassDecoration(
          borderRadius: 20,
          borderColor: AdminColors.cardBorder,
        ),
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'ADD STUDENTS',
              style: AdminTextStyles.sectionHeader,
            ),
            SizedBox(height: 16),
            Container(
              decoration: AdminColors.glassDecoration(),
              child: TextField(
                controller: TextEditingController(),
                style: AdminTextStyles.cardTitle,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: AdminTextStyles.cardSubtitle,
                  prefixIcon: Icon(Icons.search, color: AdminColors.secondaryText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Student>>(
                future: _fetchAllStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
                    ));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(
                      'No students available',
                      style: AdminTextStyles.cardSubtitle,
                    ));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(top: 16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final student = snapshot.data![index];
                      return _buildStudentTile(student, true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Student>> _fetchAllStudents() async {
    try {
      final response = await http.get(
        Uri.parse("http://193.203.162.232:5050/students/all"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Student>.from(data['students'].map((student) => Student(
          id: student['id'],
          name: student['name'],
          rollNumber: student['roll_number'],
          avatarColor: _getRandomColor(),
        )));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Widget _buildStudentTile(Student student, bool isAddAction) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: AdminColors.glassDecoration(),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AdminColors.accentGradient(student.avatarColor),
          ),
          child: Center(
            child: Text(
              student.name.substring(0, 1),
              style: AdminTextStyles.statValue.copyWith(color: AdminColors.primaryText),
            ),
          ),
        ),
        title: Text(student.name, style: AdminTextStyles.cardTitle),
        subtitle: Text(student.rollNumber, style: AdminTextStyles.cardSubtitle),
        trailing: IconButton(
          icon: Icon(
            isAddAction ? Icons.add_circle : Icons.remove_circle,
            color: isAddAction ? AdminColors.successAccent : AdminColors.dangerAccent,
          ),
          onPressed: () async {
            if (isAddAction) {
              Navigator.pop(context);
              setState(() => _students.add(student));
            } else {
              await _removeStudent(student.id);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final textStyles = context.adminTextStyles;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subjectName.toUpperCase(),
                style: AdminTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AdminColors.primaryAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: AdminColors.glassDecoration(),
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '${widget.year} • ${_students.length} STUDENTS',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.primaryAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
              ),
            ),
          )
              : _students.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 60,
                    color: AdminColors.disabledText,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'NO STUDENTS ENROLLED',
                    style: AdminTextStyles.cardSubtitle.copyWith(
                      color: AdminColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStudentTile(_students[index], false),
                );
              },
              childCount: _students.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: Container(
          width: 60,
          height: 60,
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
          child: Icon(Icons.add, color: AdminColors.primaryText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class Student {
  final int id;
  final String name;
  final String rollNumber;
  final Color avatarColor;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.avatarColor,
  });
}