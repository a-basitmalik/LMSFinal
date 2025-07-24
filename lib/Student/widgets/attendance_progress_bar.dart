import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AttendanceProgressBar extends StatelessWidget {
  final int percentage;
  final double height;
  final double borderRadius;

  const AttendanceProgressBar({
    super.key,
    required this.percentage,
    this.height = 12.0,
    this.borderRadius = 16.0,
  });

  Color getProgressColor(double percentage) {
    if (percentage >= 85) return AppColors.success;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color barColor = getProgressColor(percentage.toDouble());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: barColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentage / 100),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ),
    );
  }
}