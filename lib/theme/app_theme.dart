import 'package:flutter/material.dart';

/// Детская тема приложения: яркая палитра, крупные скруглённые элементы,
/// большие шрифты — удобно для детей 7–9 лет.
class AppTheme {
  AppTheme._();

  // Базовая палитра.
  static const Color purple = Color(0xFF6C5CE7);
  static const Color orange = Color(0xFFFF9F43);
  static const Color teal = Color(0xFF00B894);
  static const Color pink = Color(0xFFE84393);
  static const Color sky = Color(0xFF0984E3);
  static const Color yellow = Color(0xFFFDCB6E);
  static const Color cream = Color(0xFFFFF8EE);
  static const Color ink = Color(0xFF2D3436);

  /// Цвет игры по её идентификатору.
  static const Map<String, Color> gameColors = {
    'maze': purple,
    'stars': teal,
    'pattern': orange,
    'odd': pink,
    'steps': sky,
    'blocks': Color(0xFF8E44AD),
    'pixel': Color(0xFFE91E63),
    'python': Color(0xFF3776AB),
    // Новые игры: отладка и шифры.
    'bug': Color(0xFF2DBE60),
    'code': Color(0xFF3742FA),
    // Музыка и логика (Контент-3)
    'melody': Color(0xFF7D5FFF),
    'memory': Color(0xFF7E57C2),
    'hanoi': Color(0xFF42A5F5),
    'robot': Color(0xFFFFB300),
    // Системное мышление.
    'parts': Color(0xFF00A8A8),
    'causes': Color(0xFFB84CE3),
    'rules': Color(0xFFE17055),
  };

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    ).copyWith(
      primary: purple,
      secondary: orange,
      tertiary: teal,
      surface: cream,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
