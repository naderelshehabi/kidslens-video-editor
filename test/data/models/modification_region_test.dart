import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';

void main() {
  group('RegionBounds', () {
    test('should create with all fields', () {
      const bounds = RegionBounds(
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );

      expect(bounds.x, equals(0.1));
      expect(bounds.y, equals(0.2));
      expect(bounds.width, equals(0.3));
      expect(bounds.height, equals(0.4));
    });

    test('should serialize and deserialize via JSON', () {
      const original = RegionBounds(
        x: 0.15,
        y: 0.25,
        width: 0.5,
        height: 0.35,
      );

      final jsonString = jsonEncode(original.toJson());
      final restored = RegionBounds.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.width, equals(original.width));
      expect(restored.height, equals(original.height));
    });
  });

  group('VideoRegionBlur', () {
    test('should create with required region and default intensity', () {
      const mod = VideoRegionBlur(
        region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
      );

      expect(mod.intensity, equals(50));
      expect(mod.region.x, equals(0.1));
    });

    test('should create with custom intensity', () {
      const mod = VideoRegionBlur(
        intensity: 80,
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.intensity, equals(80));
    });

    test('should be a video modification', () {
      const mod = VideoRegionBlur(
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.isVideoModification, isTrue);
      expect(mod.isAudioModification, isFalse);
      expect(mod.isDestructive, isFalse);
      expect(mod.isRegionModification, isTrue);
    });

    test('should have correct display name', () {
      const mod = VideoRegionBlur(
        intensity: 75,
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.displayName, equals('Region Blur (75%)'));
      expect(mod.shortCode, equals('RBLUR'));
      expect(mod.iconName, equals('blur_on'));
    });

    test('should return empty FFmpeg filter', () {
      const mod = VideoRegionBlur(
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.toFFmpegFilter(), equals(''));
    });

    test('should serialize and deserialize via JSON', () {
      const original = VideoRegionBlur(
        intensity: 60,
        region: RegionBounds(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
      );

      final json = original.toJson();
      final jsonString = jsonEncode(json);
      final restored = Modification.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored, isA<VideoRegionBlur>());
      final blur = restored as VideoRegionBlur;
      expect(blur.intensity, equals(60));
      expect(blur.region.x, equals(0.2));
      expect(blur.region.y, equals(0.3));
      expect(blur.region.width, equals(0.4));
      expect(blur.region.height, equals(0.5));
    });
  });

  group('VideoRegionPixelate', () {
    test('should create with defaults', () {
      const mod = VideoRegionPixelate(
        region: RegionBounds(x: 0.1, y: 0.1, width: 0.5, height: 0.5),
      );

      expect(mod.blockSize, equals(10));
      expect(mod.isRegionModification, isTrue);
    });

    test('should have correct display name', () {
      const mod = VideoRegionPixelate(
        blockSize: 20,
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.displayName, equals('Region Pixelate (20px)'));
      expect(mod.shortCode, equals('RPIXEL'));
    });

    test('should not be destructive', () {
      const mod = VideoRegionPixelate(
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.isDestructive, isFalse);
    });

    test('should serialize and deserialize via JSON', () {
      const original = VideoRegionPixelate(
        blockSize: 16,
        region: RegionBounds(x: 0.3, y: 0.4, width: 0.2, height: 0.1),
      );

      final json = original.toJson();
      final jsonString = jsonEncode(json);
      final restored = Modification.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored, isA<VideoRegionPixelate>());
      final pix = restored as VideoRegionPixelate;
      expect(pix.blockSize, equals(16));
      expect(pix.region.x, equals(0.3));
    });
  });

  group('VideoRegionBlackBox', () {
    test('should create with defaults', () {
      const mod = VideoRegionBlackBox(
        region: RegionBounds(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
      );

      expect(mod.color, equals('#000000'));
      expect(mod.opacity, equals(1.0));
      expect(mod.isRegionModification, isTrue);
    });

    test('should have correct display name', () {
      const mod = VideoRegionBlackBox(
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.displayName, equals('Region Black Box'));
      expect(mod.shortCode, equals('RBBOX'));
      expect(mod.iconName, equals('crop_square'));
    });

    test('should not be destructive', () {
      const mod = VideoRegionBlackBox(
        region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
      );

      expect(mod.isDestructive, isFalse);
    });

    test('should serialize and deserialize via JSON', () {
      const original = VideoRegionBlackBox(
        color: '#FF0000',
        opacity: 0.8,
        region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
      );

      final json = original.toJson();
      final jsonString = jsonEncode(json);
      final restored = Modification.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored, isA<VideoRegionBlackBox>());
      final bbox = restored as VideoRegionBlackBox;
      expect(bbox.color, equals('#FF0000'));
      expect(bbox.opacity, equals(0.8));
    });
  });

  group('ModificationListExtensions with region mods', () {
    test('should classify region mods as video modifications', () {
      final mods = <Modification>[
        const AudioMute(),
        const VideoRegionBlur(
          region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
        ),
        const VideoRegionPixelate(
          region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
        ),
        const VideoRegionBlackBox(
          region: RegionBounds(x: 0, y: 0, width: 1, height: 1),
        ),
      ];

      expect(mods.videoModifications, hasLength(3));
      expect(mods.audioModifications, hasLength(1));
      expect(mods.destructiveModifications, hasLength(1)); // Only AudioMute
    });
  });

  group('pattern matching', () {
    test('should match region modifications in switch', () {
      const mod = VideoRegionBlur(
        region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
      );

      final result = switch (mod as Modification) {
        VideoRegionBlur(:final intensity, :final region) =>
          'blur:$intensity:${region.x}',
        _ => 'other',
      };

      expect(result, equals('blur:50:0.1'));
    });
  });
}
