import 'package:flutter/material.dart';

/// Application theme configuration
/// Uses a cheerful, family-friendly color palette inspired by popular kids apps
/// (YouTube Kids, PBS Kids, Disney+). Colors evoke safety, joy, and entertainment.
///
/// Color Psychology:
/// - Coral/Orange: Friendly, energizing, warm, inviting
/// - Teal/Cyan: Trustworthy, calming, playful
/// - Yellow: Cheerful, happy, optimistic
/// - Purple: Creative, imaginative, fun
class AppTheme {
  AppTheme._();

  // Primary colors - Cheerful coral/orange palette (warmth, joy, energy)
  static const Color primaryColor = Color(0xFFFF7043); // Deep Orange 400 - Coral
  static const Color primaryVariant = Color(0xFFE64A19); // Deep Orange 700
  static const Color primaryLight = Color(0xFFFFAB91); // Deep Orange 200 - Soft coral

  // Secondary colors - Playful teal palette (trust, calm, safety)
  static const Color secondaryColor = Color(0xFF26C6DA); // Cyan 400 - Teal
  static const Color secondaryVariant = Color(0xFF00ACC1); // Cyan 600
  static const Color secondaryLight = Color(0xFF80DEEA); // Cyan 200 - Sky blue

  // Accent colors - Sunny and cheerful
  static const Color accentColor = Color(0xFFFFD54F); // Amber 300 - Sunny yellow
  static const Color accentLight = Color(0xFFFFF8E1); // Amber 50 - Cream yellow

  // Tertiary colors - Playful purple for creativity
  static const Color tertiaryColor = Color(0xFFBA68C8); // Purple 300 - Playful purple
  static const Color tertiaryLight = Color(0xFFE1BEE7); // Purple 100 - Soft lavender

  // Status colors - Friendly, not alarming
  static const Color successColor = Color(0xFF81C784); // Green 300 - Soft green
  static const Color warningColor = Color(0xFFFFB74D); // Orange 300 - Warm amber
  static const Color errorColor = Color(0xFFE57373); // Red 300 - Soft coral red
  static const Color infoColor = Color(0xFF4FC3F7); // Light Blue 300 - Friendly blue

  // Detection type colors - Visible but child-friendly (not scary)
  static const Color profanityColor =
      Color(0xFFFFB300); // Amber 600 - Warm gold (alert but friendly)
  static const Color nsfwColor = Color(0xFFEC407A); // Pink 400 (soft magenta)
  static const Color nudityColor =
      Color(0xFFEC407A); // Pink 400 (same as NSFW)
  static const Color violenceColor = Color(0xFFFF8A65); // Deep Orange 300 - Muted coral
  static const Color bloodColor = Color(0xFFEF5350); // Red 400 - Softer red
  static const Color weaponsColor =
      Color(0xFF90A4AE); // Blue Grey 300 - Neutral gray

  /// Light theme - Cheerful coral/teal palette for family-friendly editing
  /// Inspired by popular kids apps with warm, inviting colors
  static ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
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
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
    );

  /// Dark theme - Cheerful coral/teal palette for family-friendly editing
  /// Uses lighter variants for better visibility on dark backgrounds
  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight, // Lighter coral for dark theme visibility
        secondary: secondaryLight, // Sky blue for dark theme visibility
        tertiary: tertiaryLight,
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
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
    );

  /// Get color for detection type
  /// Returns child-friendly colors that are distinct but not scary
  /// Colors are softer variants that alert without alarming children
  static Color getDetectionColor(String type) {
    switch (type.toLowerCase()) {
      case 'profanity':
        return profanityColor; // Warm gold - alert but friendly
      case 'nsfw':
        return nsfwColor; // Soft pink - distinct
      case 'nudity':
        return nudityColor; // Soft pink
      case 'violence':
        return violenceColor; // Muted coral
      case 'blood':
        return bloodColor; // Softer red
      case 'weapons':
        return weaponsColor; // Neutral gray
      default:
        return const Color(0xFFB0BEC5); // Blue Grey 200 - neutral fallback
    }
  }

  /// Get a lighter variant of detection color for backgrounds
  static Color getDetectionColorLight(String type) => getDetectionColor(type).withValues(alpha: 0.2);

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
