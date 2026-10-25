import 'package:flutter/material.dart';

class KalasagTheme {
  static const primary = Color(0xFF4B8FF7),
      secondary = Color(0xFF67C7E8),
      warning = Color(0xFFF4B740),
      danger = Color(0xFFF05A67),
      success = Color(0xFF42B978);
  static ThemeData dark() => _theme(
    Brightness.dark,
    const Color(0xFF0C1524),
    const Color(0xFF152235),
    primary,
  );
  static ThemeData light() => _theme(
    Brightness.light,
    const Color(0xFFF3F6FA),
    Colors.white,
    const Color(0xFF1769D2),
  );
  static ThemeData _theme(Brightness b, Color bg, Color surface, Color seed) =>
      ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: b,
          surface: surface,
          error: danger,
        ),
        scaffoldBackgroundColor: bg,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: seed.withValues(alpha: .18),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
