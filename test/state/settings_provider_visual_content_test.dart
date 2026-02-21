import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/data/models/visual_content_defaults.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Runtime category default initialization', () {
    test('initially visualContentConfig.categories may be empty', () {
      final state = container.read(settingsNotifierProvider);
      final config = state.analysisSettings.visualContentConfig;

      expect(config.categories, isEmpty);
    });

    test(
        'ensureVisualContentDefaults populates categories with 4 defaults when empty',
        () {
      container.read(settingsNotifierProvider.notifier).ensureVisualContentDefaults();

      final state = container.read(settingsNotifierProvider);
      final categories = state.analysisSettings.visualContentConfig.categories;

      expect(categories, hasLength(4));
      expect(categories.map((c) => c.id), contains('nudity'));
      expect(categories.map((c) => c.id), contains('sexual_content'));
      expect(categories.map((c) => c.id), contains('kissing'));
      expect(categories.map((c) => c.id), contains('immodest_dress'));
    });

    test('ensureVisualContentDefaults is idempotent', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();
      final categoriesAfterFirst =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categoriesAfterFirst, hasLength(4));

      notifier.ensureVisualContentDefaults();
      final categoriesAfterSecond =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;

      expect(categoriesAfterSecond, hasLength(4));
      expect(
        categoriesAfterSecond.map((c) => c.id).toList(),
        equals(categoriesAfterFirst.map((c) => c.id).toList()),
      );
    });

    test('ensureVisualContentDefaults does not overwrite existing categories',
        () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Manually add a single category first
      const customCategory = VisualContentCategory(
        id: 'custom_test',
        name: 'Custom Test',
        description: 'A test category',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['test prompt'],
        isBuiltIn: false,
      );
      notifier.addCustomCategory(customCategory);
      expect(
        container.read(settingsNotifierProvider)
            .analysisSettings.visualContentConfig.categories,
        hasLength(1),
      );

      // ensureVisualContentDefaults should not overwrite because categories
      // is not empty
      notifier.ensureVisualContentDefaults();
      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;

      expect(categories, hasLength(1));
      expect(categories.first.id, equals('custom_test'));
    });
  });

  group('updateVisualContentConfig', () {
    test('updates the entire config', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      const newConfig = VisualContentConfig(
        enableNudeNetDetection: false,
        enableClipClassification: false,
        preFilterThreshold: 0.50,
      );

      notifier.updateVisualContentConfig(newConfig);

      final state = container.read(settingsNotifierProvider);
      final config = state.analysisSettings.visualContentConfig;

      expect(config.enableNudeNetDetection, isFalse);
      expect(config.enableClipClassification, isFalse);
      expect(config.preFilterThreshold, equals(0.50));
      expect(config.categories, isEmpty);
    });

    test('changes are reflected in state', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      final configBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configBefore.categories, hasLength(4));

      // Replace with a config that has only one category
      final updatedConfig = configBefore.copyWith(
        categories: [VisualContentDefaults.nudity],
      );
      notifier.updateVisualContentConfig(updatedConfig);

      final configAfter =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfter.categories, hasLength(1));
      expect(configAfter.categories.first.id, equals('nudity'));
    });

    test('persists changes that can be verified by reading state', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      const config = VisualContentConfig(
        enableClipClassification: false,
        preFilterThreshold: 0.75,
      );

      notifier.updateVisualContentConfig(config);

      // Read state again to verify persistence
      final readState = container.read(settingsNotifierProvider);
      expect(
        readState.analysisSettings.visualContentConfig.enableNudeNetDetection,
        isTrue,
      );
      expect(
        readState.analysisSettings.visualContentConfig.enableClipClassification,
        isFalse,
      );
      expect(
        readState.analysisSettings.visualContentConfig.preFilterThreshold,
        equals(0.75),
      );
    });
  });

  group('updateVisualContentCategory', () {
    test('updates a single category by ID', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      const updatedNudity = VisualContentCategory(
        id: 'nudity',
        name: 'Nudity (Updated)',
        description: 'Updated description',
        detectionSource: CategoryDetectionSource.nudeNet,
        detectionLabels: ['FEMALE_BREAST_EXPOSED'],
        threshold: 0.90,
        action: VisualContentAction.pixelateRegion,
      );

      notifier.updateVisualContentCategory('nudity', updatedNudity);

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;

      final nudityCategory = categories.firstWhere((c) => c.id == 'nudity');
      expect(nudityCategory.name, equals('Nudity (Updated)'));
      expect(nudityCategory.description, equals('Updated description'));
      expect(nudityCategory.threshold, equals(0.90));
      expect(nudityCategory.action, equals(VisualContentAction.pixelateRegion));
    });

    test('only the targeted category changes, others remain unchanged', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      final categoriesBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      final kissingBefore = categoriesBefore.firstWhere(
        (c) => c.id == 'kissing',
      );
      final sexualBefore = categoriesBefore.firstWhere(
        (c) => c.id == 'sexual_content',
      );
      final immodestBefore = categoriesBefore.firstWhere(
        (c) => c.id == 'immodest_dress',
      );

      // Update only nudity
      const updatedNudity = VisualContentCategory(
        id: 'nudity',
        name: 'Nudity Modified',
        description: 'Modified',
        detectionSource: CategoryDetectionSource.nudeNet,
        threshold: 0.99,
      );
      notifier.updateVisualContentCategory('nudity', updatedNudity);

      final categoriesAfter =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      final kissingAfter = categoriesAfter.firstWhere(
        (c) => c.id == 'kissing',
      );
      final sexualAfter = categoriesAfter.firstWhere(
        (c) => c.id == 'sexual_content',
      );
      final immodestAfter = categoriesAfter.firstWhere(
        (c) => c.id == 'immodest_dress',
      );

      expect(kissingAfter, equals(kissingBefore));
      expect(sexualAfter, equals(sexualBefore));
      expect(immodestAfter, equals(immodestBefore));
    });

    test('non-existent category ID does not crash', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      const updatedCategory = VisualContentCategory(
        id: 'non_existent',
        name: 'Does Not Exist',
        description: 'This ID is not in the list',
        detectionSource: CategoryDetectionSource.clip,
      );

      // Should not throw
      notifier.updateVisualContentCategory('non_existent', updatedCategory);

      // Categories should remain unchanged (4 built-in defaults)
      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categories, hasLength(4));
    });
  });

  group('addCustomCategory', () {
    test('adds a new category to the list', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      const customCategory = VisualContentCategory(
        id: 'custom_violence',
        name: 'Violence',
        description: 'Detects violent scenes',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['violent fight scene', 'physical assault'],
        clipNegativePrompts: ['sports competition', 'action movie stunt'],
        clipThreshold: 3.5,
        action: VisualContentAction.cutScene,
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categories, hasLength(5));
    });

    test('new category appears in config.categories', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      const customCategory = VisualContentCategory(
        id: 'custom_drugs',
        name: 'Drug Content',
        description: 'Detects drug-related content',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['drug use', 'smoking marijuana'],
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      final found = categories.where((c) => c.id == 'custom_drugs');
      expect(found, hasLength(1));
      expect(found.first.name, equals('Drug Content'));
    });

    test('custom category has isBuiltIn = false', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      const customCategory = VisualContentCategory(
        id: 'custom_gambling',
        name: 'Gambling',
        description: 'Detects gambling content',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['casino gambling'],
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      final added = categories.firstWhere((c) => c.id == 'custom_gambling');
      expect(added.isBuiltIn, isFalse);
    });

    test('adding to empty list works correctly', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Categories start empty (no ensureVisualContentDefaults called)
      expect(
        container.read(settingsNotifierProvider)
            .analysisSettings.visualContentConfig.categories,
        isEmpty,
      );

      const customCategory = VisualContentCategory(
        id: 'first_custom',
        name: 'First Custom',
        description: 'The very first category added',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['test'],
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categories, hasLength(1));
      expect(categories.first.id, equals('first_custom'));
    });
  });

  group('removeCustomCategory', () {
    test('removes a custom category by ID', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      const customCategory = VisualContentCategory(
        id: 'to_be_removed',
        name: 'Removable',
        description: 'This will be removed',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['removable content'],
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);
      expect(
        container.read(settingsNotifierProvider)
            .analysisSettings.visualContentConfig.categories,
        hasLength(5),
      );

      notifier.removeCustomCategory('to_be_removed');

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categories, hasLength(4));
      expect(categories.map((c) => c.id), isNot(contains('to_be_removed')));
    });

    test('category no longer in list after removal', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      const customCategory = VisualContentCategory(
        id: 'temporary',
        name: 'Temporary',
        description: 'Temporary category',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['temp'],
        isBuiltIn: false,
      );

      notifier.addCustomCategory(customCategory);
      expect(
        container.read(settingsNotifierProvider)
            .analysisSettings.visualContentConfig.categories
            .any((c) => c.id == 'temporary'),
        isTrue,
      );

      notifier.removeCustomCategory('temporary');

      expect(
        container.read(settingsNotifierProvider)
            .analysisSettings.visualContentConfig.categories
            .any((c) => c.id == 'temporary'),
        isFalse,
      );
    });

    test('removing a built-in category by ID filters it out', () {
      container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults()
        // removeCustomCategory filters by ID regardless of isBuiltIn flag.
        // This verifies the method handles the operation without crashing.
        ..removeCustomCategory('nudity');

      final categories =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;

      // The implementation filters by ID, so built-in categories are also
      // removed if the ID matches. Verify the method completes and the
      // category is no longer present.
      expect(categories.map((c) => c.id), isNot(contains('nudity')));
      expect(categories, hasLength(3));
    });

    test('removing non-existent ID does not crash or change list', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      final categoriesBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;

      notifier.removeCustomCategory('does_not_exist');

      final categoriesAfter =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig.categories;
      expect(categoriesAfter, hasLength(categoriesBefore.length));
    });
  });

  group('Config toggles', () {
    test('toggle enableNudeNetDetection', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Default is true
      final configBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configBefore.enableNudeNetDetection, isTrue);

      // Toggle to false
      notifier.updateVisualContentConfig(
        configBefore.copyWith(enableNudeNetDetection: false),
      );
      final configAfterDisable =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfterDisable.enableNudeNetDetection, isFalse);

      // Toggle back to true
      notifier.updateVisualContentConfig(
        configAfterDisable.copyWith(enableNudeNetDetection: true),
      );
      final configAfterEnable =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfterEnable.enableNudeNetDetection, isTrue);
    });

    test('toggle enableClipClassification', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Default is true
      final configBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configBefore.enableClipClassification, isTrue);

      // Toggle to false
      notifier.updateVisualContentConfig(
        configBefore.copyWith(enableClipClassification: false),
      );
      final configAfterDisable =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfterDisable.enableClipClassification, isFalse);

      // Toggle back to true
      notifier.updateVisualContentConfig(
        configAfterDisable.copyWith(enableClipClassification: true),
      );
      final configAfterEnable =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfterEnable.enableClipClassification, isTrue);
    });

    test('change preFilterThreshold', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Default is 0.30
      final configBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configBefore.preFilterThreshold, equals(0.30));

      // Change to 0.60
      notifier.updateVisualContentConfig(
        configBefore.copyWith(preFilterThreshold: 0.60),
      );
      final configAfter =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfter.preFilterThreshold, equals(0.60));
    });

    test('change preFilterThreshold preserves other config fields', () {
      final notifier = container.read(settingsNotifierProvider.notifier)
        ..ensureVisualContentDefaults();

      final configBefore =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configBefore.categories, hasLength(4));

      notifier.updateVisualContentConfig(
        configBefore.copyWith(preFilterThreshold: 0.10),
      );

      final configAfter =
          container.read(settingsNotifierProvider)
              .analysisSettings.visualContentConfig;
      expect(configAfter.preFilterThreshold, equals(0.10));
      expect(configAfter.enableNudeNetDetection,
          equals(configBefore.enableNudeNetDetection),);
      expect(configAfter.enableClipClassification,
          equals(configBefore.enableClipClassification),);
      expect(configAfter.categories, hasLength(4));
    });

    test('multiple toggles in sequence reflect correct final state', () {
      final notifier = container.read(settingsNotifierProvider.notifier);

      var config = container.read(settingsNotifierProvider)
          .analysisSettings.visualContentConfig;

      // Disable both
      notifier.updateVisualContentConfig(
        config.copyWith(
          enableNudeNetDetection: false,
          enableClipClassification: false,
        ),
      );

      config = container.read(settingsNotifierProvider)
          .analysisSettings.visualContentConfig;
      expect(config.enableNudeNetDetection, isFalse);
      expect(config.enableClipClassification, isFalse);

      // Enable NudeNet only
      notifier.updateVisualContentConfig(
        config.copyWith(enableNudeNetDetection: true),
      );

      config = container.read(settingsNotifierProvider)
          .analysisSettings.visualContentConfig;
      expect(config.enableNudeNetDetection, isTrue);
      expect(config.enableClipClassification, isFalse);

      // Enable both
      notifier.updateVisualContentConfig(
        config.copyWith(enableClipClassification: true),
      );

      config = container.read(settingsNotifierProvider)
          .analysisSettings.visualContentConfig;
      expect(config.enableNudeNetDetection, isTrue);
      expect(config.enableClipClassification, isTrue);
    });
  });
}
