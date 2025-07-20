import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'AddSubject.dart';
import 'SubjectDetails.dart';



class SubjectDashboard extends StatefulWidget {
  final int campusId;
  final String campusName;
  final int subjectGroupId;

  const SubjectDashboard({
    Key? key,
    required this.campusId,
    required this.subjectGroupId,
    this.campusName = "Campus",
  }) : super(key: key);

  @override
  _SubjectDashboardState createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  List<SubjectItem> _subjectItems = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _subjectGroupName = "";

  @override
  void initState() {
    super.initState();
    _fetchSubjectGroupName();
    _fetchSubjects();
  }

  Future<void> _fetchSubjectGroupName() async {
    try {
      final response = await http.get(Uri.parse(
          'http://193.203.162.232:5050/subject/api/subject_groups/${widget.subjectGroupId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _subjectGroupName = data['subject_group_name'] ?? "Subjects";
        });
      }
    } catch (e) {
      print('Error fetching subject group name: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
        'http://193.203.162.232:5050/subject/api/subjects/group_subjects?campus_id=${widget.campusId}&subject_group_id=${widget.subjectGroupId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final subjects = data['subjects'] as List;
          final List<SubjectItem> subjectItems = [];

          // Group subjects by year
          final firstYearSubjects = subjects.where((s) => s['year'] == 1).toList();
          final secondYearSubjects = subjects.where((s) => s['year'] == 2).toList();

          // Add First Year header if there are first year subjects
          if (firstYearSubjects.isNotEmpty) {
            subjectItems.add(SubjectItem(type: SubjectItemType.header, title: 'First Year'));
            subjectItems.addAll(firstYearSubjects.map((s) => SubjectItem(
              type: SubjectItemType.subject,
              subject: Subject(
                id: s['subject_id'],
                name: s['subject_name'],
                teacher: s['teacher_name'] ?? 'Not assigned',
                studentCount: s['student_count'] ?? 0,
                year: s['year'],
                day: s['day'],
                time: s['time'],
              ),
            )).toList());
          }

          // Add Second Year header if there are second year subjects
          if (secondYearSubjects.isNotEmpty) {
            subjectItems.add(SubjectItem(type: SubjectItemType.header, title: 'Second Year'));
            subjectItems.addAll(secondYearSubjects.map((s) => SubjectItem(
              type: SubjectItemType.subject,
              subject: Subject(
                id: s['subject_id'],
                name: s['subject_name'],
                teacher: s['teacher_name'] ?? 'Not assigned',
                studentCount: s['student_count'] ?? 0,
                year: s['year'],
                day: s['day'],
                time: s['time'],
              ),
            )).toList());
          }

          setState(() {
            _subjectItems = subjectItems;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load subjects');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    final colors = AdminColors();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AdminTextStyles.cardSubtitle),
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminColors();
    final textStyles = AdminTextStyles();

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _subjectGroupName.toUpperCase(),
                style: AdminTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AdminColors.primaryAccent.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AdminColors.primaryAccent.withOpacity(0.7),
                      AdminColors.secondaryAccent.withOpacity(0.7),
                      AdminColors.infoAccent.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: 0.2,
                        child: Icon(
                          Icons.school,
                          size: 200,
                          color: AdminColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: AdminColors.glassDecoration(),
                child: TextField(
                  controller: _searchController,
                  style: AdminTextStyles.cardTitle,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AdminColors.primaryAccent),
                    hintText: 'Search subjects...',
                    hintStyle: AdminTextStyles.cardSubtitle,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
              ),
            ),
          ),

          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
                strokeWidth: 3,
              ),
            ),
          )
              : _subjectItems.isEmpty
              ? SliverFillRemaining(
            child: Center(
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
                    'No subjects found for this group',
                    style: AdminTextStyles.cardSubtitle,
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: _fetchSubjects,
                    style: TextButton.styleFrom(
                      foregroundColor: AdminColors.primaryAccent,
                      side: BorderSide(color: AdminColors.primaryAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Refresh', style: AdminTextStyles.secondaryButton),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = _subjectItems[index];
                if (item.type == SubjectItemType.header) {
                  return _buildHeader(item.title!, colors, textStyles);
                } else {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildSubjectItem(item.subject!, colors, textStyles),
                      ),
                    ),
                  );
                }
              },
              childCount: _subjectItems.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => AddSubjectScreen(
                campusId: widget.campusId,
                campusName: widget.campusName,
              ),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        },
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
          child: Icon(Icons.add, color: AdminColors.primaryText, size: 28),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader(String title, AdminColors colors, AdminTextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: AdminTextStyles.sectionTitle(AdminColors.primaryAccent),
      ),
    );
  }

  Widget _buildSubjectItem(Subject subject, AdminColors colors, AdminTextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AdminColors.glassDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectDetailsPage(
                    subjectId: subject.id,
                    year: subject.year.toString(),
                    subjectName: subject.name,
                    campusId: widget.campusId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: AdminTextStyles.cardTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AdminColors.cardBorder),
                        ),
                        child: Text(
                          '${subject.studentCount}',
                          style: AdminTextStyles.statValue.copyWith(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: AdminColors.secondaryText),
                      SizedBox(width: 8),
                      Text(
                        subject.teacher,
                        style: AdminTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AdminColors.secondaryText),
                      SizedBox(width: 8),
                      Text(
                        '${subject.day} ${subject.time != null ? 'at ${subject.time}' : ''}',
                        style: AdminTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: subject.studentCount / 100, // Adjust based on your data
                    backgroundColor: AdminColors.secondaryBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SubjectItemType { header, subject }

class SubjectItem {
  final SubjectItemType type;
  final String? title;
  final Subject? subject;

  SubjectItem({
    required this.type,
    this.title,
    this.subject,
  });
}

class Subject {
  final int id;
  final String name;
  final String teacher;
  final int studentCount;
  final int year;
  final String? day;
  final String? time;

  Subject({
    required this.id,
    required this.name,
    required this.teacher,
    required this.studentCount,
    required this.year,
    this.day,
    this.time,
  });
}