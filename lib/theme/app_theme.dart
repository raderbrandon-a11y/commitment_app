import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF161526);
  static const Color coral = Color(0xFFF28891);
  static const Color gold = Color(0xFFF2B749);
  static const Color offWhite = Color(0xFFFCFBFC);

  /// App-wide light theme (used by `AppTheme.light` in app.dart)
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: offWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: Brightness.light,
      ).copyWith(
        primary: navy,
        secondary: coral,
        tertiary: gold,
        surface: offWhite,
      ),
    );

    return base.copyWith(
      // ✅ Global ElevatedButton styling
      // Fix iOS text clipping WITHOUT setting global textStyle here.
      // (Setting textStyle globally can unexpectedly override typography.)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size.fromHeight(52), // ✅ prevents iOS clipping
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ✅ Global FilledButton styling (Material 3)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          minimumSize: const Size.fromHeight(52), // ✅ prevents iOS clipping
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ✅ Global TextButton styling (e.g., History link)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: navy,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
