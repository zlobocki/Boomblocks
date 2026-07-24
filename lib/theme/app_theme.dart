import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft casual cartoon palette — warm earth + sky, not purple/cream defaults.
class BoomColors {
  static const skyTop = Color(0xFF7EC8E3);
  static const skyBottom = Color(0xFFB8E0D2);
  static const earth = Color(0xFFC4A484);
  static const earthDark = Color(0xFF8B6914);
  static const rock = Color(0xFF9A8C7A);
  static const boardBg = Color(0xFFE8D5B7);
  static const boardLine = Color(0xFFD4B896);
  static const hud = Color(0xFFFFF6E8);
  static const ink = Color(0xFF3D2C1E);
  static const accent = Color(0xFFE07A3D);
  static const accentDeep = Color(0xFFC45C26);
  static const success = Color(0xFF5CAD6E);
  static const danger = Color(0xFFE85D5D);
  static const rope = Color(0xFFD4A017);
  static const dynamite = Color(0xFFE24A3B);
  static const tray = Color(0xFFFFF9F0);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BoomColors.accent,
        brightness: Brightness.light,
        primary: BoomColors.accentDeep,
        secondary: BoomColors.success,
        surface: BoomColors.hud,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: BoomColors.ink,
        displayColor: BoomColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: BoomColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BoomColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
