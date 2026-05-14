import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color dark = Color(0xFF1B1B1B);
  static const Color darkGray = Color(0xFF8E8E8E);
  static const Color lightGray = Color(0xFFDEDEDE);
  static const Color background = Color(0xFFF4F3F3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF0ED186);
  static const Color blue = Color(0xFF3422FF);
  static const Color pink = Color(0xFFF54EF0);
  static const Color orange = Color(0xFFFF8811);
  static const Color red = Color(0xFFEC4444);
  static const Color warmBrown = Color(0xFF8B4513);
  static const Color warmOrange = Color(0xFFCC6B3A);
}

class AppTheme {
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.0,
        color: AppColors.dark,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: AppColors.dark,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.dark,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.darkGray,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.darkGray,
      );

  static TextStyle get buttonText => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: AppColors.dark,
      );

  static TextStyle get logo => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      );

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.light(
          primary: AppColors.dark,
          secondary: AppColors.green,
          surface: AppColors.white,
          error: AppColors.red,
        ),
        textTheme: TextTheme(
          headlineLarge: headingLarge,
          headlineMedium: headingMedium,
          headlineSmall: headingSmall,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelSmall: caption,
        ),
        useMaterial3: true,
      );
}
