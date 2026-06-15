import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

void main() {
  test('settings state defaults are valid', () {
    final state = SettingsState();
    expect(state.analysisSettings.enableProfanity, isTrue);
    expect(
      state.analysisSettings.analysisPipelineId,
      DetectionPipelineIds.vssFamilySafetyV1,
    );
    expect(state.defaultExportFormat, ExportFormat.mp4);
    expect(state.localRuntimeId, LocalRuntimeId.cudaLlamaCpp.jsonValue);
    expect(state.modelBundleIdsByRole, isEmpty);
    expect(state.acceptedModelBundleTerms, isEmpty);
  });

  test('settings state serializes local model bundle selections', () {
    final state = SettingsState(
      localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
      modelBundleIdsByRole: const {'vlm': 'test_bundle'},
      acceptedModelBundleTerms: const ['test_bundle'],
    );

    final restored = SettingsState.fromJson(state.toJson());

    expect(
      restored.localRuntimeId,
      LocalRuntimeId.cudaTransformersHelper.jsonValue,
    );
    expect(restored.modelBundleIdsByRole, {'vlm': 'test_bundle'});
    expect(restored.acceptedModelBundleTerms, ['test_bundle']);
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

  test('settings notifier updates pipeline and local runtime', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsNotifierProvider.notifier)
      ..setAnalysisPipeline(DetectionPipelineIds.vssFamilySafetyV1)
      ..setLocalRuntime(LocalRuntimeId.directmlOnnx.jsonValue);

    final state = container.read(settingsNotifierProvider);
    expect(
      state.analysisSettings.analysisPipelineId,
      DetectionPipelineIds.vssFamilySafetyV1,
    );
    expect(state.localRuntimeId, LocalRuntimeId.directmlOnnx.jsonValue);
  });

  test('settings notifier keeps validation-ready official GGUF selections', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsNotifierProvider.notifier)
      ..setLocalRuntime(LocalRuntimeId.cudaLlamaCpp.jsonValue)
      ..selectModelBundleForRole(
        role: ModelBundleRole.vlm.name,
        modelBundleId: 'qwen3_vl_8b_instruct_gguf_q4km',
      )
      ..selectModelBundleForRole(
        role: ModelBundleRole.embedding.name,
        modelBundleId: 'qwen3_embedding_0_6b_gguf_q8',
      );

    expect(
      container.read(settingsNotifierProvider).modelBundleIdsByRole,
      {
        ModelBundleRole.vlm.name: 'qwen3_vl_8b_instruct_gguf_q4km',
        ModelBundleRole.embedding.name: 'qwen3_embedding_0_6b_gguf_q8',
      },
    );
  });

  test('settings notifier blocks commercially blocked model bundle selections',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsNotifierProvider.notifier).selectModelBundleForRole(
          role: ModelBundleRole.grounding.name,
          modelBundleId: 'nvidia_locateanything_3b',
        );

    expect(
      container.read(settingsNotifierProvider).modelBundleIdsByRole,
      isEmpty,
    );
  });

  test('settings notifier persists terms acceptance separately from selection',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(settingsNotifierProvider.notifier)
        .setModelBundleTermsAccepted(
          modelBundleId: 'meta_llama_4_scout_17b_16e_instruct',
          accepted: true,
        );

    expect(
      container.read(settingsNotifierProvider).acceptedModelBundleTerms,
      ['meta_llama_4_scout_17b_16e_instruct'],
    );
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
    expect(categories.first.id, ContentCategoryDefaults.nsfw.id);
  });
}
