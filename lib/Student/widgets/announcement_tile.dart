import 'package:flutter/material.dart';

import '../utils/theme.dart';

class AnnouncementTile extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final bool isRead;
  final Color color;

  const AnnouncementTile({
    super.key,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: isRead
                        ? textTheme.bodyMedium
                        : textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}