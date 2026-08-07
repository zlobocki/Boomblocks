import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark mine palette — charcoal stone, copper, lantern gold.
class BoomColors {
  static const skyTop = Color(0xFF1A140F);
  static const skyBottom = Color(0xFF0B0907);
  static const earth = Color(0xFF6B4A32);
  static const earthDark = Color(0xFF3A2618);
  static const rock = Color(0xFF5A4A3A);
  static const boardBg = Color(0xFF17120E);
  static const boardLine = Color(0xFF2A221C);
  static const hud = Color(0xFF1A140F);
  static const ink = Color(0xFFF2E6D8);
  static const cream = Color(0xFFF2E6D8);
  static const dust = Color(0xFFC4A574);
  static const accent = Color(0xFFC45C26);
  static const accentDeep = Color(0xFFE07A3D);
  static const success = Color(0xFF5CAD6E);
  static const danger = Color(0xFFE85D5D);
  static const rope = Color(0xFFD4A017);
  static const dynamite = Color(0xFFE24A3B);
  static const undo = Color(0xFF6BA3C7);
  static const tray = Color(0xFF1A140F);
  static const frameGold = Color(0xFFC9A227);
  static const gold = Color(0xFFE8C07A);
  static const copper = Color(0xFFC45C26);
  static const emerald = Color(0xFF3D9B6E);
}

class AppTheme {
  static const gold = BoomColors.gold;
  static const copper = BoomColors.copper;
  static const frameGold = BoomColors.frameGold;
  static const cream = BoomColors.cream;
  static const dust = BoomColors.dust;
  static const ink = BoomColors.ink;
  static const emerald = BoomColors.emerald;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BoomColors.accent,
        brightness: Brightness.dark,
        primary: BoomColors.accentDeep,
        secondary: BoomColors.success,
        surface: BoomColors.hud,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: BoomColors.skyBottom,
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
        iconTheme: const IconThemeData(color: BoomColors.ink),
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
      dialogTheme: DialogThemeData(
        backgroundColor: BoomColors.hud,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
