import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OsnovaThemeId {
  emeraldGold,
  cyberNeon,
  velvetMafia,
  midnightAmethyst,
}

class OsnovaPalette {
  final OsnovaThemeId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isNeon;
  final Color bgDark;
  final Color bgDeep;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color gold;
  final Color goldBright;
  final Color creamText;
  final Color sageMuted;
  final Color liveGreen;
  final Color neonGlow;
  final List<Color> primaryGradientColors;
  final List<Color> cardGradientColors;
  final List<Color> cardActiveGradientColors;

  const OsnovaPalette({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isNeon,
    required this.bgDark,
    required this.bgDeep,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.gold,
    required this.goldBright,
    required this.creamText,
    required this.sageMuted,
    required this.liveGreen,
    required this.neonGlow,
    required this.primaryGradientColors,
    required this.cardGradientColors,
    required this.cardActiveGradientColors,
  });
}

class OsnovaTheme {
  static const String _prefsKey = 'osnova_selected_theme_id';

  static final ValueNotifier<OsnovaThemeId> themeNotifier =
      ValueNotifier<OsnovaThemeId>(OsnovaThemeId.emeraldGold);

  static const Map<OsnovaThemeId, OsnovaPalette> palettes = {
    OsnovaThemeId.emeraldGold: OsnovaPalette(
      id: OsnovaThemeId.emeraldGold,
      title: 'Смарагд і Золото',
      subtitle: 'Фірмова класика OSNOVA',
      icon: Icons.auto_awesome_rounded,
      isNeon: false,
      bgDark: Color(0xFF0B1D17),
      bgDeep: Color(0xFF07130F),
      surfaceCard: Color(0xFF132B23),
      surfaceElevated: Color(0xFF1A3A2F),
      gold: Color(0xFFD4B475),
      goldBright: Color(0xFFEBD096),
      creamText: Color(0xFFF4EFE6),
      sageMuted: Color(0xFF8FB8A8),
      liveGreen: Color(0xFF4ADE80),
      neonGlow: Color(0xFFD4B475),
      primaryGradientColors: [
        Color(0xFFEBD096),
        Color(0xFFD4B475),
        Color(0xFFB89452),
      ],
      cardGradientColors: [
        Color(0xFF17352B),
        Color(0xFF10241D),
        Color(0xFF0C1C16),
      ],
      cardActiveGradientColors: [
        Color(0xFF224B3D),
        Color(0xFF163329),
        Color(0xFF10251E),
      ],
    ),
    OsnovaThemeId.cyberNeon: OsnovaPalette(
      id: OsnovaThemeId.cyberNeon,
      title: 'Нічний Неон',
      subtitle: 'Зелене неонове світіння рамок',
      icon: Icons.bolt_rounded,
      isNeon: true,
      bgDark: Color(0xFF040B08),
      bgDeep: Color(0xFF020604),
      surfaceCard: Color(0xFF081812),
      surfaceElevated: Color(0xFF0E291F),
      gold: Color(0xFF00E676),
      goldBright: Color(0xFF69F0AE),
      creamText: Color(0xFFEBFFF5),
      sageMuted: Color(0xFF6EE7B7),
      liveGreen: Color(0xFF00FF88),
      neonGlow: Color(0xFF00FF88),
      primaryGradientColors: [
        Color(0xFF69F0AE),
        Color(0xFF00E676),
        Color(0xFF00B85C),
      ],
      cardGradientColors: [
        Color(0xFF0B2219),
        Color(0xFF06150F),
        Color(0xFF040E0A),
      ],
      cardActiveGradientColors: [
        Color(0xFF113829),
        Color(0xFF0A241A),
        Color(0xFF061711),
      ],
    ),
    OsnovaThemeId.velvetMafia: OsnovaPalette(
      id: OsnovaThemeId.velvetMafia,
      title: 'Вечірня Мафія',
      subtitle: 'Атмосфера турнірів та ночі',
      icon: Icons.masks_rounded,
      isNeon: true,
      bgDark: Color(0xFF12080B),
      bgDeep: Color(0xFF0A0406),
      surfaceCard: Color(0xFF1F0E14),
      surfaceElevated: Color(0xFF2E151E),
      gold: Color(0xFFF59E0B),
      goldBright: Color(0xFFFCD34D),
      creamText: Color(0xFFFAF3EE),
      sageMuted: Color(0xFFD6A8B4),
      liveGreen: Color(0xFF4ADE80),
      neonGlow: Color(0xFFFB7185),
      primaryGradientColors: [
        Color(0xFFFCD34D),
        Color(0xFFF59E0B),
        Color(0xFFD97706),
      ],
      cardGradientColors: [
        Color(0xFF281219),
        Color(0xFF190B10),
        Color(0xFF11070A),
      ],
      cardActiveGradientColors: [
        Color(0xFF3B1A24),
        Color(0xFF261017),
        Color(0xFF1A0B10),
      ],
    ),
    OsnovaThemeId.midnightAmethyst: OsnovaPalette(
      id: OsnovaThemeId.midnightAmethyst,
      title: 'Північний Аметист',
      subtitle: 'Лаунж та ігрова зона PS5',
      icon: Icons.nightlight_round,
      isNeon: true,
      bgDark: Color(0xFF0A0918),
      bgDeep: Color(0xFF05050E),
      surfaceCard: Color(0xFF14122B),
      surfaceElevated: Color(0xFF1E1B40),
      gold: Color(0xFFC084FC),
      goldBright: Color(0xFFE9D5FF),
      creamText: Color(0xFFF3F0FF),
      sageMuted: Color(0xFFA5B4FC),
      liveGreen: Color(0xFF34D399),
      neonGlow: Color(0xFFA855F7),
      primaryGradientColors: [
        Color(0xFFE9D5FF),
        Color(0xFFC084FC),
        Color(0xFF9333EA),
      ],
      cardGradientColors: [
        Color(0xFF1A1738),
        Color(0xFF110F26),
        Color(0xFF0B0A1A),
      ],
      cardActiveGradientColors: [
        Color(0xFF282354),
        Color(0xFF1A1638),
        Color(0xFF121029),
      ],
    ),
  };

  static OsnovaThemeId get currentTheme => themeNotifier.value;

  static OsnovaPalette get current =>
      palettes[themeNotifier.value] ?? palettes[OsnovaThemeId.emeraldGold]!;

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_prefsKey);
    if (savedName == null) return;
    final match = OsnovaThemeId.values
        .where((e) => e.name == savedName)
        .firstOrNull;
    if (match != null) {
      themeNotifier.value = match;
    }
  }

  static Future<void> setTheme(OsnovaThemeId id) async {
    if (themeNotifier.value == id) return;
    themeNotifier.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id.name);
  }

  // Динамічні геттери палітри — весь додаток автоматично підлаштовується під тему
  static bool get isNeon => current.isNeon;
  static Color get bgDark => current.bgDark;
  static Color get bgDeep => current.bgDeep;
  static Color get surfaceCard => current.surfaceCard;
  static Color get surfaceElevated => current.surfaceElevated;
  static Color get gold => current.gold;
  static Color get goldBright => current.goldBright;
  static Color get creamText => current.creamText;
  static Color get sageMuted => current.sageMuted;
  static Color get liveGreen => current.liveGreen;
  static Color get neonGlow => current.neonGlow;

  static LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: current.primaryGradientColors,
      );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: current.cardGradientColors,
      );

  static LinearGradient get cardActiveGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: current.cardActiveGradientColors,
      );

  static ThemeData buildTheme([OsnovaThemeId? themeId]) {
    final p = themeId != null ? palettes[themeId]! : current;
    final baseDark = ThemeData.dark(useMaterial3: true);
    final manropeTheme = GoogleFonts.manropeTextTheme(baseDark.textTheme).apply(
      bodyColor: p.creamText,
      displayColor: p.creamText,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: p.bgDark,
      textTheme: manropeTheme.copyWith(
        titleLarge: GoogleFonts.montserrat(
          textStyle: manropeTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: p.creamText,
        ),
        titleMedium: GoogleFonts.montserrat(
          textStyle: manropeTheme.titleMedium,
          fontWeight: FontWeight.w600,
          color: p.creamText,
        ),
        labelLarge: GoogleFonts.montserrat(
          textStyle: manropeTheme.labelLarge,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: p.gold,
        onPrimary: p.bgDark,
        secondary: p.sageMuted,
        surface: p.surfaceCard,
        onSurface: p.creamText,
        primaryContainer: p.surfaceElevated,
        onPrimaryContainer: p.goldBright,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bgDark,
        foregroundColor: p.creamText,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.creamText,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: (p.isNeon ? p.neonGlow : p.gold).withValues(alpha: 0.48),
            width: p.isNeon ? 1.4 : 1.0,
          ),
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