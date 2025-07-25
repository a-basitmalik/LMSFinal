import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';

class AnnouncementScreen extends StatefulWidget {
  final int subjectId;

  const AnnouncementScreen({super.key, required this.subjectId});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/student/api/subject/${widget.subjectId}/announcements'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          announcements = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load announcements: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Subject Announcements',
          style: TeacherTextStyles.sectionHeader.copyWith(
            fontSize: 20,
            color: TeacherColors.primaryText,
          ),
        ),
        backgroundColor: TeacherColors.secondaryBackground,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnnouncements,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAnnouncementModal(context),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage,
                style: TextStyle(color: TeacherColors.dangerAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAnnouncements,
              child: Text('Retry', style: TeacherTextStyles.primaryButton),
            ),
          ],
        ),
      );
    }

    if (announcements.isEmpty) {
      return Center(
        child: Text(
          'No announcements yet',
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: TeacherColors.secondaryText,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    return Container(
      decoration: TeacherColors.glassDecoration(
        borderRadius: 12,
        borderColor: TeacherColors.cardBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title with "NEW" badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement['title'] ?? 'No title',
                    style: TeacherTextStyles.assignmentTitle.copyWith(
                      color: TeacherColors.primaryText,
                    ),
                  ),
                ),
                if (announcement['isNew'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TeacherColors.dangerAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NEW',
                      style: TeacherTextStyles.secondaryButton.copyWith(
                        color: TeacherColors.primaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            /// Time with bullet
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: TeacherColors.secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  announcement['time'] ?? 'Unknown time',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Content
            Text(
              announcement['content'] ?? 'No content',
              style: TeacherTextStyles.listItemSubtitle.copyWith(
                fontSize: 15,
                color: TeacherColors.primaryText.withOpacity(0.9),
                height: 1.5,
              ),
            ),

            /// Attachments
            if (announcement['attachments'] != null &&
                (announcement['attachments'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Attachments:',
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (announcement['attachments'] as List).map<Widget>((attachment) {
                      return InkWell(
                        onTap: () {
                          // Handle attachment download/view
                          _openAttachment(attachment['file_url']);
                        },
                        child: Chip(
                          backgroundColor: TeacherColors.infoAccent.withOpacity(0.2),
                          label: Text(
                            attachment['name'] ?? 'Attachment',
                            style: TeacherTextStyles.cardSubtitle.copyWith(
                              color: TeacherColors.infoAccent,
                            ),
                          ),
                          avatar: const Icon(Icons.attach_file, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openAttachment(String fileUrl) {
    // Implement attachment opening logic
    // You might want to use url_launcher package
    print('Opening attachment: $fileUrl');
  }

  void _showAddAnnouncementModal(BuildContext context) {
    // Use the implementation from the previous answer
    // Make sure to pass widget.subjectId when creating the announcement
  }
}