import 'package:flutter/material.dart';
import '../utils/app_design_system.dart';
import '../utils/theme.dart';

class AssessmentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const AssessmentCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: () => _navigateToAssessmentDetails(context, title),
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppTheme.defaultPadding,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.cardTitle?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
                    ),
                  ),
                  onPressed: () => _navigateToAssessmentDetails(context, title),
                  child: Text(
                    'View Details',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAssessmentDetails(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Viewing details for $title',
          style: Theme.of(context).textTheme.bodyMedium,

        ),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}