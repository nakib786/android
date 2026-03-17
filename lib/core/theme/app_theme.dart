import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colours.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColours.canadianRed,
        onPrimary: AppColours.white,
        secondary: AppColours.charcoal,
        surface: AppColours.white,
        onSurface: AppColours.charcoal,
        error: Colors.red,
      ),
      scaffoldBackgroundColor: AppColours.lightGrey,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(color: AppColours.charcoal, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.plusJakartaSans(color: AppColours.charcoal),
        bodyMedium: GoogleFonts.plusJakartaSans(color: AppColours.charcoal.withOpacity(0.8)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.canadianRed,
        foregroundColor: AppColours.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColours.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.canadianRed,
          foregroundColor: AppColours.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColours.canadianRed,
        onPrimary: AppColours.white,
        secondary: AppColours.lightGrey,
        surface: Color(0xFF1E1E1E),
        onSurface: AppColours.white,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: AppColours.charcoal,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(color: AppColours.white, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.plusJakartaSans(color: AppColours.white),
        bodyMedium: GoogleFonts.plusJakartaSans(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.charcoal,
        foregroundColor: AppColours.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.canadianRed,
          foregroundColor: AppColours.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
