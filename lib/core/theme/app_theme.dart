import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colours.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColours.canadianRed,
        onPrimary: AppColours.white,
        secondary: AppColours.charcoal,
        surface: AppColours.white,
        onSurface: AppColours.charcoal,
        error: Colors.red,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.canadianRed,
        foregroundColor: AppColours.white,
        elevation: 0,
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
      colorScheme: const ColorScheme.dark(
        primary: AppColours.canadianRed,
        onPrimary: AppColours.white,
        secondary: AppColours.lightGrey,
        surface: AppColours.charcoal,
        onSurface: AppColours.white,
        error: Colors.redAccent,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.charcoal,
        foregroundColor: AppColours.white,
        elevation: 0,
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
