import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/transcription_isolate.dart';

void main() {
  group('TranscriptionIsolateParams', () {
    group('creation with defaults', () {
      test('should have correct default values', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
        );

        expect(params.libraryPath, equals('/lib/whisper.dll'));
        expect(params.audioPath, equals('/tmp/audio.wav'));
        expect(params.modelPath, equals('/models/base.bin'));
        expect(params.language, isNull);
        expect(params.translateToEnglish, isFalse);
        expect(params.useGpu, isTrue);
        expect(params.nThreads, equals(0));
        expect(params.beamSize, equals(5));
      });

      test('should allow custom values to override defaults', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          language: 'en',
          translateToEnglish: true,
          useGpu: false,
          nThreads: 8,
          beamSize: 3,
        );

        expect(params.language, equals('en'));
        expect(params.translateToEnglish, isTrue);
        expect(params.useGpu, isFalse);
        expect(params.nThreads, equals(8));
        expect(params.beamSize, equals(3));
      });
    });

    group('settings propagation', () {
      test('should persist GPU-off setting', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          useGpu: false,
        );

        expect(params.useGpu, isFalse);
      });

      test('should persist high thread count', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          nThreads: 16,
        );

        expect(params.nThreads, equals(16));
      });

      test('should persist custom beam size', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          beamSize: 8,
        );

        expect(params.beamSize, equals(8));
      });
    });

    group('thread count validation', () {
      test('nThreads=0 represents auto-detect', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          nThreads: 0,
        );

        expect(params.nThreads, equals(0));
      });

      test('nThreads=1 is valid minimum', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          nThreads: 1,
        );

        expect(params.nThreads, equals(1));
      });

      test('nThreads=16 is valid maximum from ceiling', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          nThreads: 16,
        );

        expect(params.nThreads, equals(16));
      });
    });

    group('beam size', () {
      test('beam size 1 can be set', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          beamSize: 1,
        );

        expect(params.beamSize, equals(1));
      });

      test('beam size 3 can be set', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          beamSize: 3,
        );

        expect(params.beamSize, equals(3));
      });

      test('beam size 5 can be set', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          beamSize: 5,
        );

        expect(params.beamSize, equals(5));
      });

      test('beam size 8 can be set', () {
        const params = TranscriptionIsolateParams(
          libraryPath: '/lib/whisper.dll',
          audioPath: '/tmp/audio.wav',
          modelPath: '/models/base.bin',
          beamSize: 8,
        );

        expect(params.beamSize, equals(8));
      });
    });
  });

  group('AsrService.adaptiveBeamSize', () {
    test('returns 2 for tiny models', () {
      expect(AsrService.adaptiveBeamSize('whisper-tiny'), equals(2));
      expect(AsrService.adaptiveBeamSize('whisper-tiny.en'), equals(2));
    });

    test('returns 3 for base models', () {
      expect(AsrService.adaptiveBeamSize('whisper-base'), equals(3));
      expect(AsrService.adaptiveBeamSize('whisper-base.en'), equals(3));
    });

    test('returns 4 for small models', () {
      expect(AsrService.adaptiveBeamSize('whisper-small'), equals(4));
    });

    test('returns 5 for medium models', () {
      expect(AsrService.adaptiveBeamSize('whisper-medium'), equals(5));
    });

    test('returns 5 for large models', () {
      expect(AsrService.adaptiveBeamSize('whisper-large-v3'), equals(5));
      expect(AsrService.adaptiveBeamSize('whisper-large-v2'), equals(5));
    });

    test('returns 5 for unknown models', () {
      expect(AsrService.adaptiveBeamSize('custom-model'), equals(5));
    });
  });
}
