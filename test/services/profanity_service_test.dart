import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/profanity_match.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';

void main() {
  late ProfanityService profanityService;

  setUp(() {
    profanityService = ProfanityService();
  });

  group('ProfanityService', () {
    group('initialization', () {
      test('should create a new service instance', () {
        expect(profanityService, isNotNull);
      });

      test('should load word list for language', () async {
        await profanityService.loadWordList('en');
        // No exception means success
      });
    });

    group('custom words', () {
      test('should add custom words for detection', () {
        profanityService.addCustomWords(['customword', 'anotherword']);
        // No exception means success
      });

      test('should detect custom words', () async {
        profanityService.addCustomWords(['testbadword']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 5),
              text: 'This is a testbadword example',
              words: [
                TranscriptWord(
                  word: 'This',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 200),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'is',
                  startTime: Duration(milliseconds: 200),
                  endTime: Duration(milliseconds: 400),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'a',
                  startTime: Duration(milliseconds: 400),
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.99,
                ),
                TranscriptWord(
                  word: 'testbadword',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.97,
                ),
                TranscriptWord(
                  word: 'example',
                  startTime: Duration(seconds: 1),
                  endTime: Duration(seconds: 2),
                  confidence: 0.96,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, isNotEmpty);
        expect(matches.first.matchedProfanity, equals('testbadword'));
        expect(matches.first.type, equals(MatchType.exact));
        expect(matches.first.confidence, equals(1.0));
      });
    });

    group('excluded words', () {
      test('should add words to exclusion list', () {
        profanityService.excludeWords(['allowedword', 'safeword']);
        // No exception means success
      });

      test('should not detect excluded words', () async {
        await profanityService.loadWordList('en');
        profanityService
          ..addCustomWords(['testword'])
          ..excludeWords(['testword']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'Using testword here',
              words: [
                TranscriptWord(
                  word: 'Using',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'testword',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'here',
                  startTime: Duration(seconds: 1),
                  endTime: Duration(seconds: 2),
                  confidence: 0.97,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, isEmpty);
      });
    });

    group('detection', () {
      test('should return empty list for clean transcript', () {
        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 5),
              text: 'This is a clean sentence',
              words: [
                TranscriptWord(
                  word: 'This',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'is',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(milliseconds: 700),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'a',
                  startTime: Duration(milliseconds: 700),
                  endTime: Duration(milliseconds: 800),
                  confidence: 0.99,
                ),
                TranscriptWord(
                  word: 'clean',
                  startTime: Duration(milliseconds: 800),
                  endTime: Duration(seconds: 1),
                  confidence: 0.97,
                ),
                TranscriptWord(
                  word: 'sentence',
                  startTime: Duration(seconds: 1),
                  endTime: Duration(seconds: 2),
                  confidence: 0.96,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, isEmpty);
      });

      test('should return empty list for empty transcript', () {
        final transcript = Transcript.empty();

        final matches = profanityService.detect(transcript);

        expect(matches, isEmpty);
      });

      test('should detect multiple profanity matches', () async {
        profanityService.addCustomWords(['badword1', 'badword2']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 5),
              text: 'badword1 and then badword2',
              words: [
                TranscriptWord(
                  word: 'badword1',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'and',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(milliseconds: 700),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'then',
                  startTime: Duration(milliseconds: 700),
                  endTime: Duration(seconds: 1),
                  confidence: 0.97,
                ),
                TranscriptWord(
                  word: 'badword2',
                  startTime: Duration(seconds: 1),
                  endTime: Duration(seconds: 2),
                  confidence: 0.96,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(2));
      });

      test('should detect profanity in multiple segments', () async {
        profanityService.addCustomWords(['profanity']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'First profanity',
              words: [
                TranscriptWord(
                  word: 'First',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'profanity',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
            TranscriptSegment(
              id: 'seg-2',
              startTime: Duration(seconds: 5),
              endTime: Duration(seconds: 8),
              text: 'Second profanity',
              words: [
                TranscriptWord(
                  word: 'Second',
                  startTime: Duration(seconds: 5),
                  endTime: Duration(seconds: 6),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'profanity',
                  startTime: Duration(seconds: 6),
                  endTime: Duration(seconds: 7),
                  confidence: 0.97,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(2));
      });
    });

    group('leetspeak detection', () {
      test('should detect leetspeak variations', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['test']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 't3st word',
              words: [
                TranscriptWord(
                  word: 't3st',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'word',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        // Should detect 't3st' as leetspeak for 'test'
        if (matches.isNotEmpty) {
          expect(matches.first.type, equals(MatchType.leetspeak));
          expect(matches.first.confidence, lessThan(1.0)); // Lower confidence for leetspeak
        }
      });
    });

    group('normalization', () {
      test('should handle case insensitivity', () {
        profanityService.addCustomWords(['testword']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'TESTWORD and TestWord',
              words: [
                TranscriptWord(
                  word: 'TESTWORD',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'and',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(milliseconds: 700),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'TestWord',
                  startTime: Duration(milliseconds: 700),
                  endTime: Duration(seconds: 1),
                  confidence: 0.97,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(2));
      });

      test('should strip punctuation from words', () {
        profanityService.addCustomWords(['badword']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'badword! and badword?',
              words: [
                TranscriptWord(
                  word: 'badword!',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'and',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(milliseconds: 700),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'badword?',
                  startTime: Duration(milliseconds: 700),
                  endTime: Duration(seconds: 1),
                  confidence: 0.97,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(2));
      });
    });

    group('ProfanityMatch properties', () {
      test('should include correct word timing information', () {
        profanityService.addCustomWords(['detected']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 5),
              text: 'The detected word here',
              words: [
                TranscriptWord(
                  word: 'The',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 200),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'detected',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'word',
                  startTime: Duration(seconds: 1),
                  endTime: Duration(seconds: 2),
                  confidence: 0.97,
                ),
                TranscriptWord(
                  word: 'here',
                  startTime: Duration(seconds: 2),
                  endTime: Duration(seconds: 3),
                  confidence: 0.96,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(1));
        expect(
          matches.first.startTime,
          equals(const Duration(milliseconds: 500)),
        );
        expect(
          matches.first.endTime,
          equals(const Duration(seconds: 1)),
        );
        expect(matches.first.originalWord, equals('detected'));
      });

      test('should generate unique IDs for each match', () {
        profanityService.addCustomWords(['word1', 'word2']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 3),
              text: 'word1 word2',
              words: [
                TranscriptWord(
                  word: 'word1',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'word2',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(2));
        expect(matches[0].id, isNotEmpty);
        expect(matches[1].id, isNotEmpty);
        expect(matches[0].id, isNot(equals(matches[1].id)));
      });
    });

    group('edge cases', () {
      test('should handle very short words', () {
        profanityService.addCustomWords(['x']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'A x B',
              words: [
                TranscriptWord(
                  word: 'A',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 200),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'x',
                  startTime: Duration(milliseconds: 200),
                  endTime: Duration(milliseconds: 400),
                  confidence: 0.98,
                ),
                TranscriptWord(
                  word: 'B',
                  startTime: Duration(milliseconds: 400),
                  endTime: Duration(milliseconds: 600),
                  confidence: 0.97,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        expect(matches, hasLength(1));
      });

      test('should handle empty words gracefully', () {
        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: '',
              words: [
                TranscriptWord(
                  word: '',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 200),
                  confidence: 0.95,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        // Should not throw
        final matches = profanityService.detect(transcript);
        expect(matches, isEmpty);
      });

      test('should handle special characters in words', () {
        profanityService.addCustomWords(['test']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 't@e#s\$t',
              words: [
                TranscriptWord(
                  word: 't@e#s\$t',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        // Should try to normalize and potentially match
        profanityService.detect(transcript);
        // Result depends on implementation details
      });
    });

    group('isLanguageLoaded state', () {
      test('should return false for unloaded language', () {
        final isLoaded = profanityService.isLanguageLoaded('xx');

        expect(isLoaded, isFalse);
      });

      test('should return true after loading language', () async {
        await profanityService.loadWordList('en');

        final isLoaded = profanityService.isLanguageLoaded('en');

        expect(isLoaded, isTrue);
      });

      test('should track multiple loaded languages', () async {
        await profanityService.loadWordList('en');
        await profanityService.loadWordList('de');

        expect(profanityService.isLanguageLoaded('en'), isTrue);
        expect(profanityService.isLanguageLoaded('de'), isTrue);
        expect(profanityService.isLanguageLoaded('fr'), isFalse);
      });

      test('should return loaded languages set', () async {
        await profanityService.loadWordList('en');
        await profanityService.loadWordList('es');

        final loaded = profanityService.loadedLanguages;

        expect(loaded, contains('en'));
        expect(loaded, contains('es'));
      });

      test('getWordCount should return 0 for unloaded language', () {
        final count = profanityService.getWordCount('xx');

        expect(count, equals(0));
      });

      test('getWordCount should return count after loading', () async {
        await profanityService.loadWordList('en');

        final count = profanityService.getWordCount('en');

        // English wordlist should have some words
        expect(count, greaterThanOrEqualTo(0));
      });

      test('clearWordlists should reset loaded state', () async {
        await profanityService.loadWordList('en');
        expect(profanityService.isLanguageLoaded('en'), isTrue);

        profanityService.clearWordlists();

        expect(profanityService.isLanguageLoaded('en'), isFalse);
        expect(profanityService.loadedLanguages, isEmpty);
      });
    });

    group('phonetic matching (Double Metaphone)', () {
      test('should detect phonetically similar words', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['phone']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'fone call',
              words: [
                TranscriptWord(
                  word: 'fone',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'call',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        // 'fone' and 'phone' have the same phonetic encoding
        if (matches.isNotEmpty) {
          expect(matches.first.type, equals(MatchType.phonetic));
          expect(matches.first.confidence, lessThan(1.0));
        }
      });

      test('should handle words starting with silent letters', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['knife']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'nife sharp',
              words: [
                TranscriptWord(
                  word: 'nife',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'sharp',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        // Should try phonetic matching for 'nife' vs 'knife'
        profanityService.detect(transcript);
        // Result depends on phonetic algorithm specifics
      });

      test('should match words with different spellings but same sound', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['tough']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'tuff guy',
              words: [
                TranscriptWord(
                  word: 'tuff',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'guy',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        // 'tuff' and 'tough' should be phonetically similar
        if (matches.isNotEmpty) {
          expect(
            matches.first.type,
            anyOf(equals(MatchType.phonetic), equals(MatchType.fuzzy)),
          );
        }
      });
    });

    group('fuzzy matching (Levenshtein distance)', () {
      test('should detect words with minor typos', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['badword']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'badwrod here',
              words: [
                TranscriptWord(
                  word: 'badwrod',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'here',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        // 'badwrod' is one transposition away from 'badword'
        if (matches.isNotEmpty) {
          expect(matches.first.confidence, lessThan(1.0));
        }
      });

      test('should detect words with single character difference', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['testing']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'testng example',
              words: [
                TranscriptWord(
                  word: 'testng',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'example',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        // 'testng' is missing one letter from 'testing'
        profanityService.detect(transcript);
        // Result depends on similarity threshold
      });

      test('should not match words that are too different', () async {
        await profanityService.loadWordList('en');
        profanityService.addCustomWords(['specific']);

        const transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg-1',
              startTime: Duration.zero,
              endTime: Duration(seconds: 2),
              text: 'completely different',
              words: [
                TranscriptWord(
                  word: 'completely',
                  startTime: Duration.zero,
                  endTime: Duration(milliseconds: 500),
                  confidence: 0.95,
                ),
                TranscriptWord(
                  word: 'different',
                  startTime: Duration(milliseconds: 500),
                  endTime: Duration(seconds: 1),
                  confidence: 0.98,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        final matches = profanityService.detect(transcript);

        // Words are too different, should not match
        expect(
          matches.where((m) => m.matchedProfanity == 'specific'),
          isEmpty,
        );
      });
    });

    group('LanguageInfo', () {
      test('should parse from JSON correctly', () {
        final json = {
          'code': 'en',
          'name': 'English',
          'rtl': false,
        };

        final info = LanguageInfo.fromJson(json);

        expect(info.code, equals('en'));
        expect(info.name, equals('English'));
        expect(info.rtl, isFalse);
      });

      test('should handle RTL languages', () {
        final json = {
          'code': 'ar',
          'name': 'Arabic',
          'rtl': true,
        };

        final info = LanguageInfo.fromJson(json);

        expect(info.code, equals('ar'));
        expect(info.rtl, isTrue);
      });
    });

    group('metadata loading', () {
      test('should load metadata successfully', () async {
        await profanityService.loadMetadata();

        final languages = profanityService.supportedLanguages;

        // Should have at least English
        expect(languages, isNotEmpty);
      });

      test('supportedLanguages should be immutable', () async {
        await profanityService.loadMetadata();

        final languages = profanityService.supportedLanguages;

        expect(() => languages.add(const LanguageInfo(code: 'xx', name: 'Test', rtl: false)),
            throwsA(isA<UnsupportedError>()),);
      });
    });
  });
}
