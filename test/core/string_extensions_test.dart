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

      test('should return empty for dot file without extension', () {
        expect('.gitignore'.fileExtension, equals(''));
      });

      test('should handle trailing dot', () {
        expect('filename.'.fileExtension, equals(''));
      });

      test('should return lowercase for uppercase extensions', () {
        expect('video.MP4'.fileExtension, equals('mp4'));
      });

      test('should return lowercase from mixed case', () {
        expect('video.Mp4'.fileExtension, equals('mp4'));
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
        expect('/path/to/folder/'.fileName, equals('folder'));
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
          'This is a very long string'.truncate(13),
          equals('This is a ...'),
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
        expect('Hello'.truncate(3), equals('...'));
      });

      test('should handle empty string', () {
        expect(''.truncate(10), equals(''));
      });
    });

    group('isValidPath', () {
      test('should return true for valid Unix path', () {
        expect('/path/to/file.txt'.isValidPath, isTrue);
      });

      test('should return true for valid Windows path', () {
        expect('C:\\Users\\file.txt'.isValidPath, isTrue);
      });

      test('should return true for relative path', () {
        expect('relative/path/file.txt'.isValidPath, isTrue);
      });

      test('should return true for simple filename', () {
        expect('file.txt'.isValidPath, isTrue);
      });

      test('should return true for empty string', () {
        expect(''.isValidPath, isTrue);
      });
    });
  });
}
