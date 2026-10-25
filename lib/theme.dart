import 'package:flutter/material.dart';

class KalasagTheme {
  static const primary = Color(0xFF1769D2),
      navy = Color(0xFF102A43),
      secondary = Color(0xFF0E8A92),
      warning = Color(0xFFE7A321),
      danger = Color(0xFFD64550),
      success = Color(0xFF218A61);
  static ThemeData dark() => _theme(
    Brightness.dark,
    const Color(0xFF071421),
    const Color(0xFF102335),
    const Color(0xFF5B9CFF),
  );
  static ThemeData light() => _theme(
    Brightness.light,
    const Color(0xFFF4F7FA),
    Colors.white,
    const Color(0xFF1769D2),
  );
  static ThemeData _theme(
    Brightness b,
    Color bg,
    Color surface,
    Color seed,
  ) => ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: b,
      surface: surface,
      error: danger,
    ),
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -.6,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
      ),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.42),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg,
      foregroundColor: b == Brightness.dark ? Colors.white : navy,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: b == Brightness.dark ? Colors.white : navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    scaffoldBackgroundColor: bg,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: seed.withValues(alpha: .18),
      height: 72,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: b == Brightness.dark
              ? const Color(0xFF284157)
              : const Color(0xFFE1E8EF),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: b == Brightness.dark
          ? const Color(0xFF172D40)
          : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: b == Brightness.dark
              ? const Color(0xFF2B455B)
              : const Color(0xFFDCE5EC),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: b == Brightness.dark
          ? const Color(0xFF2B455B)
          : const Color(0xFFE1E8EF),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
