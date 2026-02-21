import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';

void main() {
  group('Modification sealed class', () {
    group('AudioMute', () {
      test('should create an AudioMute modification', () {
        const mod = AudioMute();

        expect(mod.isAudioModification, isTrue);
        expect(mod.isVideoModification, isFalse);
        expect(mod.isDestructive, isTrue);
        expect(mod.displayName, equals('Mute Audio'));
        expect(mod.shortCode, equals('MUTE'));
        expect(mod.iconName, equals('volume_off'));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = AudioMute();
        expect(mod.toFFmpegFilter(), equals('volume=0'));
      });
    });

    group('AudioBeep', () {
      test('should create an AudioBeep with defaults', () {
        const mod = AudioBeep();

        expect(mod.frequency, equals(1000));
        expect(mod.volume, equals(0.5));
        expect(mod.isAudioModification, isTrue);
        expect(mod.isVideoModification, isFalse);
        expect(mod.isDestructive, isFalse);
        expect(mod.displayName, equals('Beep (1000Hz)'));
        expect(mod.shortCode, equals('BEEP'));
        expect(mod.iconName, equals('music_note'));
      });

      test('should create an AudioBeep with custom parameters', () {
        const mod = AudioBeep(frequency: 440, volume: 0.8);

        expect(mod.frequency, equals(440));
        expect(mod.volume, equals(0.8));
        expect(mod.displayName, equals('Beep (440Hz)'));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = AudioBeep(frequency: 500, volume: 0.7);
        expect(
          mod.toFFmpegFilter(),
          equals('sine=frequency=500:sample_rate=44100,volume=0.7'),
        );
      });
    });

    group('AudioReplace', () {
      test('should create an AudioReplace modification', () {
        const mod = AudioReplace(audioPath: '/path/to/beep.wav');

        expect(mod.audioPath, equals('/path/to/beep.wav'));
        expect(mod.volume, equals(1.0));
        expect(mod.loop, isFalse);
        expect(mod.isAudioModification, isTrue);
        expect(mod.isDestructive, isFalse);
        expect(mod.displayName, equals('Replace Audio'));
        expect(mod.shortCode, equals('REPLACE'));
        expect(mod.iconName, equals('swap_horiz'));
      });

      test('should create with custom options', () {
        const mod = AudioReplace(
          audioPath: '/path/to/audio.mp3',
          volume: 0.8,
          loop: true,
        );

        expect(mod.volume, equals(0.8));
        expect(mod.loop, isTrue);
      });

      test('should generate correct FFmpeg filter', () {
        const mod = AudioReplace(audioPath: '/audio.wav', volume: 0.9);
        expect(
          mod.toFFmpegFilter(),
          equals('amovie=/audio.wav,volume=0.9'),
        );
      });
    });

    group('VideoBlur', () {
      test('should create a VideoBlur with default intensity', () {
        const mod = VideoBlur();

        expect(mod.intensity, equals(20));
        expect(mod.isVideoModification, isTrue);
        expect(mod.isAudioModification, isFalse);
        expect(mod.isDestructive, isFalse);
        expect(mod.displayName, equals('Blur (20%)'));
        expect(mod.shortCode, equals('BLUR'));
        expect(mod.iconName, equals('blur_on'));
      });

      test('should create with custom intensity', () {
        const mod = VideoBlur(intensity: 50);

        expect(mod.intensity, equals(50));
        expect(mod.displayName, equals('Blur (50%)'));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = VideoBlur(intensity: 30);
        expect(mod.toFFmpegFilter(), equals('boxblur=6:6'));
      });
    });

    group('VideoPixelate', () {
      test('should create a VideoPixelate with default block size', () {
        const mod = VideoPixelate();

        expect(mod.blockSize, equals(16));
        expect(mod.isVideoModification, isTrue);
        expect(mod.isDestructive, isFalse);
        expect(mod.displayName, equals('Pixelate (16px)'));
        expect(mod.shortCode, equals('PIXEL'));
        expect(mod.iconName, equals('grid_on'));
      });

      test('should create with custom block size', () {
        const mod = VideoPixelate(blockSize: 32);

        expect(mod.blockSize, equals(32));
        expect(mod.displayName, equals('Pixelate (32px)'));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = VideoPixelate(blockSize: 8);
        expect(
          mod.toFFmpegFilter(),
          equals('scale=iw/8:ih/8,scale=iw*8:ih*8:flags=neighbor'),
        );
      });
    });

    group('VideoBlackBox', () {
      test('should create a VideoBlackBox with defaults', () {
        const mod = VideoBlackBox();

        expect(mod.color, equals('#000000'));
        expect(mod.opacity, equals(1.0));
        expect(mod.isVideoModification, isTrue);
        expect(mod.isDestructive, isFalse);
        expect(mod.displayName, equals('Black Box'));
        expect(mod.shortCode, equals('BBOX'));
        expect(mod.iconName, equals('crop_square'));
      });

      test('should create with custom color and opacity', () {
        const mod = VideoBlackBox(color: '#FF0000', opacity: 0.8);

        expect(mod.color, equals('#FF0000'));
        expect(mod.opacity, equals(0.8));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = VideoBlackBox(color: '#FFFFFF', opacity: 0.5);
        expect(
          mod.toFFmpegFilter(),
          equals('drawbox=color=FFFFFF@0.5:t=fill'),
        );
      });
    });

    group('VideoSkip', () {
      test('should create a VideoSkip modification', () {
        const mod = VideoSkip();

        expect(mod.isVideoModification, isTrue);
        expect(mod.isAudioModification, isFalse);
        expect(mod.isDestructive, isTrue);
        expect(mod.displayName, equals('Skip/Cut'));
        expect(mod.shortCode, equals('SKIP'));
        expect(mod.iconName, equals('content_cut'));
      });

      test('should generate correct FFmpeg filter', () {
        const mod = VideoSkip();
        expect(mod.toFFmpegFilter(), equals('select=0'));
      });
    });

    group('pattern matching', () {
      test('should work with switch expressions', () {
        final modifications = <Modification>[
          const AudioMute(),
          const AudioBeep(),
          const AudioReplace(audioPath: '/test.wav'),
          const VideoBlur(),
          const VideoPixelate(),
          const VideoBlackBox(),
          const VideoSkip(),
          const Modification.videoRegionBlur(region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4)),
          const Modification.videoRegionPixelate(region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4)),
          const Modification.videoRegionBlackBox(region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4)),
        ];

        final results = modifications.map((mod) => switch (mod) {
            AudioMute() => 'mute',
            AudioBeep() => 'beep',
            AudioReplace() => 'replace',
            VideoBlur() => 'blur',
            VideoPixelate() => 'pixelate',
            VideoBlackBox() => 'blackbox',
            VideoSkip() => 'skip',
            VideoRegionBlur() => 'regionblur',
            VideoRegionPixelate() => 'regionpixelate',
            VideoRegionBlackBox() => 'regionblackbox',
          },).toList();

        expect(results, equals([
          'mute',
          'beep',
          'replace',
          'blur',
          'pixelate',
          'blackbox',
          'skip',
          'regionblur',
          'regionpixelate',
          'regionblackbox',
        ]),);
      });

      test('should extract values in pattern matching', () {
        const mod = AudioBeep(frequency: 880, volume: 0.6);

        final result = switch (mod) {
          AudioBeep(:final frequency, :final volume) =>
            'freq=$frequency, vol=$volume',
        };

        expect(result, equals('freq=880, vol=0.6'));
      });
    });

    group('JSON serialization', () {
      test('should serialize AudioMute to JSON', () {
        const mod = AudioMute();
        final json = mod.toJson();

        expect(json['runtimeType'], equals('audioMute'));
      });

      test('should serialize AudioBeep to JSON', () {
        const mod = AudioBeep(frequency: 500, volume: 0.7);
        final json = mod.toJson();

        expect(json['runtimeType'], equals('audioBeep'));
        expect(json['frequency'], equals(500));
        expect(json['volume'], equals(0.7));
      });

      test('should serialize VideoBlur to JSON', () {
        const mod = VideoBlur(intensity: 40);
        final json = mod.toJson();

        expect(json['runtimeType'], equals('videoBlur'));
        expect(json['intensity'], equals(40));
      });

      test('should deserialize AudioMute from JSON', () {
        final json = {'runtimeType': 'audioMute'};
        final mod = Modification.fromJson(json);

        expect(mod, isA<AudioMute>());
      });

      test('should deserialize AudioBeep from JSON', () {
        final json = {
          'runtimeType': 'audioBeep',
          'frequency': 800,
          'volume': 0.9,
        };
        final mod = Modification.fromJson(json);

        expect(mod, isA<AudioBeep>());
        expect((mod as AudioBeep).frequency, equals(800));
        expect(mod.volume, equals(0.9));
      });

      test('should deserialize VideoPixelate from JSON', () {
        final json = {
          'runtimeType': 'videoPixelate',
          'blockSize': 24,
        };
        final mod = Modification.fromJson(json);

        expect(mod, isA<VideoPixelate>());
        expect((mod as VideoPixelate).blockSize, equals(24));
      });

      test('should round-trip through JSON correctly', () {
        const original = AudioReplace(
          audioPath: '/path/to/audio.mp3',
          volume: 0.85,
          loop: true,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = Modification.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored, isA<AudioReplace>());
        final restoredReplace = restored as AudioReplace;
        expect(restoredReplace.audioPath, equals(original.audioPath));
        expect(restoredReplace.volume, equals(original.volume));
        expect(restoredReplace.loop, equals(original.loop));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const mod1 = AudioBeep();
        const mod2 = AudioBeep();

        expect(mod1, equals(mod2));
        expect(mod1.hashCode, equals(mod2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const mod1 = AudioBeep();
        const mod2 = AudioBeep(frequency: 500);

        expect(mod1, isNot(equals(mod2)));
      });

      test('should not be equal between different types', () {
        const mod1 = AudioMute();
        const mod2 = VideoSkip();

        expect(mod1, isNot(equals(mod2)));
      });
    });

    group('copyWith', () {
      test('should copy AudioBeep with modified fields', () {
        const original = AudioBeep();
        final copy = original.copyWith(frequency: 2000);

        expect(copy.frequency, equals(2000));
        expect(copy.volume, equals(0.5));
      });

      test('should copy VideoBlur with modified intensity', () {
        const original = VideoBlur();
        final copy = original.copyWith(intensity: 60);

        expect(copy.intensity, equals(60));
      });

      test('should copy VideoBlackBox with modified fields', () {
        const original = VideoBlackBox();
        final copy = original.copyWith(color: '#FF0000', opacity: 0.5);

        expect(copy.color, equals('#FF0000'));
        expect(copy.opacity, equals(0.5));
      });
    });
  });
}
