import 'package:flutter/material.dart';
import '../utils/theme.dart'; // Make sure AppColors is correctly imported

class AttendanceProgressBar extends StatelessWidget {
  final int percentage;

  const AttendanceProgressBar({super.key, required this.percentage});

  // Function to pick bar color based on percentage
  Color getProgressColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final Color barColor = getProgressColor(percentage.toDouble());

    return Container(
      decoration: BoxDecoration(
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
        borderRadius: BorderRadius.circular(16),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentage / 100),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder:
              (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 12, // Thicker bar
                backgroundColor: AppColors.lightGrey,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
        ),
      ),
    );
  }
}
