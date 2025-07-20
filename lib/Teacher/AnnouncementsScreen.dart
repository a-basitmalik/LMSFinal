import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
class AnnouncementScreen extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;

  const AnnouncementScreen({super.key, required this.announcements});

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
      body: ListView.separated(
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
                  // Title with NEW badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          announcement['title'],
                          style: TeacherTextStyles.assignmentTitle.copyWith(
                            color: TeacherColors.primaryText,
                          ),
                        ),
                      ),
                      if (announcement['isNew'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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

                  // Time with circle bullet
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
                        announcement['time'],
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          color: TeacherColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Content
                  Text(
                    announcement['content'],
                    style: TeacherTextStyles.listItemSubtitle.copyWith(
                      fontSize: 15,
                      color: TeacherColors.primaryText.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}