import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('fileExtension', () {
      test('should extract simple extension', () {
        expect('video.mp4'.fileExtension, equals('mp4'));
      });

      test('should extract extension from path', () {
        expect('/path/to/video.mp4'.fileExtension, equals('mp4'));
      });

      test('should extract extension from Windows path', () {
        expect('C:\\Users\\video.mp4'.fileExtension, equals('mp4'));
      });

      test('should handle multiple dots', () {
        expect('archive.tar.gz'.fileExtension, equals('gz'));
      });

      test('should return empty for no extension', () {
        expect('filename'.fileExtension, equals(''));
      });

      test('should return empty for dot file', () {
        expect('.gitignore'.fileExtension, equals('gitignore'));
      });

      test('should handle trailing dot', () {
        expect('filename.'.fileExtension, equals(''));
      });

      test('should handle uppercase extensions', () {
        expect('video.MP4'.fileExtension, equals('MP4'));
      });
    });

    group('fileExtensionLower', () {
      test('should extract lowercase extension', () {
        expect('video.MP4'.fileExtensionLower, equals('mp4'));
      });

      test('should extract lowercase from mixed case', () {
        expect('video.Mp4'.fileExtensionLower, equals('mp4'));
      });

      test('should return empty for no extension', () {
        expect('filename'.fileExtensionLower, equals(''));
      });
    });

    group('fileName', () {
      test('should extract filename from path', () {
        expect('/path/to/video.mp4'.fileName, equals('video.mp4'));
      });

      test('should extract filename from Windows path', () {
        expect('C:\\Users\\video.mp4'.fileName, equals('video.mp4'));
      });

      test('should return filename when no path', () {
        expect('video.mp4'.fileName, equals('video.mp4'));
      });

      test('should handle trailing slash', () {
        expect('/path/to/folder/'.fileName, equals(''));
      });

      test('should handle multiple slashes', () {
        expect('/path//to//video.mp4'.fileName, equals('video.mp4'));
      });
    });

    group('fileNameWithoutExtension', () {
      test('should extract filename without extension', () {
        expect(
          '/path/to/video.mp4'.fileNameWithoutExtension,
          equals('video'),
        );
      });

      test('should handle multiple dots', () {
        expect(
          '/path/archive.tar.gz'.fileNameWithoutExtension,
          equals('archive.tar'),
        );
      });

      test('should handle no extension', () {
        expect(
          '/path/to/filename'.fileNameWithoutExtension,
          equals('filename'),
        );
      });
    });

    group('directoryPath', () {
      test('should extract directory from Unix path', () {
        expect(
          '/path/to/video.mp4'.directoryPath,
          equals('/path/to'),
        );
      });

      test('should extract directory from Windows path', () {
        expect(
          'C:\\Users\\Videos\\video.mp4'.directoryPath,
          equals('C:\\Users\\Videos'),
        );
      });

      test('should handle root path', () {
        expect('/video.mp4'.directoryPath, equals(''));
      });

      test('should handle filename only', () {
        expect('video.mp4'.directoryPath, equals(''));
      });
    });

    group('capitalize', () {
      test('should capitalize first letter', () {
        expect('hello'.capitalize, equals('Hello'));
      });

      test('should handle single character', () {
        expect('h'.capitalize, equals('H'));
      });

      test('should handle empty string', () {
        expect(''.capitalize, equals(''));
      });

      test('should preserve rest of string', () {
        expect('hELLO wORLD'.capitalize, equals('HELLO wORLD'));
      });

      test('should handle already capitalized', () {
        expect('Hello'.capitalize, equals('Hello'));
      });

      test('should handle numbers', () {
        expect('123abc'.capitalize, equals('123abc'));
      });

      test('should handle unicode', () {
        expect('über'.capitalize, equals('Über'));
      });
    });

    group('titleCase', () {
      test('should capitalize each word', () {
        expect('hello world'.titleCase, equals('Hello World'));
      });

      test('should handle single word', () {
        expect('hello'.titleCase, equals('Hello'));
      });

      test('should handle empty string', () {
        expect(''.titleCase, equals(''));
      });

      test('should handle multiple spaces', () {
        expect('hello  world'.titleCase, equals('Hello  World'));
      });

      test('should handle mixed case', () {
        expect('hELLO wORLD'.titleCase, equals('HELLO WORLD'));
      });
    });

    group('truncate', () {
      test('should truncate long string', () {
        expect(
          'This is a very long string'.truncate(10),
          equals('This is a...'),
        );
      });

      test('should not truncate short string', () {
        expect('Hello'.truncate(10), equals('Hello'));
      });

      test('should handle exact length', () {
        expect('HelloWorld'.truncate(10), equals('HelloWorld'));
      });

      test('should use custom ellipsis', () {
        expect(
          'This is a very long string'.truncate(10, ellipsis: '…'),
          equals('This is a…'),
        );
      });

      test('should handle empty ellipsis', () {
        expect(
          'This is a very long string'.truncate(10, ellipsis: ''),
          equals('This is a '),
        );
      });

      test('should handle zero length', () {
        expect('Hello'.truncate(0), equals('...'));
      });

      test('should handle empty string', () {
        expect(''.truncate(10), equals(''));
      });
    });

    group('truncateMiddle', () {
      test('should truncate middle of long string', () {
        expect(
          'very_long_filename.mp4'.truncateMiddle(15),
          equals('very_l...le.mp4'),
        );
      });

      test('should not truncate short string', () {
        expect('short.mp4'.truncateMiddle(15), equals('short.mp4'));
      });

      test('should handle exact length', () {
        expect(
          'exactly_fifteen'.truncateMiddle(15),
          equals('exactly_fifteen'),
        );
      });
    });

    group('isValidUrl', () {
      test('should validate http URL', () {
        expect('http://example.com'.isValidUrl, isTrue);
      });

      test('should validate https URL', () {
        expect('https://example.com'.isValidUrl, isTrue);
      });

      test('should validate URL with path', () {
        expect('https://example.com/path/to/resource'.isValidUrl, isTrue);
      });

      test('should validate URL with query', () {
        expect('https://example.com?key=value'.isValidUrl, isTrue);
      });

      test('should reject invalid URL', () {
        expect('not a url'.isValidUrl, isFalse);
      });

      test('should reject empty string', () {
        expect(''.isValidUrl, isFalse);
      });

      test('should reject ftp URL', () {
        expect('ftp://example.com'.isValidUrl, isFalse);
      });
    });

    group('isValidEmail', () {
      test('should validate simple email', () {
        expect('test@example.com'.isValidEmail, isTrue);
      });

      test('should validate email with subdomain', () {
        expect('test@mail.example.com'.isValidEmail, isTrue);
      });

      test('should validate email with plus', () {
        expect('test+tag@example.com'.isValidEmail, isTrue);
      });

      test('should validate email with dots', () {
        expect('first.last@example.com'.isValidEmail, isTrue);
      });

      test('should reject email without @', () {
        expect('testexample.com'.isValidEmail, isFalse);
      });

      test('should reject email without domain', () {
        expect('test@'.isValidEmail, isFalse);
      });

      test('should reject empty string', () {
        expect(''.isValidEmail, isFalse);
      });
    });

    group('removeWhitespace', () {
      test('should remove all whitespace', () {
        expect('hello world'.removeWhitespace, equals('helloworld'));
      });

      test('should remove tabs and newlines', () {
        expect('hello\t\nworld'.removeWhitespace, equals('helloworld'));
      });

      test('should handle empty string', () {
        expect(''.removeWhitespace, equals(''));
      });

      test('should handle no whitespace', () {
        expect('helloworld'.removeWhitespace, equals('helloworld'));
      });
    });

    group('normalizeWhitespace', () {
      test('should collapse multiple spaces', () {
        expect('hello    world'.normalizeWhitespace, equals('hello world'));
      });

      test('should convert tabs to spaces', () {
        expect('hello\tworld'.normalizeWhitespace, equals('hello world'));
      });

      test('should trim leading and trailing', () {
        expect('  hello world  '.normalizeWhitespace, equals('hello world'));
      });

      test('should handle newlines', () {
        expect('hello\n\nworld'.normalizeWhitespace, equals('hello world'));
      });
    });

    group('isBlank', () {
      test('should return true for empty string', () {
        expect(''.isBlank, isTrue);
      });

      test('should return true for whitespace only', () {
        expect('   '.isBlank, isTrue);
      });

      test('should return true for tabs and newlines', () {
        expect('\t\n'.isBlank, isTrue);
      });

      test('should return false for non-blank string', () {
        expect('hello'.isBlank, isFalse);
      });

      test('should return false for string with content and whitespace', () {
        expect('  hello  '.isBlank, isFalse);
      });
    });

    group('isNotBlank', () {
      test('should return false for empty string', () {
        expect(''.isNotBlank, isFalse);
      });

      test('should return false for whitespace only', () {
        expect('   '.isNotBlank, isFalse);
      });

      test('should return true for non-blank string', () {
        expect('hello'.isNotBlank, isTrue);
      });
    });

    group('toSnakeCase', () {
      test('should convert camelCase to snake_case', () {
        expect('camelCase'.toSnakeCase, equals('camel_case'));
      });

      test('should convert PascalCase to snake_case', () {
        expect('PascalCase'.toSnakeCase, equals('pascal_case'));
      });

      test('should handle consecutive capitals', () {
        expect('XMLParser'.toSnakeCase, equals('x_m_l_parser'));
      });

      test('should handle already snake_case', () {
        expect('snake_case'.toSnakeCase, equals('snake_case'));
      });

      test('should handle single word', () {
        expect('word'.toSnakeCase, equals('word'));
      });
    });

    group('toCamelCase', () {
      test('should convert snake_case to camelCase', () {
        expect('snake_case'.toCamelCase, equals('snakeCase'));
      });

      test('should handle multiple underscores', () {
        expect('multi_word_string'.toCamelCase, equals('multiWordString'));
      });

      test('should handle leading underscore', () {
        expect('_leading'.toCamelCase, equals('leading'));
      });

      test('should handle trailing underscore', () {
        expect('trailing_'.toCamelCase, equals('trailing'));
      });

      test('should handle already camelCase', () {
        expect('camelCase'.toCamelCase, equals('camelCase'));
      });
    });

    group('toKebabCase', () {
      test('should convert camelCase to kebab-case', () {
        expect('camelCase'.toKebabCase, equals('camel-case'));
      });

      test('should convert snake_case to kebab-case', () {
        expect('snake_case'.toKebabCase, equals('snake-case'));
      });

      test('should handle spaces', () {
        expect('hello world'.toKebabCase, equals('hello-world'));
      });
    });

    group('containsIgnoreCase', () {
      test('should find exact match', () {
        expect('Hello World'.containsIgnoreCase('World'), isTrue);
      });

      test('should find case-insensitive match', () {
        expect('Hello World'.containsIgnoreCase('world'), isTrue);
      });

      test('should return false for no match', () {
        expect('Hello World'.containsIgnoreCase('xyz'), isFalse);
      });

      test('should handle empty pattern', () {
        expect('Hello'.containsIgnoreCase(''), isTrue);
      });
    });

    group('replaceAll edge cases', () {
      test('should handle empty string', () {
        expect(''.replaceFirst('a', 'b'), equals(''));
      });

      test('should handle no matches', () {
        expect('hello'.replaceFirst('x', 'y'), equals('hello'));
      });
    });

    group('splitLines', () {
      test('should split by newline', () {
        expect('line1\nline2\nline3'.splitLines, equals(['line1', 'line2', 'line3']));
      });

      test('should handle Windows line endings', () {
        expect('line1\r\nline2'.splitLines, equals(['line1', 'line2']));
      });

      test('should handle empty string', () {
        expect(''.splitLines, equals(['']));
      });

      test('should handle single line', () {
        expect('single line'.splitLines, equals(['single line']));
      });
    });

    group('reverse', () {
      test('should reverse string', () {
        expect('hello'.reverse, equals('olleh'));
      });

      test('should handle empty string', () {
        expect(''.reverse, equals(''));
      });

      test('should handle single character', () {
        expect('a'.reverse, equals('a'));
      });

      test('should handle palindrome', () {
        expect('radar'.reverse, equals('radar'));
      });
    });

    group('nullIfEmpty', () {
      test('should return null for empty string', () {
        expect(''.nullIfEmpty, isNull);
      });

      test('should return string for non-empty', () {
        expect('hello'.nullIfEmpty, equals('hello'));
      });
    });

    group('nullIfBlank', () {
      test('should return null for blank string', () {
        expect('   '.nullIfBlank, isNull);
      });

      test('should return string for non-blank', () {
        expect('hello'.nullIfBlank, equals('hello'));
      });
    });
  });
}
