import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Light Luxury Theme Tokens (Whitish porcelain background & high contrast)
  static const Color scaffoldLight = Color(0xFFF8F9FA); // Warm porcelain white
  static const Color surfaceLight = Color(0xFFFFFFFF);  // Pure crisp card white
  static const Color surfaceMuted = Color(0xFFF1F5F9);  // Subtle soft grey container
  static const Color borderLight = Color(0xFFE2E8F0);   // Crisp soft border
  static const Color borderSubtle = Color(0xFFEDF2F7);  // Hairline divider

  // High-Contrast Typography
  static const Color textDark = Color(0xFF0F172A);      // Slate 900 - Deep charcoal
  static const Color textMedium = Color(0xFF334155);    // Slate 700 - Balanced body
  static const Color textMuted = Color(0xFF64748B);     // Slate 500 - Captions
  static const Color textSubtle = Color(0xFF94A3B8);    // Slate 400 - Tertiary

  // Vibrant, Elegant Accents with High Contrast
  static const Color primaryEmerald = Color(0xFF059669); // High-contrast emerald (AAA accessible)
  static const Color emeraldBg = Color(0xFFECFDF5);     // Soft emerald tint
  static const Color accentAmber = Color(0xFFD97706);   // High-contrast warm gold/amber
  static const Color amberBg = Color(0xFFFFFBEB);       // Soft amber tint
  static const Color royalBlue = Color(0xFF2563EB);     // Royal Blue
  static const Color blueBg = Color(0xFFEFF6FF);        // Soft blue tint
  static const Color alertRed = Color(0xFFDC2626);      // High-contrast ruby red
  static const Color redBg = Color(0xFFFEF2F2);         // Soft red tint
  static const Color purple = Color(0xFF7C3AED);        // Deep violet
  static const Color purpleBg = Color(0xFFF5F3FF);      // Soft violet tint

  static const Color darkPill = Color(0xFF0F172A);      // Obsidian action buttons / high contrast elements

  // Status Colors
  static const Color confirmed = Color(0xFF059669);
  static const Color pending = Color(0xFFD97706);
  static const Color rejected = Color(0xFFDC2626);
  static const Color cancelled = Color(0xFF64748B);

  // Surface Colors for Backward Compatibility
  static const Color surfaceDark = Color(0xFFF8F9FA);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color cardDarkElevated = Color(0xFFF8FAFC);

  // Text Colors for Backward Compatibility
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: scaffoldLight,
      colorScheme: const ColorScheme.light(
        primary: primaryEmerald,
        secondary: accentAmber,
        surface: surfaceLight,
        error: alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPill,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryEmerald,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textMedium),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSubtle),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textMedium,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkPill,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
