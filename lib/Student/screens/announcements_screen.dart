import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../utils/theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  final List<Announcement> announcements = [
    Announcement(
      id: '1',
      title: 'Sports Day Postponed',
      message: 'The sports day event has been postponed to next week due to weather conditions. Please check the new schedule in the notice board.',
      date: DateTime.now(),
      author: 'Sports Committee',
    ),
    Announcement(
      id: '2',
      title: 'Science Fair Winners',
      message: 'Congratulations to all participants of the annual science fair. The winners will be announced in the assembly tomorrow.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      author: 'Science Department',
    ),
    // ... other announcements
  ];

  AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Announcements',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: ListView.builder(
        padding: AppTheme.defaultPadding,
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _buildAnnouncementCard(context, announcement, textTheme);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement announcement, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  announcement.timeAgo,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (announcement.author != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'By ${announcement.author}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.defaultSpacing),
            Text(
              announcement.message,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}