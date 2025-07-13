import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectQueriesScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectQueriesScreen({super.key, required this.subject});

  @override
  _SubjectQueriesScreenState createState() => _SubjectQueriesScreenState();
}

class _SubjectQueriesScreenState extends State<SubjectQueriesScreen> {
  List<Map<String, dynamic>> queries = [];
  bool isLoading = true;
  bool isError = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQueries();
  }

  Future<void> _fetchQueries() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.185:5050/SubjectQuery/api/subjects/${widget.subject['subject_id']}/queries'),
        headers: {'Authorization': 'Bearer YOUR_ACCESS_TOKEN'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          queries = data.map<Map<String, dynamic>>((query) {
            // Convert datetime to ISO string if it's not already
            String createdAt;
            if (query['created_at'] is String) {
              createdAt = query['created_at'];
            } else {
              // Handle if created_at is a datetime object (from Python)
              createdAt = DateTime.now().toIso8601String();
            }

            return {
              'id': query['id']?.toString() ?? '',
              'student_name': query['student_name']?.toString() ?? 'Anonymous',
              'student_avatar': '👤', // Default avatar since API doesn't provide
              'question': query['question']?.toString() ?? '',
              'status': query['status']?.toString()?.toLowerCase() ?? 'pending',
              'created_at': createdAt,
              'answer': query['answer']?.toString(), // Note: API uses 'answer' not 'response'
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load queries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching queries: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching queries: $e')),
      );
    }
  }

  Future<void> _respondToQuery(String queryId, String responseText) async {
    if (responseText.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.18.185:5050/SubjectQuery/api/queries/$queryId/respond'),
        headers: {
          'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
          'Content-Type': 'application/json',
        },
        body: json.encode({'answer': responseText}), // Changed from 'response' to 'answer'
      );

      if (response.statusCode == 200) {
        await _fetchQueries();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent successfully')),
        );
      } else {
        throw Exception('Failed to send response: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending response: $e')),
      );
    }
  }
  void _showResponseDialog(Map<String, dynamic> query) {
    final subjectColor = widget.subject['color'] ?? Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subjectColor,
                    ),
                    onPressed: () {
                      _respondToQuery(
                        query['id'].toString(),
                        _responseController.text,
                      );
                      _responseController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Send'),
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
          '${widget.subject['name']} Queries',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _buildBody(theme, subjectColor),
    );
  }

  Widget _buildBody(ThemeData theme, Color subjectColor) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load queries',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQueries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (queries.isEmpty) {
      return Center(
        child: Text(
          'No queries yet',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchQueries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: queries.length,
        itemBuilder: (context, index) => _buildQueryCard(
          queries[index],
          theme,
          subjectColor,
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
    final date = DateFormat('MMM d, h:mm a').format(
      DateTime.parse(query['created_at']).toLocal(),
    );
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: subjectColor.withAlpha(51),
                  child: Text(
                    query['student_avatar'] ?? '👤',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query['student_name'] ?? 'Anonymous',
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
            Text(
              query['question'],
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (query['answer'] != null || query['answer'] != null) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Response',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    query['answer'] ?? query['answer'] ?? '',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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