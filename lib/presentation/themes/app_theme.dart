import 'package:flutter/material.dart';

/// Application theme configuration
/// Uses a cheerful, family-friendly color palette.
///
/// Keywords: Family, Safe, kids, joy, entertainment, cheerful
///
/// Color Psychology:
/// - Blue: Safe, trustworthy, calm, friendly
/// - Yellow/Amber: Joy, optimism, entertainment, energy
/// - Green: Growth, harmony, safety
/// - Pink: Playful, sweet, cheerful
class AppTheme {
  AppTheme._();

  // Primary colors - Safe & Trustworthy Blue (Family, Safe)
  static const Color primaryColor = Color(0xFF1E88E5); // Blue 600
  static const Color primaryVariant = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight = Color(0xFF64B5F6); // Blue 300

  // Secondary colors - Joyful Amber/Yellow (Joy, Entertainment)
  static const Color secondaryColor = Color(0xFFFFB300); // Amber 600
  static const Color secondaryVariant = Color(0xFFFF8F00); // Amber 800
  static const Color secondaryLight = Color(0xFFFFD54F); // Amber 300

  // Tertiary colors - Playful Green (Cheerful, Growth)
  static const Color tertiaryColor = Color(0xFF43A047); // Green 600
  static const Color tertiaryLight = Color(0xFF81C784); // Green 300

  // Accent colors - Fun Pink
  static const Color accentColor = Color(0xFFEC407A); // Pink 400
  static const Color accentLight = Color(0xFFF48FB1); // Pink 200

  // Status colors - Clear and friendly
  static const Color successColor = Color(0xFF66BB6A); // Green 400
  static const Color warningColor = Color(0xFFFFA726); // Orange 400
  static const Color errorColor = Color(0xFFEF5350); // Red 400
  static const Color infoColor = Color(0xFF42A5F5); // Blue 400

  // Background colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7FA); // Very light cool grey/blue
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);

  // Detection type colors - Consistent with the safe/joy theme
  static const Color profanityColor = Color(0xFFFFCA28); // Amber 400
  static const Color nsfwColor = Color(0xFFAB47BC); // Purple 400
  static const Color nudityColor = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color violenceColor = Color(0xFFFF7043); // Deep Orange 400
  static const Color bloodColor = Color(0xFFE53935); // Red 600
  static const Color weaponsColor = Color(0xFF78909C); // Blue Grey 400

  // Visual content category colors
  static const Color sexualContentColor = Color(0xFFC62828); // Dark Red 800
  static const Color kissingColor = Color(0xFFEC407A); // Pink 400
  static const Color immodestDressColor = Color(0xFFFFA000); // Amber 700
  static const Color customColor = Color(0xFF9E9E9E); // Grey 500

  /// Light theme - Cheerful Blue/Amber palette for family-friendly editing
  static ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
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
        fillColor: surfaceLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
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

  /// Dark theme - Cheerful Blue/Amber palette adapted for dark mode
  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight, // Lighter for dark theme visibility
        secondary: secondaryLight, // Lighter amber for dark theme visibility
        tertiary: tertiaryLight,
        error: errorColor,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundDark,
        surfaceTintColor: Colors.transparent,
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
        fillColor: const Color(0xFF2C2C2C),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
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
  static Color getDetectionColor(String type) {
    switch (type.toLowerCase()) {
      case 'profanity':
        return profanityColor;
      case 'nsfw':
        return nsfwColor;
      case 'nudity':
        return nudityColor;
      case 'sexual_content':
      case 'sexualcontent':
        return sexualContentColor;
      case 'kissing':
        return kissingColor;
      case 'immodest_dress':
      case 'immodestdress':
        return immodestDressColor;
      case 'violence':
        return violenceColor;
      case 'blood':
        return bloodColor;
      case 'weapons':
        return weaponsColor;
      case 'custom':
        return customColor;
      default:
        return const Color(0xFF90A4AE); // Blue Grey 300 - neutral fallback
    }
  }

  /// Get a lighter variant of detection color for backgrounds
  static Color getDetectionColorLight(String type) => getDetectionColor(type).withValues(alpha: 0.2);

  /// Get text color for detection badges (ensures accessibility)
  static Color getDetectionTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'blood':
      case 'violence':
      case 'nsfw':
      case 'nudity':
      case 'sexual_content':
      case 'sexualcontent':
      case 'kissing':
        return Colors.white;
      case 'immodest_dress':
      case 'immodestdress':
      case 'custom':
      default:
        return Colors.black87;
    }
  }
}
