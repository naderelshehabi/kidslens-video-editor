import 'dart:convert';
import 'dart:io';

/// Custom ARB (Application Resource Bundle) parser
class ArbParser {
  /// Parse ARB file and return translations
  static Future<Map<String, String>> parse(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArbParseException('ARB file not found: $filePath');
    }

    final content = await file.readAsString();
    return parseString(content);
  }

  /// Parse ARB content from string
  static Map<String, String> parseString(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final translations = <String, String>{};

      for (final entry in json.entries) {
        // Skip metadata entries (those starting with @)
        if (entry.key.startsWith('@')) continue;

        if (entry.value is String) {
          translations[entry.key] = entry.value as String;
        }
      }

      return translations;
    } on FormatException catch (e) {
      throw ArbParseException('Invalid JSON in ARB file: ${e.message}');
    }
  }

  /// Extract placeholders from a message
  static List<String> extractPlaceholders(String message) {
    final regex = RegExp(r'\{(\w+)\}');
    return regex.allMatches(message).map((m) => m.group(1)!).toList();
  }

  /// Format a message with placeholders
  static String format(String message, Map<String, dynamic> params) {
    var result = message;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }

  /// Validate ARB file structure
  static List<String> validate(String content) {
    final errors = <String>[];

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Check for required @@locale
      if (!json.containsKey('@@locale')) {
        errors.add('Missing @@locale metadata');
      }

      // Check each entry
      for (final entry in json.entries) {
        if (entry.key.startsWith('@@')) continue;
        if (entry.key.startsWith('@')) {
          // This is metadata for a key
          final messageKey = entry.key.substring(1);
          if (!json.containsKey(messageKey)) {
            errors.add('Metadata @$messageKey has no corresponding message');
          }
        } else {
          // This is a message
          if (entry.value is! String) {
            errors.add('Message ${entry.key} must be a string');
          }
        }
      }
    } on FormatException catch (e) {
      errors.add('Invalid JSON: ${e.message}');
    }

    return errors;
  }
}

/// Exception thrown during ARB parsing
class ArbParseException implements Exception {
  final String message;

  ArbParseException(this.message);

  @override
  String toString() => 'ArbParseException: $message';
}

/// Localization delegate that loads from ARB files
class AppLocalizationsDelegate {
  final Map<String, Map<String, String>> _translations = {};
  final List<String> supportedLocales;
  final String defaultLocale;

  AppLocalizationsDelegate({
    required this.supportedLocales,
    this.defaultLocale = 'en',
  });

  /// Load translations for a locale
  Future<void> load(String locale, String arbContent) async {
    _translations[locale] = ArbParser.parseString(arbContent);
  }

  /// Get a translation
  String translate(String locale, String key, [Map<String, dynamic>? params]) {
    final localeTranslations = _translations[locale] ?? _translations[defaultLocale];
    if (localeTranslations == null) {
      return key;
    }

    final message = localeTranslations[key] ?? key;
    if (params != null) {
      return ArbParser.format(message, params);
    }
    return message;
  }

  /// Check if a locale is loaded
  bool isLoaded(String locale) => _translations.containsKey(locale);

  /// Get all keys for a locale
  Set<String> getKeys(String locale) =>
      _translations[locale]?.keys.toSet() ?? {};
}
