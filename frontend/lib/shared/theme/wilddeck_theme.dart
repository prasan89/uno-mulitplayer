import 'package:flutter/material.dart';

/// WildDeck Design System — brand colors, gradients, typography, component styles.
/// Original visual identity: deep navy background, vibrant card colors, bold game aesthetic.
/// DO NOT reference any third-party card game branding in the visual identity.
class WildDeckTheme {
  // ─── Brand Colors ────────────────────────────────────────────────────────────
  static const Color navyDeep     = Color(0xFF0B0E1A);
  static const Color navyMid      = Color(0xFF141829);
  static const Color navySurface  = Color(0xFF1C2235);
  static const Color navyCard     = Color(0xFF222840);
  static const Color navyBorder   = Color(0xFF2E3550);

  // Card colors — vibrant, original palette
  static const Color cardRed      = Color(0xFFFF3B5C);
  static const Color cardBlue     = Color(0xFF2979FF);
  static const Color cardGreen    = Color(0xFF00C853);
  static const Color cardYellow   = Color(0xFFFFD600);
  static const Color cardWild     = Color(0xFF7C4DFF);

  // Accent / UI
  static const Color gold         = Color(0xFFFFB300);
  static const Color goldLight    = Color(0xFFFFE082);
  static const Color platinum     = Color(0xFFB0BEC5);
  static const Color neonGlow     = Color(0xFF00E5FF);

  // Text
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecond   = Color(0xFFB0BEC5);
  static const Color textMuted    = Color(0xFF546E7A);
  static const Color textDisabled = Color(0xFF37474F);

  // Status
  static const Color success      = Color(0xFF00E676);
  static const Color warning      = Color(0xFFFFAB00);
  static const Color error        = Color(0xFFFF1744);
  static const Color info         = Color(0xFF00B0FF);

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDeep, navyMid],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F3C), Color(0xFF0D1020)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF3B5C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD600), Color(0xFFFF8F00)],
  );

  static LinearGradient cardGradient(Color baseColor) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(baseColor, Colors.white, 0.18)!,
      baseColor,
      Color.lerp(baseColor, Colors.black, 0.25)!,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static const LinearGradient wildGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardRed, cardBlue, cardGreen, cardYellow],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  // ─── Shadows ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow(Color color, {bool elevated = false}) => [
    BoxShadow(
      color: color.withOpacity(elevated ? 0.55 : 0.35),
      blurRadius: elevated ? 24 : 12,
      offset: Offset(0, elevated ? 10 : 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: elevated ? 12 : 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── Border Radius ───────────────────────────────────────────────────────────
  static const BorderRadius radiusSmall  = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radiusLarge  = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXL     = BorderRadius.all(Radius.circular(28));
  static const BorderRadius radiusCard   = BorderRadius.all(Radius.circular(12));

  // ─── Theme ───────────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: navyDeep,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: cardRed,
        onPrimary: Colors.white,
        secondary: gold,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.white,
        background: navyDeep,
        onBackground: textPrimary,
        surface: navySurface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDeep,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: _textTheme,
      cardTheme: CardTheme(
        color: navySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMedium,
          side: const BorderSide(color: navyBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: navyBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navySurface,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyMid,
        selectedItemColor: gold,
        unselectedItemColor: textMuted,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navySurface,
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: navyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: navyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: cardRed, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecond),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? gold : textMuted),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? gold.withOpacity(0.3)
                : navyBorder),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        thumbColor: gold,
        inactiveTrackColor: navyBorder,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -1),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w800, color: textPrimary),
    displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.5),
    headlineMedium:TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
    titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecond),
    bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 1),
    labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecond, letterSpacing: 0.8),
    labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.2),
  );

  // ─── Color helpers ────────────────────────────────────────────────────────────
  static Color colorForCardColor(WildCardColor c) {
    switch (c) {
      case WildCardColor.red:    return cardRed;
      case WildCardColor.blue:   return cardBlue;
      case WildCardColor.green:  return cardGreen;
      case WildCardColor.yellow: return cardYellow;
      case WildCardColor.wild:   return cardWild;
    }
  }
}

/// WildDeck card color enum — original, not referencing any external IP.
enum WildCardColor { red, blue, green, yellow, wild }

/// WildDeck card type enum.
enum WildCardType {
  number,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour,
}
