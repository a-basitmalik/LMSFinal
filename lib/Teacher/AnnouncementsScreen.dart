import 'package:flutter/material.dart';

import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';

class AnnouncementScreen extends StatefulWidget {
  final int subjectId;

  const AnnouncementScreen({super.key, required this.subjectId});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaticAnnouncements();
  }

  void _loadStaticAnnouncements() {
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        announcements = [
          {
            'title': 'Midterm Exam Schedule',
            'content': 'Midterm exams will start from Oct 10. Check the PDF for details.',
            'time': 'Oct 1, 2025 – 10:00 AM',
            'isNew': true,
            'attachments': [
              {'name': 'Midterm_Schedule.pdf'},
            ],
          },
          {
            'title': 'Assignment Submission Reminder',
            'content': 'Don\'t forget to submit Assignment 3 by Friday.',
            'time': 'Sep 28, 2025 – 4:00 PM',
            'isNew': false,
            'attachments': [],
          },
          {
            'title': 'Lecture Cancelled',
            'content': 'Tomorrow\'s lecture is cancelled due to maintenance work.',
            'time': 'Sep 25, 2025 – 8:00 AM',
            'isNew': false,
          },
        ];
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'All Announcements',
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final announcement = announcements[index];

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
                /// Title with optional "NEW" badge
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
                          return Chip(
                            backgroundColor: TeacherColors.infoAccent.withOpacity(0.2),
                            label: Text(
                              attachment['name'] ?? 'Attachment',
                              style: TeacherTextStyles.cardSubtitle.copyWith(
                                color: TeacherColors.infoAccent,
                              ),
                            ),
                            avatar: const Icon(Icons.attach_file, size: 18),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
