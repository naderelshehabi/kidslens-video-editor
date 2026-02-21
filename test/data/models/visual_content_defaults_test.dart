import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/data/models/visual_content_defaults.dart';
import 'package:kidslens_video_editor/services/nudenet_service.dart';

void main() {
  group('VisualContentDefaults', () {
    group('builtInCategories', () {
      test('should contain exactly 4 categories', () {
        expect(VisualContentDefaults.builtInCategories, hasLength(4));
      });

      test('should have unique IDs', () {
        final ids = VisualContentDefaults.builtInCategories.map((c) => c.id).toSet();
        expect(ids, hasLength(4));
      });

      test('should have unique names', () {
        final names =
            VisualContentDefaults.builtInCategories.map((c) => c.name).toSet();
        expect(names, hasLength(4));
      });

      test('all categories should be built-in', () {
        for (final category in VisualContentDefaults.builtInCategories) {
          expect(category.isBuiltIn, isTrue,
              reason: '${category.name} should be built-in');
        }
      });

      test('all categories should be enabled by default', () {
        for (final category in VisualContentDefaults.builtInCategories) {
          expect(category.enabled, isTrue,
              reason: '${category.name} should be enabled');
        }
      });
    });

    group('nudity category', () {
      test('should be NudeNet-only detection', () {
        expect(VisualContentDefaults.nudity.detectionSource,
            equals(CategoryDetectionSource.nudeNet));
      });

      test('should have NudeNet detection labels', () {
        expect(VisualContentDefaults.nudity.detectionLabels, isNotEmpty);
        expect(VisualContentDefaults.nudity.detectionLabels,
            contains('FEMALE_BREAST_EXPOSED'));
        expect(VisualContentDefaults.nudity.detectionLabels,
            contains('BUTTOCKS_EXPOSED'));
      });

      test('should not have CLIP prompts', () {
        expect(VisualContentDefaults.nudity.clipPrompts, isEmpty);
        expect(VisualContentDefaults.nudity.clipNegativePrompts, isEmpty);
      });

      test('should use blur action', () {
        expect(VisualContentDefaults.nudity.action,
            equals(VisualContentAction.blurRegion));
      });

      test('all labels should be valid NudeNet class names', () {
        for (final label in VisualContentDefaults.nudity.detectionLabels) {
          expect(NudeNetLabels.classNames, contains(label),
              reason: 'Label "$label" not found in NudeNet class names');
        }
      });
    });

    group('sexualContent category', () {
      test('should use both detection sources', () {
        expect(VisualContentDefaults.sexualContent.detectionSource,
            equals(CategoryDetectionSource.both));
      });

      test('should have both NudeNet labels and CLIP prompts', () {
        expect(VisualContentDefaults.sexualContent.detectionLabels, isNotEmpty);
        expect(VisualContentDefaults.sexualContent.clipPrompts, isNotEmpty);
        expect(
            VisualContentDefaults.sexualContent.clipNegativePrompts, isNotEmpty);
      });

      test('should use cut action', () {
        expect(VisualContentDefaults.sexualContent.action,
            equals(VisualContentAction.cutScene));
      });

      test('CLIP threshold should be in expected range', () {
        expect(VisualContentDefaults.sexualContent.clipThreshold,
            greaterThan(0));
        expect(VisualContentDefaults.sexualContent.clipThreshold,
            lessThanOrEqualTo(15));
      });

      test('all labels should be valid NudeNet class names', () {
        for (final label
            in VisualContentDefaults.sexualContent.detectionLabels) {
          expect(NudeNetLabels.classNames, contains(label),
              reason: 'Label "$label" not found in NudeNet class names');
        }
      });
    });

    group('kissing category', () {
      test('should be CLIP-only detection', () {
        expect(VisualContentDefaults.kissing.detectionSource,
            equals(CategoryDetectionSource.clip));
      });

      test('should have CLIP prompts but no NudeNet labels', () {
        expect(VisualContentDefaults.kissing.detectionLabels, isEmpty);
        expect(VisualContentDefaults.kissing.clipPrompts, isNotEmpty);
        expect(VisualContentDefaults.kissing.clipNegativePrompts, isNotEmpty);
      });

      test('should use cut action', () {
        expect(VisualContentDefaults.kissing.action,
            equals(VisualContentAction.cutScene));
      });
    });

    group('immodestDress category', () {
      test('should be CLIP-only detection', () {
        expect(VisualContentDefaults.immodestDress.detectionSource,
            equals(CategoryDetectionSource.clip));
      });

      test('should have CLIP prompts but no NudeNet labels', () {
        expect(VisualContentDefaults.immodestDress.detectionLabels, isEmpty);
        expect(VisualContentDefaults.immodestDress.clipPrompts, isNotEmpty);
        expect(
            VisualContentDefaults.immodestDress.clipNegativePrompts, isNotEmpty);
      });

      test('should use blur action', () {
        expect(VisualContentDefaults.immodestDress.action,
            equals(VisualContentAction.blurRegion));
      });
    });

    group('label coverage', () {
      test('no duplicate labels across NudeNet categories', () {
        // Duplicates between nudity and sexual_content are expected/intentional
        // (sexual_content reuses nudity labels for NudeNet path)
        // But verify there are no accidental label typos
        final allLabels = <String>{};
        for (final category in VisualContentDefaults.builtInCategories) {
          for (final label in category.detectionLabels) {
            allLabels.add(label);
          }
        }

        // All referenced labels should be valid NudeNet labels
        for (final label in allLabels) {
          expect(NudeNetLabels.classNames, contains(label),
              reason: 'Label "$label" used in a category is not a valid '
                  'NudeNet class name');
        }
      });
    });
  });
}
