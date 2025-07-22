import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
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
        Uri.parse('http://193.203.162.232:5050/SubjectQuery/api/subjects/${widget.subject['subject_id']}/queries'),
        headers: {'Authorization': 'Bearer YOUR_ACCESS_TOKEN'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          queries = data.map<Map<String, dynamic>>((query) {
            String createdAt;
            if (query['created_at'] is String) {
              createdAt = query['created_at'];
            } else {
              createdAt = DateTime.now().toIso8601String();
            }

            return {
              'id': query['id']?.toString() ?? '',
              'student_name': query['student_name']?.toString() ?? 'Anonymous',
              'student_avatar': '👤',
              'question': query['question']?.toString() ?? '',
              'status': query['status']?.toString()?.toLowerCase() ?? 'pending',
              'created_at': createdAt,
              'answer': query['answer']?.toString(),
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
        SnackBar(
          content: Text('Error fetching queries: $e'),
          backgroundColor: TeacherColors.dangerAccent,
        ),
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
        Uri.parse('http://193.203.162.232:5050/SubjectQuery/api/queries/$queryId/respond'),
        headers: {
          'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
          'Content-Type': 'application/json',
        },
        body: json.encode({'answer': responseText}),
      );

      if (response.statusCode == 200) {
        await _fetchQueries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Response sent successfully', style: TeacherTextStyles.primaryButton),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
      } else {
        throw Exception('Failed to send response: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending response: $e', style: TeacherTextStyles.primaryButton),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  void _showResponseDialog(Map<String, dynamic> query) {
    final subjectColor = widget.subject['color'] ?? TeacherColors.primaryAccent;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: TeacherColors.secondaryBackground,
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
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 16),
              Text(query['question'], style: TeacherTextStyles.listItemSubtitle),
              const SizedBox(height: 16),
              TextField(
                controller: _responseController,
                style: TeacherTextStyles.listItemSubtitle,
                decoration: InputDecoration(
                  labelText: 'Your Response',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.primaryAccent),
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
                    child: Text('Cancel', style: TeacherTextStyles.secondaryButton),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subjectColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _respondToQuery(
                        query['id'].toString(),
                        _responseController.text,
                      );
                      _responseController.clear();
                      Navigator.pop(context);
                    },
                    child: Text('Send', style: TeacherTextStyles.primaryButton),
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
    final subjectColor = widget.subject['color'] ?? TeacherColors.primaryAccent;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Queries',
          style: TeacherTextStyles.className,
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _buildBody(subjectColor),
    );
  }


  Widget _buildBody(Color subjectColor) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: TeacherColors.primaryAccent),
      );
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: TeacherColors.dangerAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load queries',
              style: TeacherTextStyles.sectionHeader,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
              ),
              onPressed: _fetchQueries,
              child: Text('Retry', style: TeacherTextStyles.primaryButton),
            ),
          ],
        ),
      );
    }

    if (queries.isEmpty) {
      return Center(
        child: Text(
          'No queries yet',
          style: TeacherTextStyles.cardSubtitle,
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: TeacherColors.primaryBackground,
      color: TeacherColors.primaryAccent,
      onRefresh: _fetchQueries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: queries.length,
        itemBuilder: (context, index) => _buildQueryCard(
          queries[index],
          subjectColor,
        ),
      ),
    );
  }

  Widget _buildQueryCard(
      Map<String, dynamic> query,
      Color subjectColor,
      ) {
    final isPending = query['status'] == 'pending';
    final date = DateFormat('MMM d, h:mm a').format(
      DateTime.parse(query['created_at']).toLocal(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TeacherColors.glassDecoration(
        borderColor: subjectColor.withOpacity(0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPending
                      ? TeacherColors.warningAccent.withOpacity(0.2)
                      : TeacherColors.successAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPending
                        ? TeacherColors.warningAccent
                        : TeacherColors.successAccent,
                    width: 1,
                  ),
                ),
                child: Text(
                  isPending ? 'PENDING' : 'RESOLVED',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: isPending
                        ? TeacherColors.warningAccent
                        : TeacherColors.successAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: subjectColor.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      query['student_avatar'] ?? '👤',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query['student_name'] ?? 'Anonymous',
                      style: TeacherTextStyles.listItemTitle,
                    ),
                    Text(
                      date,
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              query['question'],
              style: TeacherTextStyles.listItemSubtitle,
            ),
            if (query['answer'] != null) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Response',
                    style: TeacherTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    query['answer'] ?? '',
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: subjectColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => _showResponseDialog(query),
                  child: Text(
                    'Respond Now',
                    style: TeacherTextStyles.primaryButton,
                  ),
                ),
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