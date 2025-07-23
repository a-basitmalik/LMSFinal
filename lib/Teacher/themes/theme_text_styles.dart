import 'package:flutter/material.dart';
import 'theme_colors.dart';

class TeacherTextStyles {
  // Dashboard header styles
  static const TextStyle portalTitle = TextStyle(
    color: TeacherColors.secondaryText,
    fontSize: 14,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle headerTitle = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );

  static const TextStyle className = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );

  // Section header styles
  static TextStyle sectionHeader = const TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Button styles
  static const TextStyle primaryButton = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle secondaryButton = TextStyle(
    color: TeacherColors.primaryText.withOpacity(0.8),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Card styles
  static const TextStyle cardTitle = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: TeacherColors.secondaryText,
    fontSize: 12,
  );

  // Stats styles
  static const TextStyle statValue = TextStyle(
    color: TeacherColors.primaryAccent,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statLabel = TextStyle(
    color: TeacherColors.secondaryText,
    fontSize: 12,
  );

  // List item styles
  static const TextStyle listItemTitle = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle listItemSubtitle = TextStyle(
    color: TeacherColors.secondaryText,
    fontSize: 12,
  );

  // Helper methods for dynamic colors
  static TextStyle accentText(Color color) {
    return TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle sectionTitle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  // Assignment specific styles
  static const TextStyle assignmentTitle = TextStyle(
    color: TeacherColors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle assignmentDueDate = TextStyle(
    color: TeacherColors.warningAccent,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}