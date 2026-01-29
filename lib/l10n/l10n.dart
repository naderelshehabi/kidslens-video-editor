import 'package:flutter/material.dart';

/// Supported locales
class L10n {
  L10n._();

  /// List of supported locales
  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('ar'),
  ];

  /// Default locale
  static const defaultLocale = Locale('en');

  /// Locale names for display
  static String getLocaleName(String languageCode) => switch (languageCode) {
        'en' => 'English',
        'es' => 'Español',
        'ar' => 'العربية',
        _ => languageCode,
      };

  /// Check if locale is RTL
  static bool isRtl(String languageCode) => languageCode == 'ar';
}
