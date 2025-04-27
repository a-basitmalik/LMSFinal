import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'assessment_types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Results',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ResultListScreen(campusId: 1),
    );
  }
}

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

        // Validate response structure
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
            .where((student) => student.id != 'Error') // Filter out invalid entries
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
        backgroundColor: Colors.grey[900],
        title: const Text('Student Result Summary', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(summary.toString(), style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _printSummary(summary.toString());
            },
            child: const Text('Print', style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _printSummary(String summary) {
    // Implement printing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Printing summary...'),
        backgroundColor: Colors.blueAccent,
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
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'STUDENT RESULTS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.school,
                      size: 120,
                      color: Colors.white,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    hintText: 'Search by name or ID...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          )
              : _filteredStudents.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No students found',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: _fetchStudents,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final student = _filteredStudents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Year ${student.year}',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${student.id}',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${student.phone}',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
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
        icon: const Icon(Icons.description),
        label: const Text('Summary'),
        backgroundColor: Colors.blue.shade800,
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

