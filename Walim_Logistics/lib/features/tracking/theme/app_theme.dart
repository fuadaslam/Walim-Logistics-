import 'package:flutter/material.dart';

class AppTheme {
  // Walim Brand Palette (Refined for Dashboard)
  static const Color primary = Color(0xFFEA580C); // Deep Orange
  static const Color primaryDark = Color(0xFF9A3412);
  static const Color primaryLight = Color(0xFFFDBA74);
  
  static const Color sidebarBg = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color textBody = Color(0xFF64748B);
  static const Color textHeading = Color(0xFF0F172A);

  // Status Colors (Logistics Standard)
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444);  // Rose
  static const Color info = Color(0xFF3B82F6);    // Blue

  static const Color onlineColor = success;
  static const Color idleColor = warning;
  static const Color offlineColor = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFC2410C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      secondary: textHeading,
      surface: background,
      onSurface: textHeading,
    ),
    scaffoldBackgroundColor: background,
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textHeading,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textHeading,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textHeading, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textHeading, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textHeading),
      bodyLarge: TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 13, color: textBody),
      labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textBody, letterSpacing: 0.5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: Color(0xFFFED7AA), // Light orange
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: Colors.white70,
      surface: const Color(0xFF0F172A),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    dividerTheme: const DividerThemeData(color: Colors.white10, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 13, color: Colors.white60),
      labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.5),
    ),
  );

  static Color statusColor(String status, {bool moving = false, bool ignition = false, DateTime? timestamp}) {
    switch (status) {
      case 'moving':
        return success;
      case 'idle':
        return warning;
      case 'stopped':
        return danger;
      case 'offline':
        if (timestamp != null) {
          final diff = DateTime.now().difference(timestamp);
          if (diff.inHours <= 48) return danger; // Show as stopped if recent
        }
        return offlineColor;
      default:
        // Fallback to moving/ignition if status is unknown
        if (moving) return success;
        if (ignition) return warning;
        return offlineColor;
    }
  }
}
