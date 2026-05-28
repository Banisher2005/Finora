import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark Mode
  static const darkBackground = Color(0xFF0F0F12);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkCardElevated = Color(0xFF3A3A3C);

  // Light Mode
  static const lightBackground = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);

  // Accent
  static const incomeGreen = Color(0xFF34C759);
  static const incomeGreenDark = Color(0xFF28A745);
  static const expenseRed = Color(0xFFFF6B6B);
  static const expenseOrange = Color(0xFFFF9F43);
  static const savingsBlue = Color(0xFF0A84FF);
  static const accentBlue = Color(0xFF0A84FF);
  static const accentPurple = Color(0xFF5E5CE6);

  // Gradient starts/ends
  static const gradientDarkStart = Color(0xFF1A2744);
  static const gradientDarkEnd = Color(0xFF0A1628);
  static const gradientLightStart = Color(0xFF4A90D9);
  static const gradientLightEnd = Color(0xFF357ABD);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF48484A);

  // Category colors
  static const List<Color> categoryColors = [
    Color(0xFF0A84FF),
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
    Color(0xFFFF375F),
    Color(0xFF5E5CE6),
    Color(0xFF32ADE6),
    Color(0xFFFF6961),
    Color(0xFF30D158),
    Color(0xFFFFD60A),
    Color(0xFFBF5AF2),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentPurple,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.accentBlue.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentPurple,
        surface: AppColors.lightSurface,
        onSurface: const Color(0xFF1C1C1E),
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1C1C1E),
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1C1C1E),
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1C1C1E),
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1C1E),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accentBlue.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1C1C1E),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      ),
    );
  }
}
