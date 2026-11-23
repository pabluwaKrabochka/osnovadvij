import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OsnovaTheme {
  static const Color bgDark = Color(0xFF0B1D17);
  static const Color bgDeep = Color(0xFF07130F);
  static const Color surfaceCard = Color(0xFF132B23);
  static const Color surfaceElevated = Color(0xFF1A3A2F);
  static const Color gold = Color(0xFFD4B475);
  static const Color goldBright = Color(0xFFEBD096);
  static const Color creamText = Color(0xFFF4EFE6);
  static const Color sageMuted = Color(0xFF8FB8A8);
  static const Color liveGreen = Color(0xFF4ADE80);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEBD096), Color(0xFFD4B475), Color(0xFFB89452)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17352B), Color(0xFF10241D), Color(0xFF0C1C16)],
  );

  static const LinearGradient cardActiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF224B3D), Color(0xFF163329), Color(0xFF10251E)],
  );

  static ThemeData buildTheme() {
    final baseDark = ThemeData.dark(useMaterial3: true);
    final manropeTheme = GoogleFonts.manropeTextTheme(baseDark.textTheme).apply(
      bodyColor: creamText,
      displayColor: creamText,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      textTheme: manropeTheme.copyWith(
        titleLarge: GoogleFonts.montserrat(
          textStyle: manropeTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: creamText,
        ),
        titleMedium: GoogleFonts.montserrat(
          textStyle: manropeTheme.titleMedium,
          fontWeight: FontWeight.w600,
          color: creamText,
        ),
        labelLarge: GoogleFonts.montserrat(
          textStyle: manropeTheme.labelLarge,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: bgDark,
        secondary: sageMuted,
        surface: surfaceCard,
        onSurface: creamText,
        primaryContainer: surfaceElevated,
        onPrimaryContainer: goldBright,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: creamText,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: creamText,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: gold.withValues(alpha: 0.35)),
        ),
      ),
      useMaterial3: true,
    );
  }

  static IconData iconForCategory(String category, String name) {
    final lower = name.toLowerCase();
    if (lower.contains('playstation') || lower.contains('ps5')) {
      return Icons.sports_esports_rounded;
    }
    if (lower.contains('мафія')) return Icons.masks_rounded;
    if (lower.contains('квіз')) return Icons.psychology_alt_rounded;
    if (lower.contains('настільні')) return Icons.extension_rounded;
    if (lower.contains('літературний')) return Icons.auto_stories_rounded;
    if (lower.contains('психологічна')) return Icons.spa_rounded;
    if (lower.contains('народження') || lower.contains('корпоратив')) {
      return Icons.celebration_rounded;
    }
    if (lower.contains('чай') || lower.contains('матча')) {
      return Icons.emoji_food_beverage_rounded;
    }
    if (lower.contains('тост') || lower.contains('сендвіч')) {
      return Icons.lunch_dining_rounded;
    }
    if (lower.contains('тонік') ||
        lower.contains('ice') ||
        lower.contains('айс') ||
        lower.contains('оранж') ||
        lower.contains('лимонад')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('еклер') ||
        lower.contains('спартак') ||
        lower.contains('горішки') ||
        lower.contains('кекс') ||
        lower.contains('торт')) {
      return Icons.cake_rounded;
    }
    if (lower.contains('сироп') || lower.contains('молоко')) {
      return Icons.water_drop_rounded;
    }

    switch (category) {
      case 'Основне меню':
        return Icons.coffee_maker_rounded;
      case 'Холодні напої':
        return Icons.local_bar_rounded;
      case 'Смаколики':
        return Icons.bakery_dining_rounded;
      case 'Додатки':
        return Icons.auto_awesome_rounded;
      case 'Послуги':
        return Icons.stars_rounded;
      default:
        return Icons.local_cafe_rounded;
    }
  }
}