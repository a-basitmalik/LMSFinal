import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SyllabusButton extends StatelessWidget {
  final String subjectName;
  final VoidCallback onPressed;

  const SyllabusButton({
    super.key,
    required this.subjectName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: AppTheme.defaultPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              subjectName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.picture_as_pdf,
            color: AppColors.error, // Using error color for PDF icon for consistency
          ),
        ],
      ),
    );
  }
}