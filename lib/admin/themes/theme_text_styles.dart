// theme_text_styles.dart
import 'package:flutter/material.dart';
import 'theme_colors.dart';

class AdminTextStyles {
  // Dashboard header styles
  static const TextStyle portalTitle = TextStyle(
    color: AdminColors.secondaryText,
    fontSize: 14,
    letterSpacing: 1.5,
  );

  static const TextStyle campusName = TextStyle(
    color: AdminColors.primaryText,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  // Section header styles
  static TextStyle sectionHeader = const TextStyle(
    color: AdminColors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Button styles
  static const TextStyle primaryButton = TextStyle(
    color: AdminColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle secondaryButton = TextStyle(
    color: AdminColors.primaryText.withOpacity(0.8),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Card styles
  static const TextStyle cardTitle = TextStyle(
    color: AdminColors.primaryText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AdminColors.secondaryText,
    fontSize: 10,
  );

  // Stats styles
  static const TextStyle statValue = TextStyle(
    color: AdminColors.primaryAccent,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statLabel = TextStyle(
    color: AdminColors.secondaryText,
    fontSize: 10,
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
}