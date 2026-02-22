import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

void main() {
  test('settings state defaults are valid', () {
    final state = SettingsState();
    expect(state.analysisSettings.enableProfanity, isTrue);
    expect(state.defaultExportFormat, ExportFormat.mp4);
  });

  test('settings notifier updates theme and language', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsNotifierProvider.notifier)
      ..setThemeMode(ThemeMode.dark)
      ..setLanguage('en');

    final state = container.read(settingsNotifierProvider);
    expect(state.themeMode, ThemeMode.dark);
    expect(state.selectedLanguage, 'en');
  });

  test('ensureContentDetectionDefaults populates categories when empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsNotifierProvider.notifier)
      ..updateContentDetectionConfig(
      container
          .read(settingsNotifierProvider)
          .analysisSettings
          .contentDetectionConfig
          .copyWith(categories: const []),
    )
      ..ensureContentDetectionDefaults();

    final categories = container
        .read(settingsNotifierProvider)
        .analysisSettings
        .contentDetectionConfig
        .categories;
    expect(categories, isNotEmpty);
    expect(categories.first.id, ContentCategoryDefaults.profanity.id);
  });
}
