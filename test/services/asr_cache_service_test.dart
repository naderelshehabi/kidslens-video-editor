import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/services/asr_cache_service.dart';

Transcript _makeTranscript({String language = 'en'}) => Transcript(
      segments: [
        const TranscriptSegment(
          id: 'seg_0',
          text: 'Hello world',
          startTime: Duration.zero,
          endTime: Duration(seconds: 2),
          words: [],
        ),
      ],
      language: language,
      modelId: 'test-model',
    );

void main() {
  late Directory tempCacheDir;
  late File tempAudioFile;
  late AsrCacheService cache;

  setUp(() async {
    tempCacheDir = Directory.systemTemp.createTempSync(
      'asr_cache_test_${DateTime.now().millisecondsSinceEpoch}_',
    );
    tempAudioFile = File(
      '${Directory.systemTemp.path}/test_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    )..writeAsStringSync('fake wav data');

    cache = AsrCacheService();
    await cache.init(cacheDirectory: tempCacheDir);
  });

  tearDown(() async {
    if (tempAudioFile.existsSync()) tempAudioFile.deleteSync();
    if (tempCacheDir.existsSync()) {
      tempCacheDir.deleteSync(recursive: true);
    }
  });

  group('AsrCacheService', () {
    test('lookup returns null for non-existent entry', () async {
      final result = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );
      expect(result, isNull);
    });

    test('store + lookup round-trip returns the same transcript', () async {
      final transcript = _makeTranscript();

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: transcript,
      );

      final result = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );

      expect(result, isNotNull);
      expect(result!.language, equals('en'));
      expect(result.segments.length, equals(1));
      expect(result.segments.first.text, equals('Hello world'));
    });

    test('different model IDs produce different cache entries', () async {
      final transcript1 = _makeTranscript();
      final transcript2 = _makeTranscript(language: 'es');

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: transcript1,
      );

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-small',
        language: 'en',
        transcript: transcript2,
      );

      final result1 = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );
      final result2 = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-small',
        language: 'en',
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.language, equals('en'));
      // transcript2 was stored with language 'es'
      expect(result2!.language, equals('es'));
    });

    test('different languages produce different cache entries', () async {
      final transcriptEn = _makeTranscript();
      final transcriptEs = _makeTranscript(language: 'es');

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: transcriptEn,
      );

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'es',
        transcript: transcriptEs,
      );

      final resultEn = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );
      final resultEs = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'es',
      );

      expect(resultEn, isNotNull);
      expect(resultEs, isNotNull);
      expect(resultEn!.language, equals('en'));
      expect(resultEs!.language, equals('es'));
    });

    test('null language vs explicit language produce different cache entries',
        () async {
      final transcriptAuto = _makeTranscript(language: 'detected');
      final transcriptEn = _makeTranscript();

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        transcript: transcriptAuto,
      );

      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: transcriptEn,
      );

      final resultAuto = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
      );
      final resultEn = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );

      expect(resultAuto, isNotNull);
      expect(resultEn, isNotNull);
      expect(resultAuto!.language, equals('detected'));
      expect(resultEn!.language, equals('en'));
    });

    test('clearAll empties the cache', () async {
      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: _makeTranscript(),
      );

      // Verify it was stored
      final before = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );
      expect(before, isNotNull);

      await cache.clearAll();

      final after = await cache.lookup(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
      );
      expect(after, isNull);
    });

    test('cacheSize returns 0 for empty cache', () async {
      final size = await cache.cacheSize();
      expect(size, equals(0));
    });

    test('cacheSize increases after storing a transcript', () async {
      await cache.store(
        audioPath: tempAudioFile.path,
        modelId: 'whisper-base',
        language: 'en',
        transcript: _makeTranscript(),
      );

      final size = await cache.cacheSize();
      expect(size, greaterThan(0));
    });
  });
}
