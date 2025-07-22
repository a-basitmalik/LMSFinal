import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';
import 'package:flutter/animation.dart';


class SubjectQueriesScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectQueriesScreen({super.key, required this.subject});

  @override
  _SubjectQueriesScreenState createState() => _SubjectQueriesScreenState();
}

class _SubjectQueriesScreenState extends State<SubjectQueriesScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> queries = [];
  bool isLoading = true;
  bool isError = false;
  final TextEditingController _responseController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchQueries();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // <-- This will also require a mixin
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _responseController.dispose();
    super.dispose();
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
          style: TeacherTextStyles.className.copyWith(
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        backgroundColor: subjectColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                subjectColor.withOpacity(0.9),
                subjectColor.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: subjectColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(subjectColor),
      ),
    );
  }

  Widget _buildBody(Color subjectColor) {
    if (isLoading) {
      return Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                  backgroundColor: subjectColor.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Queries...',
                style: TeacherTextStyles.cardTitle.copyWith(
                  color: TeacherColors.primaryText.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isError) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: TeacherColors.dangerAccent.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load queries',
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      TeacherColors.primaryAccent.withOpacity(0.7),
                      TeacherColors.primaryAccent.withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TeacherColors.primaryAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _fetchQueries,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        'Retry',
                        style: TeacherTextStyles.primaryButton.copyWith(
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (queries.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 48,
                color: TeacherColors.primaryText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No queries yet',
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  color: TeacherColors.primaryText.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        backgroundColor: TeacherColors.primaryBackground,
        color: subjectColor,
        displacement: 40,
        edgeOffset: 20,
        onRefresh: _fetchQueries,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: queries.length,
          itemBuilder: (context, index) => AnimatedQueryCard(
            query: queries[index],
            subjectColor: subjectColor,
            onRespond: _showResponseDialog,
            animation: _fadeAnimation,
            index: index,
          ),
        ),
      ),
    );
  }
}

class AnimatedQueryCard extends StatelessWidget {
  final Map<String, dynamic> query;
  final Color subjectColor;
  final Function(Map<String, dynamic>) onRespond;
  final Animation<double> animation;
  final int index;

  const AnimatedQueryCard({
    super.key,
    required this.query,
    required this.subjectColor,
    required this.onRespond,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = query['status'] == 'pending';
    final date = DateFormat('MMM d, h:mm a').format(
      DateTime.parse(query['created_at']).toLocal(),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(
            0.1 * index,
            1.0,
            curve: Curves.easeOutQuart,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: TeacherColors.secondaryBackground.withOpacity(0.6),
            border: Border.all(
              color: subjectColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPending
                                ? [
                              TeacherColors.warningAccent.withOpacity(0.3),
                              TeacherColors.warningAccent.withOpacity(0.1),
                            ]
                                : [
                              TeacherColors.successAccent.withOpacity(0.3),
                              TeacherColors.successAccent.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPending
                                ? TeacherColors.warningAccent.withOpacity(0.5)
                                : TeacherColors.successAccent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isPending ? 'PENDING' : 'RESOLVED',
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: isPending
                                ? TeacherColors.warningAccent
                                : TeacherColors.successAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                subjectColor.withOpacity(0.3),
                                subjectColor.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: subjectColor.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                              style: TeacherTextStyles.listItemTitle.copyWith(
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              date,
                              style: TeacherTextStyles.cardSubtitle.copyWith(
                                color: TeacherColors.primaryText.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      query['question'],
                      style: TeacherTextStyles.listItemSubtitle.copyWith(
                        height: 1.4,
                      ),
                    ),
                    if (query['answer'] != null) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Response',
                            style: TeacherTextStyles.cardTitle.copyWith(
                              color: subjectColor.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TeacherColors.primaryBackground.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: subjectColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              query['answer'] ?? '',
                              style: TeacherTextStyles.listItemSubtitle.copyWith(
                                color: TeacherColors.primaryText.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                subjectColor.withOpacity(0.8),
                                subjectColor.withOpacity(0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onRespond(query),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.reply,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Respond Now',
                                      style: TeacherTextStyles.primaryButton.copyWith(
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}