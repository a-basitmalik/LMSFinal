// theme_colors.dart
import 'package:flutter/material.dart';

class AdminColors {
  // Background colors
  static const Color primaryBackground = Color(0xFF0A0A1A);
  static const Color secondaryBackground = Color(0xFF12122B);

  // Accent colors
  static const Color primaryAccent = Colors.cyanAccent;
  static const Color secondaryAccent = Colors.blueAccent;
  static const Color successAccent = Colors.greenAccent;
  static const Color warningAccent = Colors.orangeAccent;
  static const Color dangerAccent = Colors.redAccent;
  static const Color infoAccent = Colors.purpleAccent;

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0CC);
  static const Color disabledText = Color(0xFF666680);

  // Card colors
  static const Color cardBackground = Color(0x10FFFFFF);
  static const Color cardBorder = Color(0x30FFFFFF);

  // Section specific colors
  static const Color studentColor = Colors.blueAccent;
  static const Color facultyColor = Colors.purpleAccent;
  static const Color attendanceColor = Colors.greenAccent;
  static const Color fineColor = Colors.redAccent;
  static const Color resultsColor = Colors.orangeAccent;
  static const Color plannerColor = Colors.orangeAccent;
  static const Color announcementColor = Colors.cyanAccent;
  static const Color curriculumColor = Colors.blueAccent;
  static const Color reportsColor = Colors.redAccent;

  // Glass morphism effects
  static Color glassEffectLight = Colors.white.withOpacity(0.1);
  static Color glassEffectDark = Colors.white.withOpacity(0.05);

  // Gradient helpers
  static LinearGradient accentGradient(Color color) {
    return LinearGradient(
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static BoxDecoration glassDecoration({
    Color? borderColor,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? cardBorder,
        width: 1.5,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [glassEffectLight, glassEffectDark],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }
}