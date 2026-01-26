import 'package:flutter/material.dart';

/// Application theme configuration
/// Uses a family-friendly color palette with green and blue tones
/// that feel welcoming and safe for kids content editing.
class AppTheme {
  AppTheme._();

  // Primary colors - Friendly green palette
  static const Color primaryColor = Color(0xFF4CAF50); // Material Green 500
  static const Color primaryVariant = Color(0xFF2E7D32); // Material Green 800
  static const Color primaryLight = Color(0xFF81C784); // Material Green 300

  // Secondary colors - Calming blue palette
  static const Color secondaryColor = Color(0xFF2196F3); // Material Blue 500
  static const Color secondaryVariant = Color(0xFF1976D2); // Material Blue 700
  static const Color secondaryLight = Color(0xFF64B5F6); // Material Blue 300

  // Accent colors - Warm and inviting
  static const Color accentColor = Color(0xFFFFB74D); // Warm orange
  static const Color accentLight = Color(0xFFFFE0B2); // Light peach

  // Status colors
  static const Color successColor = Color(0xFF66BB6A); // Friendly green
  static const Color warningColor = Color(0xFFFFB74D); // Warm orange
  static const Color errorColor = Color(0xFFE57373); // Softer red
  static const Color infoColor = Color(0xFF64B5F6); // Calming blue

  // Detection type colors - Distinct but not harsh
  static const Color profanityColor =
      Color(0xFFFF9800); // Orange (warning but not scary)
  static const Color nsfwColor = Color(0xFFE91E63); // Pink/Magenta (distinct)
  static const Color nudityColor =
      Color(0xFFE91E63); // Pink/Magenta (same as NSFW)
  static const Color violenceColor = Color(0xFFEF5350); // Softer red
  static const Color bloodColor = Color(0xFFC62828); // Dark red
  static const Color weaponsColor =
      Color(0xFF78909C); // Gray/Steel (Blue Grey 400)

  /// Light theme - Family-friendly with green/blue palette
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
  }

  /// Dark theme - Family-friendly with green/blue palette
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryLight, // Lighter blue for dark theme visibility
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
  }

  /// Get color for detection type
  /// Returns family-friendly colors that are distinct but not harsh
  static Color getDetectionColor(String type) {
    switch (type.toLowerCase()) {
      case 'profanity':
        return profanityColor; // Orange - warning but not scary
      case 'nsfw':
        return nsfwColor; // Pink/Magenta - distinct
      case 'nudity':
        return nudityColor; // Pink/Magenta
      case 'violence':
        return violenceColor; // Softer red
      case 'blood':
        return bloodColor; // Dark red
      case 'weapons':
        return weaponsColor; // Gray/Steel
      default:
        return const Color(0xFF90A4AE); // Blue Grey 300 - neutral fallback
    }
  }

  /// Get a lighter variant of detection color for backgrounds
  static Color getDetectionColorLight(String type) {
    return getDetectionColor(type).withOpacity(0.2);
  }

  /// Get text color for detection badges (ensures accessibility)
  static Color getDetectionTextColor(String type) {
    // Use white text on darker backgrounds, dark text on lighter
    switch (type.toLowerCase()) {
      case 'blood':
      case 'violence':
        return Colors.white;
      default:
        return Colors.black87;
    }
  }
}
