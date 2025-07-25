import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color primaryBackground = Color(0xFF1A1A2E); // Matches TeacherColors.primaryBackground
  static const Color secondaryBackground = Color(0xFF16213E); // Matches TeacherColors.secondaryBackground
  static const Color surface = Color(0x15FFFFFF); // Transparent white like cardBackground
  static const Color cardBackground = Color(0x15FFFFFF); // Matches TeacherColors.cardBackground
  static const Color cardBorder = Color(0x25FFFFFF); // Matches TeacherColors.cardBorder

  // Accent colors
  static const Color primary = Color(0xFF00D1D1); // Matches TeacherColors.primaryAccent
  static const Color primaryLight = Color(0xFF4CC9F0); // Matches TeacherColors.secondaryAccent
  static const Color primaryDark = Color(0xFF00A895); // Fallback match
  static const Color secondary = Color(0xFF4CC9F0); // Matches TeacherColors.secondaryAccent
  static const Color secondaryLight = Color(0xFF60A5FA); // Matches TeacherColors.studentColor
  static const Color secondaryDark = Color(0xFF00A895); // Close to secondaryAccent darker tone

  // Status colors
  static const Color success = Color(0xFF4ADE80); // Matches TeacherColors.successAccent
  static const Color warning = Color(0xFFF97316); // Matches TeacherColors.warningAccent
  static const Color error = Color(0xFFEF4444); // Matches TeacherColors.dangerAccent
  static const Color info = Color(0xFFA855F7); // Matches TeacherColors.infoAccent

  // Text colors
  static const Color textPrimary = Colors.white; // Matches TeacherColors.primaryText
  static const Color textSecondary = Color(0xFF94A3B8); // Matches TeacherColors.secondaryText
  static const Color disabledText = Color(0xFF64748B); // Matches TeacherColors.disabledText

  // Glass morphism effects
  static Color glassEffectLight = Colors.white.withOpacity(0.1); // Matches TeacherColors.glassEffectLight
  static Color glassEffectDark = Colors.white.withOpacity(0.05); // Matches TeacherColors.glassEffectDark

  // Section specific colors - Updated to match TeacherColors values
  static const Color studentColor = Color(0xFF60A5FA); // Blue-400
  static const Color facultyColor = Color(0xFFA855F7); // Purple-500
  static const Color attendanceColor = Color(0xFF4ADE80); // Green-400
  static const Color fineColor = Color(0xFFEF4444); // Red
  static const Color resultsColor = Color(0xFFF59E0B); // Amber-500

  // Other accent sets (unchanged)
  static const accentPinkLight = Color(0xFFFFB6C1); // Optional set
  static const accentPink = Color(0xFFFF69B4);      // Optional set
  static const accentBlueLight = Color(0xFFADD8E6);
  static const accentBlue = Color(0xFF1E90FF);
  static const accentAmberLight = Color(0xFFFFECB3);
  static const accentAmber = Color(0xFFFFC107);
  static const successLight = Color(0xFFC8E6C9);

  // Gradient helper (unchanged)
  static LinearGradient accentGradient(Color color) {
    return LinearGradient(
      colors: [
        color.withOpacity(0.4), // Matches TeacherColors.accentGradient
        color.withOpacity(0.2),
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