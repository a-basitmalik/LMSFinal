import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_text_styles.dart';

extension TeacherThemeExtensions on BuildContext {
  // Color shortcuts
  TeacherColors get teacherColors => TeacherColors();

  // Text style shortcuts
  TeacherTextStyles get teacherTextStyles => TeacherTextStyles();

  // Theme shortcuts
  ThemeData get teacherTheme => Theme.of(this);

  // Media query shortcuts
  MediaQueryData get teacherMedia => MediaQuery.of(this);
}

extension TeacherColorExtensions on Color {
  // Method to get glass morphism decoration
  BoxDecoration toGlassDecoration({
    double borderRadius = 16,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: withOpacity(0.5),
        width: borderWidth,
      ),
      gradient: TeacherColors.accentGradient(this),
    );
  }

  // Method to create circular icon container
  BoxDecoration toCircleDecoration({double size = 40}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: TeacherColors.accentGradient(this),
      border: Border.all(
        color: withOpacity(0.5),
        width: 1.0,
      ),
    );
  }
}