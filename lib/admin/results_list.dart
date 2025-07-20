import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';


import 'assessment_types.dart';

class ResultListScreen extends StatefulWidget {
  final int campusId;

  const ResultListScreen({Key? key, required this.campusId}) : super(key: key);

  @override
  _ResultListScreenState createState() => _ResultListScreenState();
}

class _ResultListScreenState extends State<ResultListScreen> {
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://193.203.162.232:5050/result/get_students?campus_id=${widget.campusId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['students'] == null) {
          throw Exception('Invalid response: missing students array');
        }

        final students = (data['students'] as List)
            .map((student) {
          try {
            return Student(
              id: student['student_id']?.toString() ?? 'N/A',
              name: student['name']?.toString() ?? 'No Name',
              phone: student['phone']?.toString() ?? 'No Phone',
              year: (student['year'] as num?)?.toInt() ?? 0,
            );
          } catch (e) {
            print('Error parsing student: $e');
            return Student(
              id: 'Error',
              name: 'Invalid Data',
              phone: '',
              year: 0,
            );
          }
        })
            .where((student) => student.id != 'Error')
            .toList();

        setState(() {
          _students = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      _showErrorSnackbar('Invalid API response format');
      setState(() => _isLoading = false);
    } on http.ClientException catch (e) {
      _showErrorSnackbar('Network error: ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      _showErrorSnackbar('Unexpected error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((student) {
        return student.name.toLowerCase().contains(query) ||
            student.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showResultSummary() {
    if (_students.isEmpty) {
      _showMessage('No students available', 'The student list is empty.');
      return;
    }

    final yearCounts = <int, int>{};
    for (final student in _students) {
      yearCounts[student.year] = (yearCounts[student.year] ?? 0) + 1;
    }

    final summary = StringBuffer()
      ..writeln('Total Students: ${_students.length}\n')
      ..writeln('Students by Year:');

    yearCounts.forEach((year, count) {
      summary.writeln('Year $year: $count students');
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.secondaryBackground,
        title: Text(
          'Student Result Summary',
          style: AdminTextStyles.sectionHeader,
        ),
        content: SingleChildScrollView(
          child: Text(
            summary.toString(),
            style: AdminTextStyles.cardSubtitle.copyWith(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _printSummary(summary.toString());
            },
            child: Text(
              'Print',
              style: AdminTextStyles.secondaryButton.copyWith(
                color: AdminColors.primaryAccent,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AdminTextStyles.secondaryButton,
            ),
          ),
        ],
      ),
    );
  }

  void _printSummary(String summary) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Printing summary...',
          style: AdminTextStyles.cardSubtitle,
        ),
        backgroundColor: AdminColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.secondaryBackground,
        title: Text(title, style: AdminTextStyles.sectionHeader),
        content: Text(message, style: AdminTextStyles.cardSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AdminTextStyles.secondaryButton.copyWith(
                color: AdminColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AdminTextStyles.cardSubtitle,
        ),
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openStudentDetails(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentTypeScreen(
          studentId: student.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'STUDENT RESULTS',
                style: AdminTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AdminColors.resultsColor,
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
                      AdminColors.resultsColor.withOpacity(0.8),
                      AdminColors.resultsColor.withOpacity(0.6),
                      AdminColors.resultsColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.school,
                      size: 120,
                      color: AdminColors.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: AdminColors.glassDecoration(
                  borderRadius: 12,
                  borderColor: AdminColors.resultsColor,
                ),
                child: TextField(
                  controller: _searchController,
                  style: AdminTextStyles.cardTitle,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AdminColors.resultsColor,
                    ),
                    hintText: 'Search by name or ID...',
                    hintStyle: AdminTextStyles.cardSubtitle,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
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
                color: AdminColors.resultsColor,
              ),
            ),
          )
              : _filteredStudents.isEmpty
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
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: AdminTextStyles.cardSubtitle,
                  ),
                  TextButton(
                    onPressed: _fetchStudents,
                    child: Text(
                      'Retry',
                      style: AdminTextStyles.secondaryButton.copyWith(
                        color: AdminColors.resultsColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final student = _filteredStudents[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: AdminColors.glassDecoration(
                    borderRadius: 12,
                    borderColor: AdminColors.studentColor,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openStudentDetails(student),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: AdminTextStyles.cardTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminColors.studentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Year ${student.year}',
                                  style: AdminTextStyles.cardSubtitle.copyWith(
                                    color: AdminColors.studentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${student.id}',
                            style: AdminTextStyles.cardSubtitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${student.phone}',
                            style: AdminTextStyles.cardSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: _filteredStudents.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showResultSummary,
        icon: Icon(
          Icons.description,
          color: AdminColors.primaryText,
        ),
        label: Text(
          'Summary',
          style: AdminTextStyles.primaryButton,
        ),
        backgroundColor: AdminColors.resultsColor,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class Student {
  final String id;
  final String name;
  final String phone;
  final int year;

  Student({
    required this.id,
    required this.name,
    required this.phone,
    required this.year,
  });
}