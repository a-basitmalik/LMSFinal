import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Class Schedule',
          style: textTheme.titleLarge,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  // This would come from your data source in a real app
                  final days = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                  ];
                  final day = days[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: AppColors.cardBackground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.cardBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildClassItem(
                                  context,
                                  time: '08:00 - 09:00',
                                  subject: 'Mathematics',
                                  room: 'B-12',
                                  color: AppColors.primary,
                                ),
                                const Divider(
                                  height: 16,
                                  thickness: 1,
                                  color: AppColors.cardBorder,
                                ),
                                _buildClassItem(
                                  context,
                                  time: '09:00 - 10:00',
                                  subject: 'Physics',
                                  room: 'Lab-2',
                                  color: AppColors.secondary,
                                ),
                                const Divider(
                                  height: 16,
                                  thickness: 1,
                                  color: AppColors.cardBorder,
                                ),
                                _buildClassItem(
                                  context,
                                  time: '10:30 - 11:30',
                                  subject: 'Chemistry',
                                  room: 'B-14',
                                  color: AppColors.info,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: 5, // 5 days
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem(
      BuildContext context, {
        required String time,
        required String subject,
        required String room,
        required Color color,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  subject,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              room,
              style: textTheme.bodyMedium?.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}