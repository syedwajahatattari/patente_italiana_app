import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.failedRed,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
        titleMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.failedRed,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
        titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
        titleMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // Urdu Typography using Jameel Noori Nastaleeq
  static const String urduFontFamily = 'JameelNooriNastaleeq';

  static TextStyle urduStyle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.7,
  }) {
    return TextStyle(
      fontFamily: urduFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
