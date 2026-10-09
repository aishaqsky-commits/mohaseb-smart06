import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ColorTokens.background,
      colorScheme: const ColorScheme.light(
        primary: ColorTokens.neutralInfo,
        surface: ColorTokens.surface,
        error: ColorTokens.negative,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.normal),
      ),
    );
  }
}
