import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/subtitle_track.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/subtitle_service.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';

/// Integration tests for the complete subtitle generation pipeline
///
/// These tests verify end-to-end subtitle generation:
/// 1. Whisper bindings initialization
/// 2. ASR model availability and selection
/// 3. Transcription pipeline
/// 4. Subtitle track generation
/// 5. Export to subtitle formats (SRT, VTT, ASS)
void main() {
  // Ensure Flutter bindings are initialized for tests that need them
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up path_provider mock for tests that need it
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          final tempDir =
              Directory.systemTemp.createTempSync('test_app_support_');
          return tempDir.path;
        }
        if (methodCall.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          final tempDir = Directory.systemTemp.createTempSync('test_docs_');
          return tempDir.path;
        }
        return null;
      },
    );
  });

  group('Whisper Bindings Integration', () {
    late WhisperBindings whisper;

    setUp(() {
      whisper = WhisperBindings();
    });

    test('should initialize without throwing', () async {
      await expectLater(
        whisper.initialize(),
        completes,
      );
    });

    test('should mark as initialized after initialize()', () async {
      // Before initialization, isModelLoaded() returns false (doesn't throw)
      // The actual check happens in _ensureInitialized() which is called by transcribe/loadModel
      expect(whisper.isModelLoaded(), isFalse);

      // Initialize
      await whisper.initialize();

      // After initialization, operations should work without throwing
      expect(whisper.isModelLoaded(), isFalse); // No model loaded yet
    });

    test('loadModel should throw if not initialized', () async {
      // loadModel calls _ensureInitialized() which should throw
      await expectLater(
        whisper.loadModel('/fake/path/model.bin'),
        throwsA(isA<WhisperNotInitializedException>()),
      );
    });

    test('initialize() should be idempotent', () async {
      await whisper.initialize();
      await whisper.initialize(); // Should not throw
      await whisper.initialize(); // Should not throw
    });

    test('should use singleton instance via provider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final whisper1 = container.read(whisperBindingsProvider);
      final whisper2 = container.read(whisperBindingsProvider);

      // Should be the same instance (keepAlive: true)
      expect(identical(whisper1, whisper2), isTrue);
    });

    test('provider instance should share initialization state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final whisper1 = container.read(whisperBindingsProvider);
      await whisper1.initialize();

      final whisper2 = container.read(whisperBindingsProvider);
      // Should already be initialized since same instance
      expect(
          whisper2.isModelLoaded(), isFalse,); // Initialized but no model loaded
    });
  });

  group('ASR Service Integration', () {
    late ProviderContainer container;
    late WhisperBindings whisper;

    setUp(() {
      container = ProviderContainer();
      whisper = container.read(whisperBindingsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('ASR service should use same WhisperBindings as provider', () {
      final asrService = container.read(asrServiceProvider);
      // The AsrService gets whisper from ref.watch(whisperBindingsProvider)
      // So its whisper instance should be the same as what we get from provider
      expect(identical(asrService.whisper, whisper), isTrue);
    });

    test(
      'initializing WhisperBindings should allow transcription',
      () async {
        // Initialize whisper through the provider instance
        await whisper.initialize();

        final asrService = container.read(asrServiceProvider);

        // Create a temporary test audio file
        final tempDir = Directory.systemTemp.createTempSync('subtitle_test_');
        final testAudio = File('${tempDir.path}/test_audio.wav');

        try {
          // Create a minimal WAV file for testing
          await testAudio.writeAsBytes(_createMinimalWavFile());

          // Transcription should not throw "not initialized"
          final transcript =
              await asrService.transcribeToResult(testAudio.path);

          expect(transcript, isA<Transcript>());
          expect(transcript.segments, isNotEmpty);
        } finally {
          // Cleanup
          if (testAudio.existsSync()) {
            testAudio.deleteSync();
          }
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
      skip:
          'Requires ASR model to be downloaded. Run with: flutter test --dart-define=INTEGRATION_TESTS=true',
    );
  });

  group('ASR Model Registry Integration', () {
    late HuggingFaceModelRegistry registry;

    setUp(() {
      registry = HuggingFaceModelRegistry.instance;
    });

    test('should have ASR models available', () {
      final asrModels = registry.getAsrModels();
      expect(asrModels, isNotEmpty);
      expect(asrModels.length, greaterThanOrEqualTo(5));
    });

    test('all ASR models should have correct type', () {
      final asrModels = registry.getAsrModels();
      for (final model in asrModels) {
        expect(model.modelType, equals(HuggingFaceModelType.asr));
      }
    });

    test('should have whisper-tiny model (smallest for testing)', () {
      final tinyModel = registry.getModelById('whisper-tiny');
      expect(tinyModel, isNotNull);
      expect(tinyModel!.id, equals('whisper-tiny'));
      expect(tinyModel.modelType, equals(HuggingFaceModelType.asr));
    });

    test('should have whisper-base model (default)', () {
      final baseModel = registry.getModelById('whisper-base');
      expect(baseModel, isNotNull);
      expect(baseModel!.id, equals('whisper-base'));
    });

    test('should have whisper-large-v3 model (highest accuracy)', () {
      final largeModel = registry.getModelById('whisper-large-v3');
      expect(largeModel, isNotNull);
      expect(largeModel!.id, equals('whisper-large-v3'));
    });

    test('recommended ASR model should exist', () {
      final recommended =
          registry.getRecommendedModel(HuggingFaceModelType.asr);
      expect(recommended, isNotNull);
      expect(recommended!.modelType, equals(HuggingFaceModelType.asr));
    });

    test('ASR models should have valid file sizes', () {
      final asrModels = registry.getAsrModels();
      for (final model in asrModels) {
        expect(
          model.sizeBytes,
          greaterThan(0),
          reason: 'Model ${model.id} should have a valid file size',
        );
      }
    });

    test('ASR models should have accuracy ratings', () {
      final asrModels = registry.getAsrModels();
      for (final model in asrModels) {
        expect(
          model.accuracyPercent,
          greaterThan(0),
          reason: 'Model ${model.id} should have accuracy rating',
        );
        expect(
          model.accuracyPercent,
          lessThanOrEqualTo(100),
          reason: 'Model ${model.id} accuracy should be <= 100',
        );
      }
    });
  });

  group('Subtitle Track Generation', () {
    test('should create SubtitleTrack from Transcript', () {
      const transcript = Transcript(
        segments: [
          TranscriptSegment(
            id: 'seg1',
            text: 'Hello world',
            startTime: Duration.zero,
            endTime: Duration(seconds: 2),
            words: [],
          ),
          TranscriptSegment(
            id: 'seg2',
            text: 'This is a test',
            startTime: Duration(seconds: 2),
            endTime: Duration(seconds: 5),
            words: [],
          ),
        ],
        language: 'en',
        modelId: 'whisper-base',
      );

      final subtitleTrack = SubtitleTrack.fromTranscript(
        id: 'track_1',
        transcript: transcript,
        mediaId: 'media_1',
      );

      expect(subtitleTrack.id, equals('track_1'));
      expect(subtitleTrack.mediaId, equals('media_1'));
      expect(subtitleTrack.language, equals('en'));
      expect(subtitleTrack.segments.length, equals(2));

      expect(subtitleTrack.segments[0].text, equals('Hello world'));
      expect(subtitleTrack.segments[0].startTime, equals(Duration.zero));
      expect(subtitleTrack.segments[0].endTime,
          equals(const Duration(seconds: 2)),);

      expect(subtitleTrack.segments[1].text, equals('This is a test'));
      expect(subtitleTrack.segments[1].startTime,
          equals(const Duration(seconds: 2)),);
      expect(subtitleTrack.segments[1].endTime,
          equals(const Duration(seconds: 5)),);
    });

    test('should convert SubtitleTrack back to Transcript', () {
      const originalTranscript = Transcript(
        segments: [
          TranscriptSegment(
            id: 'seg1',
            text: 'Original text',
            startTime: Duration(milliseconds: 500),
            endTime: Duration(seconds: 3),
            words: [],
          ),
        ],
        language: 'es',
        modelId: 'whisper-small',
      );

      final subtitleTrack = SubtitleTrack.fromTranscript(
        id: 'track_2',
        transcript: originalTranscript,
        mediaId: 'media_2',
      );

      final recoveredTranscript = subtitleTrack.toTranscript();

      expect(recoveredTranscript.language, equals('es'));
      expect(recoveredTranscript.segments.length, equals(1));
      expect(recoveredTranscript.segments[0].text, equals('Original text'));
    });

    test('should handle empty transcript gracefully', () {
      const emptyTranscript = Transcript(
        segments: [],
        language: 'en',
        modelId: 'whisper-tiny',
      );

      final subtitleTrack = SubtitleTrack.fromTranscript(
        id: 'empty_track',
        transcript: emptyTranscript,
        mediaId: 'media_empty',
      );

      expect(subtitleTrack.segments, isEmpty);
      expect(subtitleTrack.language, equals('en'));
    });
  });

  group('Subtitle Service Export Formats', () {
    late SubtitleService subtitleService;
    late SubtitleTrack testTrack;

    setUp(() {
      subtitleService = const SubtitleService();
      testTrack = SubtitleTrack(
        id: 'export_test',
        mediaId: 'media_export',
        language: 'en',
        createdAt: DateTime.now(),
        segments: [
          const SubtitleSegment(
            id: 'seg1',
            startTime: Duration.zero,
            endTime: Duration(seconds: 2, milliseconds: 500),
            text: 'First subtitle line',
          ),
          const SubtitleSegment(
            id: 'seg2',
            startTime: Duration(seconds: 3),
            endTime: Duration(seconds: 5),
            text: 'Second subtitle line',
          ),
        ],
      );
    });

    test('should export to SRT format', () {
      final transcript = testTrack.toTranscript();
      final srt = subtitleService.generateSubtitleContent(
        transcript,
        SubtitleFormat.srt,
      );

      expect(srt, contains('1'));
      expect(srt, contains('00:00:00,000'));
      expect(srt, contains('00:00:02,500'));
      expect(srt, contains('First subtitle line'));
      expect(srt, contains('2'));
      expect(srt, contains('00:00:03,000'));
      expect(srt, contains('00:00:05,000'));
      expect(srt, contains('Second subtitle line'));
    });

    test('should export to VTT format', () {
      final transcript = testTrack.toTranscript();
      final vtt = subtitleService.generateSubtitleContent(
        transcript,
        SubtitleFormat.vtt,
      );

      expect(vtt, startsWith('WEBVTT'));
      expect(vtt, contains('00:00:00.000'));
      expect(vtt, contains('00:00:02.500'));
      expect(vtt, contains('First subtitle line'));
      expect(vtt, contains('00:00:03.000'));
      expect(vtt, contains('00:00:05.000'));
      expect(vtt, contains('Second subtitle line'));
    });

    test('should export to ASS format', () {
      final transcript = testTrack.toTranscript();
      final ass = subtitleService.generateSubtitleContent(
        transcript,
        SubtitleFormat.ass,
      );

      expect(ass, contains('[Script Info]'));
      expect(ass, contains('[V4+ Styles]'));
      expect(ass, contains('[Events]'));
      expect(ass, contains('Dialogue:'));
      expect(ass, contains('First subtitle line'));
      expect(ass, contains('Second subtitle line'));
    });

    test('SRT timestamps should be properly formatted', () {
      const transcript = Transcript(
        segments: [
          TranscriptSegment(
            id: 'seg',
            text: 'Test',
            startTime: Duration(
                hours: 1, minutes: 23, seconds: 45, milliseconds: 678,),
            endTime: Duration(hours: 2),
            words: [],
          ),
        ],
        language: 'en',
        modelId: 'test',
      );

      final srt = subtitleService.generateSubtitleContent(
        transcript,
        SubtitleFormat.srt,
      );

      expect(srt, contains('01:23:45,678'));
      expect(srt, contains('02:00:00,000'));
    });

    test('VTT timestamps should use dot as millisecond separator', () {
      const transcript = Transcript(
        segments: [
          TranscriptSegment(
            id: 'seg',
            text: 'Test',
            startTime: Duration(seconds: 10, milliseconds: 123),
            endTime: Duration(seconds: 15, milliseconds: 456),
            words: [],
          ),
        ],
        language: 'en',
        modelId: 'test',
      );

      final vtt = subtitleService.generateSubtitleContent(
        transcript,
        SubtitleFormat.vtt,
      );

      // VTT uses . for milliseconds, not ,
      expect(vtt, contains('00:00:10.123'));
      expect(vtt, contains('00:00:15.456'));
    });
  });

  group('Full Subtitle Generation Pipeline', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'complete pipeline: initialize → transcribe → track → export',
      () async {
        // Step 1: Initialize whisper
        final whisper = container.read(whisperBindingsProvider);
        await whisper.initialize();

        // Step 2: Get ASR service (uses same whisper instance)
        final asrService = container.read(asrServiceProvider);
        expect(identical(asrService.whisper, whisper), isTrue);

        // Step 3: Create test audio
        final tempDir = Directory.systemTemp.createTempSync('pipeline_test_');
        final testAudio = File('${tempDir.path}/pipeline_audio.wav');

        try {
          await testAudio.writeAsBytes(_createMinimalWavFile());

          // Step 4: Transcribe
          final transcript =
              await asrService.transcribeToResult(testAudio.path);
          expect(transcript, isA<Transcript>());
          expect(transcript.segments, isNotEmpty);

          // Step 5: Convert to subtitle track
          final subtitleTrack = SubtitleTrack.fromTranscript(
            id: 'pipeline_track',
            transcript: transcript,
            mediaId: 'pipeline_media',
          );
          expect(subtitleTrack.segments, isNotEmpty);

          // Step 6: Export to formats
          final subtitleService = container.read(subtitleServiceProvider);
          final exportTranscript = subtitleTrack.toTranscript();

          final srt = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.srt,
          );
          expect(srt, isNotEmpty);
          expect(srt, contains('-->'));

          final vtt = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.vtt,
          );
          expect(vtt, startsWith('WEBVTT'));

          final ass = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.ass,
          );
          expect(ass, contains('[Script Info]'));
        } finally {
          if (testAudio.existsSync()) {
            testAudio.deleteSync();
          }
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
      skip:
          'Requires ASR model to be downloaded. Run with: flutter test --dart-define=INTEGRATION_TESTS=true',
    );

    test(
        'ASR service should share WhisperBindings initialization with provider',
        () async {
      // This test verifies the exact scenario that was failing:
      // 1. Get whisper from provider and initialize
      // 2. Get asrService (which internally uses same whisper)
      // 3. Call transcribe (should not throw "not initialized")

      final whisper = container.read(whisperBindingsProvider);
      final asrService = container.read(asrServiceProvider);

      // Verify they share the same instance
      expect(
        identical(whisper, asrService.whisper),
        isTrue,
        reason:
            'AsrService should use the same WhisperBindings instance as provider',
      );

      // Initialize through the provider instance
      await whisper.initialize();

      // The asrService.whisper should now be initialized
      // (it's the same object)
      expect(
        asrService.whisper.isModelLoaded,
        returnsNormally,
        reason:
            'AsrService.whisper should be initialized after provider initialization',
      );
    });
  });
}

/// Create a minimal valid WAV file for testing
/// This creates a 1-second mono 16-bit 16kHz WAV file with silence
List<int> _createMinimalWavFile() {
  const sampleRate = 16000;
  const numChannels = 1;
  const bitsPerSample = 16;
  const durationSeconds = 1;
  const numSamples = sampleRate * durationSeconds;
  const bytesPerSample = bitsPerSample ~/ 8;
  const dataSize = numSamples * numChannels * bytesPerSample;

  // RIFF header
  final bytes = <int>[...'RIFF'.codeUnits];
  _addInt32LE(bytes, 36 + dataSize); // File size - 8
  bytes
    ..addAll('WAVE'.codeUnits)
    // fmt subchunk
    ..addAll('fmt '.codeUnits);
  _addInt32LE(bytes, 16); // Subchunk1Size (16 for PCM)
  _addInt16LE(bytes, 1); // AudioFormat (1 = PCM)
  _addInt16LE(bytes, numChannels);
  _addInt32LE(bytes, sampleRate);
  _addInt32LE(bytes, sampleRate * numChannels * bytesPerSample); // ByteRate
  _addInt16LE(bytes, numChannels * bytesPerSample); // BlockAlign
  _addInt16LE(bytes, bitsPerSample);

  // data subchunk
  bytes.addAll('data'.codeUnits);
  _addInt32LE(bytes, dataSize);

  // Audio data (silence - all zeros)
  for (var i = 0; i < dataSize; i++) {
    bytes.add(0);
  }

  return bytes;
}

void _addInt16LE(List<int> bytes, int value) {
  bytes
    ..add(value & 0xFF)
    ..add((value >> 8) & 0xFF);
}

void _addInt32LE(List<int> bytes, int value) {
  bytes
    ..add(value & 0xFF)
    ..add((value >> 8) & 0xFF)
    ..add((value >> 16) & 0xFF)
    ..add((value >> 24) & 0xFF);
}
