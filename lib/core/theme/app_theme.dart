import 'package:flutter/material.dart';

class AppTheme {
  // Astra Color Tokens (From Figma Design)
  static const Color background = Color(0xFF07090D); // Obsidian Root
  static const Color obsidian = Color(0xFF0A0C10);   // Obsidian Surface
  static const Color surface = Color(0xFF10131A);    // Dark Slate
  static const Color surfaceCard = Color(0xFF131720);// Card Slate
  static const Color slateGlass = Color(0xFF171B25); // Elevated Glass
  static const Color borderSubtle = Color(0xFF242A36);// Subtle Border

  // Accents
  static const Color cyan = Color(0xFF00E5FF);       // Neon Cyan (Primary)
  static const Color primary = Color(0xFF00E5FF);     // Primary Brand
  static const Color indigo = Color(0xFF6366F1);     // Deep Indigo (Secondary)
  static const Color secondary = Color(0xFF6366F1);  // Secondary Accent

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status & Utility
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);

  // Glows & Shadows
  static List<BoxShadow> get cyanGlow => [
        BoxShadow(
          color: cyan.withOpacity(0.35),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.55),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: cyan,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: indigo,
        surface: surfaceCard,
        background: background,
        error: danger,
        onPrimary: Color(0xFF061014),
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slateGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
