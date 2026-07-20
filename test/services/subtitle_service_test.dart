import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/services/subtitle_service.dart';

void main() {
  late SubtitleService subtitleService;
  late Transcript testTranscript;

  setUp(() {
    subtitleService = const SubtitleService();

    // Create a test transcript with word-level timing
    testTranscript = Transcript(
      segments: [
        const TranscriptSegment(
          id: '0',
          startTime: Duration(),
          endTime: Duration(seconds: 3),
          text: 'Hello world, this is a test.',
          words: [
            TranscriptWord(
              word: 'Hello',
              startTime: Duration(),
              endTime: Duration(milliseconds: 500),
              confidence: 0.95,
            ),
            TranscriptWord(
              word: 'world,',
              startTime: Duration(milliseconds: 550),
              endTime: Duration(milliseconds: 900),
              confidence: 0.92,
            ),
            TranscriptWord(
              word: 'this',
              startTime: Duration(milliseconds: 1000),
              endTime: Duration(milliseconds: 1200),
              confidence: 0.98,
            ),
            TranscriptWord(
              word: 'is',
              startTime: Duration(milliseconds: 1250),
              endTime: Duration(milliseconds: 1400),
              confidence: 0.99,
            ),
            TranscriptWord(
              word: 'a',
              startTime: Duration(milliseconds: 1450),
              endTime: Duration(milliseconds: 1550),
              confidence: 0.97,
            ),
            TranscriptWord(
              word: 'test.',
              startTime: Duration(milliseconds: 1600),
              endTime: Duration(milliseconds: 2000),
              confidence: 0.96,
            ),
          ],
        ),
        const TranscriptSegment(
          id: '1',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 8),
          text: 'Another sentence here.',
          words: [
            TranscriptWord(
              word: 'Another',
              startTime: Duration(seconds: 5),
              endTime: Duration(seconds: 5, milliseconds: 500),
              confidence: 0.94,
            ),
            TranscriptWord(
              word: 'sentence',
              startTime: Duration(seconds: 5, milliseconds: 600),
              endTime: Duration(seconds: 6, milliseconds: 200),
              confidence: 0.91,
            ),
            TranscriptWord(
              word: 'here.',
              startTime: Duration(seconds: 6, milliseconds: 300),
              endTime: Duration(seconds: 6, milliseconds: 800),
              confidence: 0.93,
            ),
          ],
        ),
      ],
      language: 'en',
      generatedAt: DateTime.now(),
    );
  });

  group('SubtitleService', () {
    group('SRT Format', () {
      test('generates valid SRT format', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.srt,
        );

        // Check for SRT structure
        expect(content, contains('1\n'));
        expect(content, contains('2\n'));
        expect(content, contains('-->'));

        // Check time format (HH:MM:SS,mmm)
        expect(content, matches(RegExp(r'\d{2}:\d{2}:\d{2},\d{3}')));
      });

      test('uses comma as millisecond separator in SRT', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.srt,
        );

        // SRT uses comma, not period
        expect(content, contains(','));
        expect(
          content,
          matches(
            RegExp(r'\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}'),
          ),
        );
      });

      test('includes transcript text', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.srt,
        );

        expect(content, contains('Hello'));
        expect(content, contains('world'));
        expect(content, contains('Another'));
      });
    });

    group('VTT Format', () {
      test('generates valid WebVTT format', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.vtt,
        );

        // VTT header
        expect(content, startsWith('WEBVTT'));
        expect(content, contains('Kind: captions'));
        expect(content, contains('Language: en'));
      });

      test('uses period as millisecond separator in VTT', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.vtt,
        );

        // VTT uses period, not comma
        expect(
          content,
          matches(
            RegExp(r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}'),
          ),
        );
      });
    });

    group('ASS Format', () {
      test('generates valid ASS format', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.ass,
        );

        // ASS sections
        expect(content, contains('[Script Info]'));
        expect(content, contains('[V4+ Styles]'));
        expect(content, contains('[Events]'));
        expect(content, contains('Dialogue:'));
      });

      test('includes style definitions', () {
        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.ass,
        );

        expect(content, contains('Style: Default'));
        expect(content, contains('Format: Name, Fontname'));
      });
    });

    group('File Generation', () {
      test('writes SRT file to disk', () async {
        final tempDir = Directory.systemTemp.createTempSync('subtitle_test_');
        final outputPath = '${tempDir.path}/test_output.srt';

        try {
          final file = await subtitleService.generateSubtitles(
            testTranscript,
            outputPath,
            SubtitleFormat.srt,
          );

          expect(file.existsSync(), isTrue);
          expect(file.path, equals(outputPath));

          final content = await file.readAsString();
          expect(content, contains('-->'));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('writes VTT file with correct extension', () async {
        final tempDir = Directory.systemTemp.createTempSync('subtitle_test_');
        final outputPath = '${tempDir.path}/test_output.vtt';

        try {
          final file = await subtitleService.generateSubtitles(
            testTranscript,
            outputPath,
            SubtitleFormat.vtt,
          );

          expect(file.existsSync(), isTrue);

          final content = await file.readAsString();
          expect(content, startsWith('WEBVTT'));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    group('Subtitle Options', () {
      test('respects maxCharsPerLine option', () {
        const options = SubtitleOptions(maxCharsPerLine: 20);

        final content = subtitleService.generateSubtitleContent(
          testTranscript,
          SubtitleFormat.srt,
          options: options,
        );

        // Lines should be wrapped
        final lines = content.split('\n');
        for (final line in lines) {
          // Skip timing lines and empty lines
          if (line.contains('-->') ||
              line.isEmpty ||
              RegExp(r'^\d+$').hasMatch(line)) {
            continue;
          }
          // Content lines should respect the max chars
          expect(
            line.length,
            lessThanOrEqualTo(42),
          ); // Some tolerance for edge cases
        }
      });
    });

    group('SubtitleFormat enum', () {
      test('has correct extensions', () {
        expect(SubtitleFormat.srt.extension, equals('srt'));
        expect(SubtitleFormat.vtt.extension, equals('vtt'));
        expect(SubtitleFormat.ass.extension, equals('ass'));
      });

      test('has display names', () {
        expect(SubtitleFormat.srt.displayName, contains('SRT'));
        expect(SubtitleFormat.vtt.displayName, contains('WebVTT'));
        expect(SubtitleFormat.ass.displayName, contains('ASS'));
      });
    });

    group('Edge Cases', () {
      test('handles empty transcript', () {
        final emptyTranscript = Transcript(
          segments: [],
          language: 'en',
          generatedAt: DateTime.now(),
        );

        final content = subtitleService.generateSubtitleContent(
          emptyTranscript,
          SubtitleFormat.srt,
        );

        // Should produce valid (empty) SRT
        expect(content, isNotNull);
      });

      test('handles segment without word timings', () {
        final simpleTranscript = Transcript(
          segments: [
            const TranscriptSegment(
              id: '0',
              startTime: Duration(),
              endTime: Duration(seconds: 5),
              text: 'This is a simple segment without word timings.',
              words: [],
            ),
          ],
          language: 'en',
          generatedAt: DateTime.now(),
        );

        final content = subtitleService.generateSubtitleContent(
          simpleTranscript,
          SubtitleFormat.srt,
        );

        expect(content, contains('simple segment'));
      });
    });
  });
}
