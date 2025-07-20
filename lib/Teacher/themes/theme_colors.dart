import 'package:flutter/material.dart';

class TeacherColors {
  // Background colors
  static const Color primaryBackground = Color(0xFF1A1A2E);
  static const Color secondaryBackground = Color(0xFF16213E);

  // Accent colors
  static const Color primaryAccent = Color(0xFF00D1D1); // Teal accent
  static const Color secondaryAccent = Color(0xFF4CC9F0); // Light blue accent
  static const Color successAccent = Color(0xFF4ADE80); // Green accent
  static const Color warningAccent = Color(0xFFF97316); // Orange accent
  static const Color dangerAccent = Color(0xFFEF4444); // Red accent
  static const Color infoAccent = Color(0xFFA855F7); // Purple accent

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF94A3B8);
  static const Color disabledText = Color(0xFF64748B);

  // Card colors
  static const Color cardBackground = Color(0x15FFFFFF);
  static const Color cardBorder = Color(0x25FFFFFF);

  // Section specific colors
  static const Color studentColor = Color(0xFF60A5FA); // Blue-400
  static const Color classColor = Color(0xFFA855F7); // Purple-500
  static const Color attendanceColor = Color(0xFF4ADE80); // Green-400
  static const Color assignmentColor = Color(0xFFF59E0B); // Amber-500
  static const Color gradeColor = Color(0xFFEC4899); // Pink-500
  static const Color scheduleColor = Color(0xFF3B82F6); // Blue-500
  static const Color announcementColor = Color(0xFF00D1D1); // Teal-400
  static const Color reportColor = Color(0xFFF97316); // Orange-500

  // Glass morphism effects
  static Color glassEffectLight = Colors.white.withOpacity(0.1);
  static Color glassEffectDark = Colors.white.withOpacity(0.05);

  // Gradient helpers
  static LinearGradient accentGradient(Color color) {
    return LinearGradient(
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static BoxDecoration glassDecoration({
    Color? borderColor,
    double borderRadius = 16,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? cardBorder,
        width: borderWidth,
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