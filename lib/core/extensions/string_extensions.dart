import 'package:path/path.dart' as p;

/// Extension methods for String
extension StringExtensions on String {
  /// Get file extension without the dot
  String get fileExtension => p.extension(this).replaceFirst('.', '').toLowerCase();
  
  /// Get filename without extension
  String get fileNameWithoutExtension => p.basenameWithoutExtension(this);
  
  /// Get filename with extension
  String get fileName => p.basename(this);
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Convert to title case
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');
  
  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
  
  /// Check if string is a valid file path
  bool get isValidPath {
    try {
      p.normalize(this);
      return true;
    } catch (_) {
      return false;
    }
  }
}
