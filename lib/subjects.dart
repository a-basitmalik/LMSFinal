import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'AddSubject.dart';
import 'SubjectDetails.dart';
class SubjectDashboard extends StatefulWidget {
  final int campusId;
  final String campusName="Campus";

  const SubjectDashboard({Key? key, required this.campusId}) : super(key: key);

  @override
  _SubjectDashboardState createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  List<SubjectItem> _subjectItems = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://193.203.162.232:5050/subject/get_subjects_dashboard?campus_id=${widget.campusId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final subjects = data['subjects'] as List;
          final List<SubjectItem> subjectItems = [];

          // Add Pre Medical header and subjects
          subjectItems.add(SubjectItem(type: SubjectItemType.header, title: 'Pre Medical'));
          subjectItems.addAll(subjects
              .where((s) => _isPreMedicalSubject(s['subject_name']))
              .map((s) => SubjectItem(
            type: SubjectItemType.subject,
            subject: Subject(
              name: s['subject_name'],
              teacher: s['teacher_name'],
              studentCount: s['student_count'],
            ),
          ))
              .toList());

          // Add Computer header and subjects
          subjectItems.add(SubjectItem(type: SubjectItemType.header, title: 'Computer'));
          subjectItems.addAll(subjects
              .where((s) => _isComputerSubject(s['subject_name']))
              .map((s) => SubjectItem(
            type: SubjectItemType.subject,
            subject: Subject(
              name: s['subject_name'],
              teacher: s['teacher_name'],
              studentCount: s['student_count'],
            ),
          ))
              .toList());

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
  }

  bool _isPreMedicalSubject(String subjectName) {
    final name = subjectName.toLowerCase();
    return name.contains('biology') || name.contains('chemistry');
  }

  bool _isComputerSubject(String subjectName) {
    final name = subjectName.toLowerCase();
    return name.contains('math') ||
        name.contains('ict') ||
        name.contains('computer') ||
        name.contains('programming');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Futuristic App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'SUBJECT PORTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent.withOpacity(0.7),
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
                      Colors.blue.shade900,
                      Colors.indigo.shade800,
                      Colors.purple.shade900,
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                    hintText: 'Search subjects...',
                    hintStyle: TextStyle(color: Colors.grey),
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

          // Content
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
                    color: Colors.grey[700],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No subjects found',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchSubjects,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.blueAccent),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Refresh',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
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
                  return _buildHeader(item.title!);
                } else {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildSubjectItem(item.subject!),
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
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubjectItem(Subject subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
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
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectDetailsPage(
                    subjectId: 1, // Replace with actual subject ID from your data
                    year: '2023-24', // Get from your data
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${subject.studentCount}',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        subject.teacher,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: subject.studentCount / 100, // Adjust based on your data
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
  final String name;
  final String teacher;
  final int studentCount;

  Subject({
    required this.name,
    required this.teacher,
    required this.studentCount,
  });
}
