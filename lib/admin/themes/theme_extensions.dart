// theme_extensions.dart
import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_text_styles.dart';

extension AdminThemeExtensions on BuildContext {
  // Color shortcuts
  AdminColors get adminColors => AdminColors();

  // Text style shortcuts
  AdminTextStyles get adminTextStyles => AdminTextStyles();

  // Theme shortcuts
  ThemeData get adminTheme => Theme.of(this);

  // Media query shortcuts
  MediaQueryData get adminMedia => MediaQuery.of(this);
}

extension AdminColorExtensions on Color {
  // Method to get glass morphism decoration
  BoxDecoration toGlassDecoration({
    double borderRadius = 16,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: withOpacity(0.5),
        width: borderWidth,
      ),
      gradient: AdminColors.accentGradient(this),
    );
  }

  // Method to create circular icon container
  BoxDecoration toCircleDecoration({double size = 40}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: AdminColors.accentGradient(this),
      border: Border.all(
        color: withOpacity(0.5),
        width: 1.5,
      ),
    );
  }
}