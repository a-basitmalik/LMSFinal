import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color primaryBackground = Color(0xFF0A0A1A);
  static const Color secondaryBackground = Color(0xFF12122B);
  static const Color surface = Color(0x10FFFFFF);
  static const Color cardBackground = Color(0x10FFFFFF); // Matches admin
  static const Color cardBorder = Color(0x30FFFFFF); // Matches admin

  // Accent colors
  static const Color primary = Colors.cyanAccent; // Matches admin's primaryAccent
  static const Color primaryLight = Color(0xFF9E47FF);
  static const Color primaryDark = Color(0xFF0400BA);
  static const Color secondary = Colors.blueAccent; // Matches admin's secondaryAccent
  static const Color secondaryLight = Color(0xFF66FFF9);
  static const Color secondaryDark = Color(0xFF00A895);

  // Status colors
  static const Color success = Colors.greenAccent; // Matches admin's successAccent
  static const Color warning = Colors.orangeAccent; // Matches admin's warningAccent
  static const Color error = Colors.redAccent; // Matches admin's dangerAccent
  static const Color info = Colors.purpleAccent; // Matches admin's infoAccent

  // Text colors
  static const Color textPrimary = Colors.white; // Matches admin's primaryText
  static const Color textSecondary = Color(0xFFB0B0CC); // Matches admin's secondaryText
  static const Color disabledText = Color(0xFF666680); // Matches admin's disabledText

  // Glass morphism effects
  static Color glassEffectLight = Colors.white.withOpacity(0.1); // Matches admin
  static Color glassEffectDark = Colors.white.withOpacity(0.05); // Matches admin

  // Section specific colors - Matches admin exactly
  static const Color studentColor = Colors.blueAccent;
  static const Color facultyColor = Colors.purpleAccent;
  static const Color attendanceColor = Colors.greenAccent;
  static const Color fineColor = Colors.redAccent;
  static const Color resultsColor = Colors.orangeAccent;

  // Gradient helpers - Matches admin exactly
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

class AppTheme {
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const double defaultBorderRadius = 12.0;
  static const double defaultSpacing = 16.0;
  static const double defaultIconSize = 28.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.black,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.disabledText, fontSize: 12),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.disabledText,
          fontSize: 10,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.disabledText),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.black,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.disabledText, fontSize: 12),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.disabledText,
          fontSize: 10,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.disabledText),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
    );
  }
}

// Text styles extension - Updated to match admin exactly
extension CustomTextStyles on TextTheme {
  TextStyle? get portalTitle => labelMedium?.copyWith(
    letterSpacing: 1.5,
    color: AppColors.textSecondary, // Matches admin
    fontSize: 14, // Matches admin
  );

  TextStyle? get campusName => displayMedium?.copyWith(
    letterSpacing: 1.2,
    color: AppColors.textPrimary, // Matches admin
    fontSize: 22, // Matches admin
    fontWeight: FontWeight.bold, // Matches admin
  );

  TextStyle? get cardTitle => titleLarge?.copyWith(
    color: AppColors.textPrimary, // Matches admin
    fontSize: 12, // Matches admin
    fontWeight: FontWeight.w500, // Matches admin
  );

  TextStyle? get sectionHeader => headlineMedium?.copyWith(
    color: AppColors.textPrimary, // Matches admin
    fontSize: 16, // Matches admin
    fontWeight: FontWeight.w600, // Matches admin
    letterSpacing: 0.5, // Matches admin
  );

  TextStyle? get cardSubtitle => bodySmall?.copyWith(
    color: AppColors.textSecondary, // Matches admin
    fontSize: 10, // Matches admin
  );

  TextStyle? get statValue => bodyLarge?.copyWith(
    color: AppColors.primary, // Matches admin
    fontWeight: FontWeight.bold, // Matches admin
    fontSize: 16, // Matches admin
  );

  TextStyle? get statLabel => labelSmall?.copyWith(
    color: AppColors.textSecondary, // Matches admin
    fontSize: 10, // Matches admin
  );

  TextStyle accentText(Color color) {
    return bodyMedium!.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
      fontSize: 14, // Matches admin
    );
  }

  TextStyle sectionTitle(Color color) {
    return headlineMedium!.copyWith(
      color: color,
      fontSize: 16, // Matches admin
      fontWeight: FontWeight.w600, // Matches admin
      letterSpacing: 0.5, // Matches admin
    );
  }
}