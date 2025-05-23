import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SubjectQueriesScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectQueriesScreen({super.key, required this.subject});

  @override
  _SubjectQueriesScreenState createState() => _SubjectQueriesScreenState();
}

class _SubjectQueriesScreenState extends State<SubjectQueriesScreen> {
  List<Map<String, dynamic>> queries = [];
  bool isLoading = false; // Changed to false since we're using dummy data
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    // Dummy data with more realistic queries
    setState(() {
      queries = [
        {
          'id': '1',
          'student_name': 'Alex Johnson',
          'student_avatar': '👨‍🎓',
          'question':
              'Could you explain the concept of polynomial division again? I missed the last class.',
          'status': 'pending',
          'created_at': '2023-06-10T09:30:00Z',
          'response': null,
        },
        {
          'id': '2',
          'student_name': 'Sarah Williams',
          'student_avatar': '👩‍🎓',
          'question':
              'Is there any recommended reading material for the upcoming exam?',
          'status': 'answered',
          'created_at': '2023-06-08T14:15:00Z',
          'response':
              'Yes, please check chapters 3-5 in the textbook and the additional PDF I shared on the course portal.',
        },
        {
          'id': '3',
          'student_name': 'Michael Chen',
          'student_avatar': '👨‍💻',
          'question':
              'Can I get an extension for Assignment 2? I had a family emergency.',
          'status': 'answered',
          'created_at': '2023-06-05T16:45:00Z',
          'response':
              'I understand. You have until Friday to submit without penalty.',
        },
        {
          'id': '4',
          'student_name': 'Emma Davis',
          'student_avatar': '👩‍🔬',
          'question':
              'The solution for problem 3 in the practice set seems incorrect. Can you verify?',
          'status': 'pending',
          'created_at': '2023-06-12T11:20:00Z',
          'response': null,
        },
      ];
    });
  }

  Future<void> _respondToQuery(String queryId, String responseText) async {
    if (responseText.trim().isEmpty) return;

    setState(() {
      final index = queries.indexWhere((q) => q['id'] == queryId);
      if (index != -1) {
        queries[index]['status'] = 'answered';
        queries[index]['response'] = responseText;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Response sent successfully')));
  }

  void _showResponseDialog(Map<String, dynamic> query) {
    final subjectColor =
        widget.subject['color'] ?? Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respond to ${query['student_name']}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(query['question'], style: GoogleFonts.poppins()),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _responseController,
                    decoration: InputDecoration(
                      labelText: 'Your Response',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subjectColor,
                        ),
                        onPressed: () {
                          _respondToQuery(
                            query['id'],
                            _responseController.text,
                          );
                          _responseController.clear();
                          Navigator.pop(context);
                        },
                        child: Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Queries', // Dynamic subject name
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
              : queries.isEmpty
              ? Center(
                child: Text(
                  'No queries yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async => _loadDummyData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queries.length,
                  itemBuilder:
                      (context, index) =>
                          _buildQueryCard(queries[index], theme, subjectColor),
                ),
              ),
    );
  }

  Widget _buildQueryCard(
    Map<String, dynamic> query,
    ThemeData theme,
    Color subjectColor,
  ) {
    final isPending = query['status'] == 'pending';
    final date = DateFormat(
      'MMM d, h:mm a',
    ).format(DateTime.parse(query['created_at']));
    final hasResponse = query['response'] != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip aligned to right like assignments screen
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  isPending ? 'PENDING' : 'RESOLVED',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: isPending ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            // Student info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: subjectColor.withAlpha(
                    51,
                  ), // Replaced withAlpha for opacity
                  child: Text(
                    query['student_avatar'],
                  ), // Moved child to the end
                ),
                const SizedBox(width: 12), // Corrected misplaced const
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query['student_name'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Question
            Text(
              query['question'],
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            if (hasResponse) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Response',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(query['response'], style: GoogleFonts.poppins()),
                ],
              ),
            ],

            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Align to the left
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subjectColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showResponseDialog(query),
                    child: Text(
                      'Respond Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
}
