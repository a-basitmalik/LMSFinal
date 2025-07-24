import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TimeTableCard extends StatelessWidget {
  final List<Map<String, String>> subjects;
  final String title;
  final String date;

  const TimeTableCard({
    super.key,
    required this.subjects,
    this.title = "Today's Timetable",
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: AppTheme.defaultPadding,
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
                Text(
                  title,
                  style: textTheme.cardTitle?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: textTheme.cardSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...subjects.map(
                  (subject) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        subject['time']!,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subject['subject']!,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      subject['room']!,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}