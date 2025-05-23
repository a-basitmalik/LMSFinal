import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectAssignmentsScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectAssignmentsScreen({super.key, required this.subject});

  @override
  _SubjectAssignmentsScreenState createState() =>
      _SubjectAssignmentsScreenState();
}

class _SubjectAssignmentsScreenState extends State<SubjectAssignmentsScreen> {
  List<Map<String, dynamic>> assignments = [];
  bool isLoading = true;
  final String _apiUrl = 'https://your-api-endpoint.com/assignments';

  @override
  void initState() {
    super.initState();
    _loadDummyData(); // Replace with _fetchAssignments() when API is ready
  }

  Future<void> _fetchAssignments() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?subject=${widget.subject['code']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          assignments = List<Map<String, dynamic>>.from(data['assignments']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading assignments: $e')));
    }
  }

  Future<void> _fetchSubmissions(String assignmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/$assignmentId/submissions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading submissions: $e')));
      rethrow;
    }
  }

  void _loadDummyData() {
    setState(() {
      assignments = [
        {
          'id': '1',
          'title': 'Linear Algebra Homework',
          'description': 'Solve problems 1-10 from chapter 3',
          'due_date': '2023-06-15T23:59:00Z',
          'posted_date': '2023-06-01T00:00:00Z',
          'submitted': 32,
          'total': 45,
          'status': 'active',
          'attachments': ['problem_set.pdf'],
        },
        {
          'id': '2',
          'title': 'Midterm Project',
          'description': 'Research paper on matrix transformations (5-7 pages)',
          'due_date': '2023-06-30T23:59:00Z',
          'posted_date': '2023-06-10T00:00:00Z',
          'submitted': 12,
          'total': 45,
          'status': 'upcoming',
          'attachments': ['project_guidelines.pdf', 'sample_paper.pdf'],
        },
        {
          'id': '3',
          'title': 'Final Exam Practice',
          'description': 'Complete the practice exam and check your answers',
          'due_date': '2023-07-10T23:59:00Z',
          'posted_date': '2023-06-25T00:00:00Z',
          'submitted': 8,
          'total': 45,
          'status': 'upcoming',
          'attachments': ['practice_exam.pdf', 'answer_key.pdf'],
        },
      ];
      isLoading = false;
    });
  }

  void _navigateToSubmissions(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AssignmentSubmissionsScreen(
              assignment: assignment,
              subjectColor:
                  widget.subject['color'] ?? Theme.of(context).primaryColor,
              fetchSubmissions: _fetchSubmissions,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;

    return Scaffold(
      extendBody: true, // Add this line
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Assignments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : assignments.isEmpty
              ? Center(
                child: Text(
                  'No assignments yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchAssignments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder:
                      (context, index) => _buildAssignmentCard(
                        assignments[index],
                        theme,
                        subjectColor,
                      ),
                ),
              ),
    );
  }

  Widget _buildAssignmentCard(
    Map<String, dynamic> assignment,
    ThemeData theme,
    Color subjectColor,
  ) {
    final dueDate = DateTime.parse(assignment['due_date']);
    final formattedDate = DateFormat('MMM d, y').format(dueDate);
    final timeLeft = dueDate.difference(DateTime.now());
    final progress = assignment['submitted'] / assignment['total'];
    final isActive = assignment['status'] == 'active';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToSubmissions(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status chip only (removed the title)
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(
                    isActive ? 'ACTIVE' : 'UPCOMING',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assignment['description'],
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due $formattedDate',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${timeLeft.inDays}d left',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: timeLeft.inDays < 3 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submissions: ${assignment['submitted']}/${assignment['total']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: subjectColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                  ),
                ],
              ),
              if (assignment['attachments'] != null &&
                  assignment['attachments'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    ...assignment['attachments'].map<Widget>(
                      (file) => Chip(
                        label: Text(
                          file,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToSubmissions(assignment),
                  child: Text(
                    'VIEW SUBMISSIONS',
                    style: GoogleFonts.poppins(
                      color: subjectColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssignmentSubmissionsScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final Color subjectColor;
  final Future<dynamic> Function(String) fetchSubmissions;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.subjectColor,
    required this.fetchSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // In a real app, you would use fetchSubmissions(assignment['id']) with FutureBuilder
    final submissions = [
      {
        'student_id': '101',
        'student_name': 'Alice Johnson',
        'submitted_at': '2023-06-14T14:30:00Z',
        'status': 'submitted',
        'file': 'alice_hw1.pdf',
        'grade': null,
      },
      {
        'student_id': '102',
        'student_name': 'Bob Smith',
        'submitted_at': '2023-06-15T10:15:00Z',
        'status': 'submitted',
        'file': 'bob_hw1.pdf',
        'grade': 85,
      },
      {
        'student_id': '103',
        'student_name': 'Charlie Brown',
        'submitted_at': null,
        'status': 'missing',
        'file': null,
        'grade': null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assignment['title'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder:
            (context, index) =>
                _buildSubmissionCard(submissions[index], theme, subjectColor),
      ),
    );
  }

  Widget _buildSubmissionCard(
    Map<String, dynamic> submission,
    ThemeData theme,
    Color subjectColor,
  ) {
    final isSubmitted = submission['status'] == 'submitted';
    final submittedAt =
        submission['submitted_at'] != null
            ? DateFormat(
              'MMM d, h:mm a',
            ).format(DateTime.parse(submission['submitted_at']))
            : 'Not submitted';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  submission['student_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    isSubmitted ? 'SUBMITTED' : 'MISSING',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: isSubmitted ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSubmitted) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    submittedAt,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    submission['file'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subjectColor,
                    ),
                  ),
                ],
              ),
            ],
            if (submission['grade'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.grade, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Grade: ${submission['grade']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSubmitted && submission['grade'] == null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subjectColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      // Grade submission
                    },
                    child: Text(
                      'Grade Submission',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (!isSubmitted)
                  TextButton(
                    onPressed: () {
                      // Send reminder
                    },
                    child: Text(
                      'Send Reminder',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
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
}
