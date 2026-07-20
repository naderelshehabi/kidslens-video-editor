// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/subtitle_track.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/subtitle_service.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';

/// Full end-to-end integration tests for subtitle generation
///
/// These tests require actual model downloads and should only be run:
/// - In CI/CD environments with sufficient resources
/// - Manually during development when testing model integration
///
/// To run these tests:
/// ```bash
/// flutter test test/integration/subtitle_generation_e2e_test.dart
/// ```
///
/// WARNING: These tests will:
/// - Download ASR models (several hundred MB each)
/// - Take significant time to complete
/// - Require network access
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          // Use a persistent location for model downloads
          final testDir =
              Directory('${Directory.systemTemp.path}/kidslens_test_models');
          if (!testDir.existsSync()) {
            testDir.createSync(recursive: true);
          }
          return testDir.path;
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

  group('End-to-End Model Download and Transcription', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'should list all available ASR models for download',
      () {
        final registry = HuggingFaceModelRegistry.instance;
        final asrModels = registry.getAsrModels();

        print('\n=== Available ASR Models ===');
        for (final model in asrModels) {
          print('  ${model.id}:');
          print('    - Size: ${_formatBytes(model.sizeBytes)}');
          print('    - Accuracy: ${model.accuracyPercent}%');
          print(
            '    - Speed: ${model.speedDescription} (${model.speedMultiplier}x)',
          );
          print(
            '    - Languages: ${model.isMultilingual ? "99+ languages" : "English only"}',
          );
        }
        print('============================\n');

        expect(asrModels.length, greaterThanOrEqualTo(10));
      },
    );

    test(
      'full pipeline with whisper-tiny (smallest model for testing)',
      () async {
        print('\n=== Testing with whisper-tiny ===');

        // Step 1: Check if model exists
        final registry = HuggingFaceModelRegistry.instance;
        final model = registry.getModelById('whisper-tiny');
        expect(model, isNotNull);
        print(
          'Model info: ${model!.id}, size: ${_formatBytes(model.sizeBytes)}',
        );

        // Step 2: Initialize whisper bindings
        final whisper = container.read(whisperBindingsProvider);
        await whisper.initialize();
        print('Whisper initialized');

        // Step 3: Get model manager and check download status
        final modelManager = container.read(modelManagerServiceProvider);
        final downloadedModels = await modelManager.getDownloadedModels();
        print('Downloaded models: $downloadedModels');

        if (!downloadedModels.contains('whisper-tiny')) {
          print('whisper-tiny not downloaded - downloading...');
          // Download the model
          await for (final progress in modelManager.downloadModel(model.id)) {
            print(
              '  Download progress: ${(progress.percentage * 100).toStringAsFixed(1)}%',
            );
          }
          print('Download complete!');
        } else {
          print('whisper-tiny already downloaded');
        }

        // Step 4: Create test audio file
        final tempDir = Directory.systemTemp.createTempSync('e2e_test_');
        final testAudio = File('${tempDir.path}/test.wav');
        await testAudio.writeAsBytes(_createTestWavFile(durationSeconds: 3));
        print('Created test audio: ${testAudio.path}');

        try {
          // Step 5: Transcribe
          final asrService = container.read(asrServiceProvider);
          print('Starting transcription...');

          final transcript = await asrService.transcribeToResult(
            testAudio.path,
            preferredModel: 'whisper-tiny',
          );

          print('Transcription complete!');
          print('  Language: ${transcript.language}');
          print('  Segments: ${transcript.segments.length}');
          for (final segment in transcript.segments) {
            print(
              '    [${_formatDuration(segment.startTime)} - ${_formatDuration(segment.endTime)}] ${segment.text}',
            );
          }

          expect(transcript, isA<Transcript>());

          // Step 6: Convert to subtitle track
          final subtitleTrack = SubtitleTrack.fromTranscript(
            id: 'e2e_test_track',
            transcript: transcript,
            mediaId: 'test_media',
          );
          print(
            'Created subtitle track with ${subtitleTrack.segments.length} segments',
          );

          // Step 7: Export to all formats
          final subtitleService = container.read(subtitleServiceProvider);
          final exportTranscript = subtitleTrack.toTranscript();

          final srt = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.srt,
          );
          print('\n=== SRT Output ===');
          print(srt);

          final vtt = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.vtt,
          );
          print('\n=== VTT Output ===');
          print(vtt);

          final ass = subtitleService.generateSubtitleContent(
            exportTranscript,
            SubtitleFormat.ass,
          );
          print('\n=== ASS Output (first 500 chars) ===');
          print(ass.length > 500 ? '${ass.substring(0, 500)}...' : ass);

          // Verify exports
          expect(srt, contains('-->'));
          expect(vtt, startsWith('WEBVTT'));
          expect(ass, contains('[Script Info]'));

          print('\n=== whisper-tiny test PASSED ===\n');
        } finally {
          if (testAudio.existsSync()) testAudio.deleteSync();
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 10)),
      skip:
          'Run manually: flutter test test/integration/subtitle_generation_e2e_test.dart -t "whisper-tiny"',
    );

    test(
      'full pipeline with whisper-base (default model)',
      () async {
        print('\n=== Testing with whisper-base ===');

        final registry = HuggingFaceModelRegistry.instance;
        final model = registry.getModelById('whisper-base');
        expect(model, isNotNull);

        final whisper = container.read(whisperBindingsProvider);
        await whisper.initialize();

        final modelManager = container.read(modelManagerServiceProvider);
        final downloadedModels = await modelManager.getDownloadedModels();

        if (!downloadedModels.contains('whisper-base')) {
          print('Downloading whisper-base...');
          await for (final progress in modelManager.downloadModel(model!.id)) {
            print(
              '  Progress: ${(progress.percentage * 100).toStringAsFixed(1)}%',
            );
          }
        }

        final tempDir = Directory.systemTemp.createTempSync('e2e_base_');
        final testAudio = File('${tempDir.path}/test.wav');
        await testAudio.writeAsBytes(_createTestWavFile(durationSeconds: 5));

        try {
          final asrService = container.read(asrServiceProvider);
          final transcript = await asrService.transcribeToResult(
            testAudio.path,
            preferredModel: 'whisper-base',
          );

          expect(transcript, isA<Transcript>());
          print('whisper-base transcription successful');
          print('  Segments: ${transcript.segments.length}');

          final subtitleTrack = SubtitleTrack.fromTranscript(
            id: 'base_track',
            transcript: transcript,
            mediaId: 'base_media',
          );

          final subtitleService = container.read(subtitleServiceProvider);
          final srt = subtitleService.generateSubtitleContent(
            subtitleTrack.toTranscript(),
            SubtitleFormat.srt,
          );
          expect(srt, isNotEmpty);

          print('\n=== whisper-base test PASSED ===\n');
        } finally {
          if (testAudio.existsSync()) testAudio.deleteSync();
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 15)),
      skip:
          'Run manually: flutter test test/integration/subtitle_generation_e2e_test.dart -t "whisper-base"',
    );

    test(
      'verify all ASR models can be resolved',
      () {
        final registry = HuggingFaceModelRegistry.instance;

        final modelIds = [
          'whisper-tiny',
          'whisper-tiny.en',
          'whisper-base',
          'whisper-base.en',
          'whisper-small',
          'whisper-small.en',
          'whisper-medium',
          'whisper-medium.en',
          'whisper-large',
          'whisper-large-v2',
          'whisper-large-v3',
        ];

        for (final id in modelIds) {
          final model = registry.getModelById(id);
          if (model != null) {
            expect(model.modelType, equals(HuggingFaceModelType.asr));
            print('✓ $id found (${_formatBytes(model.sizeBytes)})');
          } else {
            print('✗ $id NOT FOUND');
          }
        }

        // Verify at least the main models exist
        expect(registry.getModelById('whisper-tiny'), isNotNull);
        expect(registry.getModelById('whisper-base'), isNotNull);
        expect(registry.getModelById('whisper-large-v3'), isNotNull);
      },
    );
  });
}

/// Create a test WAV file with simple audio
List<int> _createTestWavFile({int durationSeconds = 1}) {
  const sampleRate = 16000;
  const numChannels = 1;
  const bitsPerSample = 16;
  final numSamples = sampleRate * durationSeconds;
  const bytesPerSample = bitsPerSample ~/ 8;
  final dataSize = numSamples * numChannels * bytesPerSample;

  // RIFF header
  final bytes = <int>[...'RIFF'.codeUnits];
  _addInt32LE(bytes, 36 + dataSize);
  bytes
    ..addAll('WAVE'.codeUnits)
    // fmt subchunk
    ..addAll('fmt '.codeUnits);
  _addInt32LE(bytes, 16);
  _addInt16LE(bytes, 1);
  _addInt16LE(bytes, numChannels);
  _addInt32LE(bytes, sampleRate);
  _addInt32LE(bytes, sampleRate * numChannels * bytesPerSample);
  _addInt16LE(bytes, numChannels * bytesPerSample);
  _addInt16LE(bytes, bitsPerSample);

  // data subchunk
  bytes.addAll('data'.codeUnits);
  _addInt32LE(bytes, dataSize);

  // Generate simple sine wave tone (440Hz)
  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sample =
        (32767 * 0.5 * (2 * 3.14159 * 440 * t).abs().remainder(1)).toInt();
    _addInt16LE(bytes, sample);
  }

  return bytes;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final millis =
      (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
  return '$minutes:$seconds.$millis';
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
