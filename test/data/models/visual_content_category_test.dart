import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';

void main() {
  group('VisualContentAction', () {
    test('should have all expected values', () {
      expect(VisualContentAction.values, hasLength(4));
      expect(VisualContentAction.values, contains(VisualContentAction.blurRegion));
      expect(VisualContentAction.values, contains(VisualContentAction.pixelateRegion));
      expect(VisualContentAction.values, contains(VisualContentAction.blackBoxRegion));
      expect(VisualContentAction.values, contains(VisualContentAction.cutScene));
    });
  });

  group('CategoryDetectionSource', () {
    test('should have all expected values', () {
      expect(CategoryDetectionSource.values, hasLength(3));
      expect(CategoryDetectionSource.values, contains(CategoryDetectionSource.nudeNet));
      expect(CategoryDetectionSource.values, contains(CategoryDetectionSource.clip));
      expect(CategoryDetectionSource.values, contains(CategoryDetectionSource.both));
    });
  });

  group('VisualContentCategory', () {
    group('creation', () {
      test('should create with required fields and defaults', () {
        const category = VisualContentCategory(
          id: 'test_category',
          name: 'Test Category',
          description: 'A test category',
          detectionSource: CategoryDetectionSource.nudeNet,
        );

        expect(category.id, equals('test_category'));
        expect(category.name, equals('Test Category'));
        expect(category.description, equals('A test category'));
        expect(category.detectionSource, equals(CategoryDetectionSource.nudeNet));
        expect(category.enabled, isTrue);
        expect(category.threshold, equals(0.5));
        expect(category.clipThreshold, equals(3.0));
        expect(category.action, equals(VisualContentAction.blurRegion));
        expect(category.detectionLabels, isEmpty);
        expect(category.clipPrompts, isEmpty);
        expect(category.clipNegativePrompts, isEmpty);
        expect(category.iconName, isNull);
        expect(category.isBuiltIn, isTrue);
      });

      test('should create with all custom fields', () {
        const category = VisualContentCategory(
          id: 'custom',
          name: 'Custom',
          description: 'Custom category',
          detectionSource: CategoryDetectionSource.both,
          detectionLabels: ['LABEL_A', 'LABEL_B'],
          clipPrompts: ['prompt 1', 'prompt 2'],
          clipNegativePrompts: ['negative 1'],
          enabled: false,
          threshold: 0.7,
          clipThreshold: 5,
          action: VisualContentAction.cutScene,
          iconName: 'shield',
          isBuiltIn: false,
        );

        expect(category.detectionLabels, hasLength(2));
        expect(category.clipPrompts, hasLength(2));
        expect(category.clipNegativePrompts, hasLength(1));
        expect(category.enabled, isFalse);
        expect(category.threshold, equals(0.7));
        expect(category.clipThreshold, equals(5.0));
        expect(category.action, equals(VisualContentAction.cutScene));
        expect(category.isBuiltIn, isFalse);
      });
    });

    group('computed properties', () {
      test('usesNudeNet returns true for nudeNet source', () {
        const category = VisualContentCategory(
          id: 'test',
          name: 'Test',
          description: 'Test',
          detectionSource: CategoryDetectionSource.nudeNet,
        );
        expect(category.usesNudeNet, isTrue);
        expect(category.usesClip, isFalse);
      });

      test('usesClip returns true for clip source', () {
        const category = VisualContentCategory(
          id: 'test',
          name: 'Test',
          description: 'Test',
          detectionSource: CategoryDetectionSource.clip,
        );
        expect(category.usesNudeNet, isFalse);
        expect(category.usesClip, isTrue);
      });

      test('usesNudeNet and usesClip both true for both source', () {
        const category = VisualContentCategory(
          id: 'test',
          name: 'Test',
          description: 'Test',
          detectionSource: CategoryDetectionSource.both,
        );
        expect(category.usesNudeNet, isTrue);
        expect(category.usesClip, isTrue);
      });

      test('hasBoundingBoxes returns true only for nudeNet-using categories', () {
        const nudeNet = VisualContentCategory(
          id: 'a',
          name: 'A',
          description: 'A',
          detectionSource: CategoryDetectionSource.nudeNet,
        );
        const clip = VisualContentCategory(
          id: 'b',
          name: 'B',
          description: 'B',
          detectionSource: CategoryDetectionSource.clip,
        );
        const both = VisualContentCategory(
          id: 'c',
          name: 'C',
          description: 'C',
          detectionSource: CategoryDetectionSource.both,
        );

        expect(nudeNet.hasBoundingBoxes, isTrue);
        expect(clip.hasBoundingBoxes, isFalse);
        expect(both.hasBoundingBoxes, isTrue);
      });

      test('isFullFrameEffect returns true for CLIP-only non-cutScene', () {
        const clipBlur = VisualContentCategory(
          id: 'a',
          name: 'A',
          description: 'A',
          detectionSource: CategoryDetectionSource.clip,
        );
        const clipCut = VisualContentCategory(
          id: 'b',
          name: 'B',
          description: 'B',
          detectionSource: CategoryDetectionSource.clip,
          action: VisualContentAction.cutScene,
        );
        const nudeNetBlur = VisualContentCategory(
          id: 'c',
          name: 'C',
          description: 'C',
          detectionSource: CategoryDetectionSource.nudeNet,
        );

        expect(clipBlur.isFullFrameEffect, isTrue);
        expect(clipCut.isFullFrameEffect, isFalse);
        expect(nudeNetBlur.isFullFrameEffect, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with modified fields', () {
        const original = VisualContentCategory(
          id: 'test',
          name: 'Original',
          description: 'Desc',
          detectionSource: CategoryDetectionSource.nudeNet,
        );

        final copy = original.copyWith(
          name: 'Modified',
          threshold: 0.8,
          enabled: false,
        );

        expect(copy.id, equals('test'));
        expect(copy.name, equals('Modified'));
        expect(copy.threshold, equals(0.8));
        expect(copy.enabled, isFalse);
        // Original unchanged
        expect(original.name, equals('Original'));
        expect(original.threshold, equals(0.5));
        expect(original.enabled, isTrue);
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = VisualContentCategory(
          id: 'nudity',
          name: 'Nudity',
          description: 'Detects nudity',
          detectionSource: CategoryDetectionSource.nudeNet,
          detectionLabels: ['FEMALE_BREAST_EXPOSED', 'BUTTOCKS_EXPOSED'],
          threshold: 0.45,
          iconName: 'visibility_off',
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final restored = VisualContentCategory.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.description, equals(original.description));
        expect(restored.detectionSource, equals(original.detectionSource));
        expect(restored.detectionLabels, equals(original.detectionLabels));
        expect(restored.threshold, equals(original.threshold));
        expect(restored.action, equals(original.action));
        expect(restored.iconName, equals(original.iconName));
      });

      test('should deserialize unknown VisualContentAction to default', () {
        final json = {
          'id': 'test',
          'name': 'Test',
          'description': 'Test',
          'detectionSource': 'nudeNet',
          'action': 'unknownFutureAction',
          'enabled': true,
          'threshold': 0.5,
          'clipThreshold': 3.0,
          'isBuiltIn': true,
          'detectionLabels': <String>[],
          'clipPrompts': <String>[],
          'clipNegativePrompts': <String>[],
        };

        final category = VisualContentCategory.fromJson(json);
        // Should fall back to blurRegion for unknown values
        expect(category.action, equals(VisualContentAction.blurRegion));
      });

      test('should deserialize unknown CategoryDetectionSource to default', () {
        final json = {
          'id': 'test',
          'name': 'Test',
          'description': 'Test',
          'detectionSource': 'unknownFutureSource',
          'action': 'blurRegion',
          'enabled': true,
          'threshold': 0.5,
          'clipThreshold': 3.0,
          'isBuiltIn': true,
          'detectionLabels': <String>[],
          'clipPrompts': <String>[],
          'clipNegativePrompts': <String>[],
        };

        final category = VisualContentCategory.fromJson(json);
        // Should fall back to clip for unknown values
        expect(category.detectionSource, equals(CategoryDetectionSource.clip));
      });

      test('should handle CLIP-only category serialization', () {
        const original = VisualContentCategory(
          id: 'kissing',
          name: 'Kissing',
          description: 'Detects kissing',
          detectionSource: CategoryDetectionSource.clip,
          clipPrompts: ['two people kissing'],
          clipNegativePrompts: ['two people talking'],
          action: VisualContentAction.cutScene,
        );

        final restored = VisualContentCategory.fromJson(original.toJson());

        expect(restored.clipPrompts, equals(['two people kissing']));
        expect(restored.clipNegativePrompts, equals(['two people talking']));
        expect(restored.clipThreshold, equals(3.0));
        expect(restored.detectionLabels, isEmpty);
      });
    });
  });
}
