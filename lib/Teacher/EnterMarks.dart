import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnterMarksScreen extends StatefulWidget {
  final String assessmentId;
  final String assessmentTitle;
  final int totalMarks;
  final Color subjectColor;

  const EnterMarksScreen({
    super.key,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.totalMarks,
    required this.subjectColor,
  });

  @override
  _EnterMarksScreenState createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  List<Map<String, dynamic>> _students = [];
  final Map<String, TextEditingController> _markControllers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  final String baseUrl = 'http://your-flask-server.com/api';
  final String studentsEndpoint = '/students';
  final String submitMarksEndpoint = '/marks';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$studentsEndpoint?assessment=${widget.assessmentId}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _students = List<Map<String, dynamic>>.from(data);
          for (var student in _students) {
            _markControllers[student['id']] = TextEditingController(
              text: student['mark']?.toString() ?? '',
            );
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _submitMarks() async {
    setState(() => _isSubmitting = true);

    try {
      final marks =
          _students.map((student) {
            return {
              'student_id': student['id'],
              'mark': int.tryParse(_markControllers[student['id']]!.text) ?? 0,
            };
          }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl$submitMarksEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assessment_id': widget.assessmentId,
          'marks': marks,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marks submitted successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to submit marks');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enter Marks: ${widget.assessmentTitle}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Marks: ${widget.totalMarks}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Students: ${_students.length}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(child: Text(student['name'][0])),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    student['name'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _markControllers[student['id']],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Marks',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitMarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.subjectColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                  'Submit Marks',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
