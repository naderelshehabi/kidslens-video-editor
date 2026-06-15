import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings_migration.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/model_bundle_selection_policy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

enum ExportQuality {
  low(480, 'Low (480p)'),
  medium(720, 'Medium (720p)'),
  high(1080, 'High (1080p)'),
  ultra(2160, 'Ultra (4K)');

  const ExportQuality(this.height, this.displayName);
  final int height;
  final String displayName;
}

enum ExportFormat {
  mp4('mp4', 'MP4 (H.264)'),
  webm('webm', 'WebM (VP9)'),
  mov('mov', 'MOV (ProRes)');

  const ExportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

class SettingsState {
  SettingsState({
    AnalysisSettings? analysisSettings,
    this.selectedLanguage,
    this.themeMode = ThemeMode.system,
    this.useDarkTheme = false,
    this.showOnboarding = true,
    this.modelCachePath,
    this.exportPath,
    this.defaultExportQuality = ExportQuality.high,
    this.defaultExportFormat = ExportFormat.mp4,
    this.autoSaveInterval = const Duration(minutes: 5),
    this.thumbnailInterval = const Duration(minutes: 1),
    this.localRuntimeId = 'cuda_llamacpp',
    this.modelBundleIdsByRole = const <String, String>{},
    this.acceptedModelBundleTerms = const <String>[],
  }) : analysisSettings = analysisSettings ?? AnalysisSettings.defaults();

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        analysisSettings: json['analysisSettings'] != null
            ? AnalysisSettings.fromJson(
                json['analysisSettings'] as Map<String, dynamic>,
              )
            : null,
        selectedLanguage: json['selectedLanguage'] as String?,
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        useDarkTheme: json['useDarkTheme'] as bool? ?? false,
        showOnboarding: json['showOnboarding'] as bool? ?? true,
        modelCachePath: json['modelCachePath'] as String?,
        exportPath: json['exportPath'] as String?,
        defaultExportQuality: ExportQuality.values[
            json['defaultExportQuality'] as int? ?? ExportQuality.high.index],
        defaultExportFormat: ExportFormat.values[
            json['defaultExportFormat'] as int? ?? ExportFormat.mp4.index],
        autoSaveInterval:
            Duration(minutes: json['autoSaveIntervalMinutes'] as int? ?? 5),
        thumbnailInterval:
            Duration(seconds: json['thumbnailIntervalSeconds'] as int? ?? 60),
        localRuntimeId: json['localRuntimeId'] as String? ?? 'cuda_llamacpp',
        modelBundleIdsByRole: _readStringMap(json['modelBundleIdsByRole']),
        acceptedModelBundleTerms: _readStringList(
          json['acceptedModelBundleTerms'],
        ),
      );

  final AnalysisSettings analysisSettings;
  final String? selectedLanguage;
  final ThemeMode themeMode;
  final bool useDarkTheme;
  final bool showOnboarding;
  final String? modelCachePath;
  final String? exportPath;
  final ExportQuality defaultExportQuality;
  final ExportFormat defaultExportFormat;
  final Duration autoSaveInterval;
  final Duration thumbnailInterval;
  final String localRuntimeId;
  final Map<String, String> modelBundleIdsByRole;
  final List<String> acceptedModelBundleTerms;

  SettingsState copyWith({
    AnalysisSettings? analysisSettings,
    String? selectedLanguage,
    ThemeMode? themeMode,
    bool? useDarkTheme,
    bool? showOnboarding,
    String? modelCachePath,
    String? exportPath,
    ExportQuality? defaultExportQuality,
    ExportFormat? defaultExportFormat,
    Duration? autoSaveInterval,
    Duration? thumbnailInterval,
    String? localRuntimeId,
    Map<String, String>? modelBundleIdsByRole,
    List<String>? acceptedModelBundleTerms,
  }) =>
      SettingsState(
        analysisSettings: analysisSettings ?? this.analysisSettings,
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        themeMode: themeMode ?? this.themeMode,
        useDarkTheme: useDarkTheme ?? this.useDarkTheme,
        showOnboarding: showOnboarding ?? this.showOnboarding,
        modelCachePath: modelCachePath ?? this.modelCachePath,
        exportPath: exportPath ?? this.exportPath,
        defaultExportQuality: defaultExportQuality ?? this.defaultExportQuality,
        defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
        autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
        thumbnailInterval: thumbnailInterval ?? this.thumbnailInterval,
        localRuntimeId: localRuntimeId ?? this.localRuntimeId,
        modelBundleIdsByRole: modelBundleIdsByRole ?? this.modelBundleIdsByRole,
        acceptedModelBundleTerms:
            acceptedModelBundleTerms ?? this.acceptedModelBundleTerms,
      );

  Map<String, dynamic> toJson() {
    final analysisSettingsJson =
        jsonDecode(jsonEncode(analysisSettings.toJson()))
            as Map<String, dynamic>;

    return {
      'analysisSettings': analysisSettingsJson,
      'selectedLanguage': selectedLanguage,
      'themeMode': themeMode.index,
      'useDarkTheme': useDarkTheme,
      'showOnboarding': showOnboarding,
      'modelCachePath': modelCachePath,
      'exportPath': exportPath,
      'defaultExportQuality': defaultExportQuality.index,
      'defaultExportFormat': defaultExportFormat.index,
      'autoSaveIntervalMinutes': autoSaveInterval.inMinutes,
      'thumbnailIntervalSeconds': thumbnailInterval.inSeconds,
      'localRuntimeId': localRuntimeId,
      'modelBundleIdsByRole': modelBundleIdsByRole,
      'acceptedModelBundleTerms': acceptedModelBundleTerms,
    };
  }
}

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) return const <String, String>{};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const String _prefsKey = 'kidslens_settings';

  @override
  SettingsState build() => SettingsState();

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final analysisSettingsJson = json['analysisSettings'];
        if (analysisSettingsJson is Map<String, dynamic> &&
            AnalysisSettingsMigration.needsMigration(analysisSettingsJson)) {
          AnalysisSettingsMigration.migrateToLatest(analysisSettingsJson);
        }
        final loadedState = SettingsState.fromJson(json);
        state = _normalizeState(loadedState);
        if (jsonEncode(state.toJson()) != jsonEncode(loadedState.toJson())) {
          _debounceSave();
        }
      }
    } catch (_) {
      state = SettingsState();
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // noop
    }
  }

  void updateAnalysisSettings(AnalysisSettings settings) {
    state = _normalizeState(
      state.copyWith(analysisSettings: _normalizeAnalysisSettings(settings)),
    );
    saveSettings();
  }

  void setAnalysisPipeline(String pipelineId) {
    final current = state.analysisSettings;
    updateAnalysisSettings(current.copyWith(analysisPipelineId: pipelineId));
  }

  void setLocalRuntime(String runtimeId) {
    state = _normalizeState(state.copyWith(localRuntimeId: runtimeId));
    saveSettings();
  }

  void selectModelBundleForRole({
    required String role,
    required String? modelBundleId,
  }) {
    final nextBundleIds = Map<String, String>.from(
      state.modelBundleIdsByRole,
    );
    if (modelBundleId == null || modelBundleId.trim().isEmpty) {
      nextBundleIds.remove(role);
    } else {
      nextBundleIds[role] = modelBundleId;
    }

    state =
        _normalizeState(state.copyWith(modelBundleIdsByRole: nextBundleIds));
    saveSettings();
  }

  void setModelBundleTermsAccepted({
    required String modelBundleId,
    required bool accepted,
  }) {
    final acceptedTerms = state.acceptedModelBundleTerms.toSet();
    if (accepted) {
      acceptedTerms.add(modelBundleId);
    } else {
      acceptedTerms.remove(modelBundleId);
    }
    state = _normalizeState(
      state.copyWith(
        acceptedModelBundleTerms: acceptedTerms.toList(growable: false),
      ),
    );
    saveSettings();
  }

  void setNsfwModel(String modelId) {
    final current = state.analysisSettings;
    updateAnalysisSettings(
      current.copyWith(
        modelConfig: current.modelConfig.copyWith(nsfwModelId: modelId),
      ),
    );
  }

  void setParserModel(String modelId) {
    final current = state.analysisSettings;
    updateAnalysisSettings(
      current.copyWith(
        modelConfig: current.modelConfig.copyWith(parserModelId: modelId),
      ),
    );
  }

  void setGenderModel(String modelId) {
    final current = state.analysisSettings;
    updateAnalysisSettings(
      current.copyWith(
        modelConfig: current.modelConfig.copyWith(genderModelId: modelId),
      ),
    );
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
    saveSettings();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(
      themeMode: mode,
      useDarkTheme: mode == ThemeMode.dark,
    );
    saveSettings();
  }

  void setDarkTheme({required bool useDark}) {
    state = state.copyWith(
      useDarkTheme: useDark,
      themeMode: useDark ? ThemeMode.dark : ThemeMode.light,
    );
    saveSettings();
  }

  void setOnboardingComplete() {
    state = state.copyWith(showOnboarding: false);
    saveSettings();
  }

  void setModelCachePath(String path) {
    state = state.copyWith(modelCachePath: path);
    saveSettings();
  }

  void setExportPath(String path) {
    state = state.copyWith(exportPath: path);
    saveSettings();
  }

  void setDefaultExportQuality(ExportQuality quality) {
    state = state.copyWith(defaultExportQuality: quality);
    saveSettings();
  }

  void setDefaultExportFormat(ExportFormat format) {
    state = state.copyWith(defaultExportFormat: format);
    saveSettings();
  }

  void setAutoSaveInterval(Duration interval) {
    state = state.copyWith(autoSaveInterval: interval);
    saveSettings();
  }

  void setThumbnailInterval(Duration interval) {
    state = state.copyWith(thumbnailInterval: interval);
    saveSettings();
  }

  void updateContentDetectionConfig(ContentDetectionConfig config) {
    final normalizedConfig = _normalizeContentDetectionConfig(config);
    state = state.copyWith(
      analysisSettings: state.analysisSettings.copyWith(
        contentDetectionConfig: normalizedConfig,
      ),
    );
    _debounceSave();
  }

  void updateContentCategory(String categoryId, ContentCategory updated) {
    final config = state.analysisSettings.contentDetectionConfig;
    final categories =
        config.categories.map((c) => c.id == categoryId ? updated : c).toList();
    updateContentDetectionConfig(config.copyWith(categories: categories));
  }

  void toggleModelContribution(
    String categoryId,
    String modelId, {
    required bool enabled,
  }) {
    final config = state.analysisSettings.contentDetectionConfig;
    final categories = config.categories.map((c) {
      if (c.id != categoryId) return c;
      final updatedContributions = c.modelContributions
          .map((m) => m.modelId == modelId ? m.copyWith(enabled: enabled) : m)
          .toList();
      return c.copyWith(modelContributions: updatedContributions);
    }).toList();
    updateContentDetectionConfig(config.copyWith(categories: categories));
  }

  void setCategoryThreshold(String categoryId, double threshold) {
    final config = state.analysisSettings.contentDetectionConfig;
    final categories = config.categories
        .map(
          (c) => c.id == categoryId
              ? c.copyWith(threshold: threshold.clamp(0.0, 1.0))
              : c,
        )
        .toList();
    updateContentDetectionConfig(config.copyWith(categories: categories));
  }

  void setCategoryAction(String categoryId, RemediationAction action) {
    final config = state.analysisSettings.contentDetectionConfig;
    final categories = config.categories
        .map((c) => c.id == categoryId ? c.copyWith(action: action) : c)
        .toList();
    updateContentDetectionConfig(config.copyWith(categories: categories));
  }

  void updateVotingConfig(VotingConfig config) {
    final detectionConfig = state.analysisSettings.contentDetectionConfig;
    updateContentDetectionConfig(
      detectionConfig.copyWith(votingConfig: config),
    );
  }

  void ensureContentDetectionDefaults() {
    final config = state.analysisSettings.contentDetectionConfig;
    final normalizedConfig = _normalizeContentDetectionConfig(config);
    if (jsonEncode(normalizedConfig.toJson()) != jsonEncode(config.toJson())) {
      updateContentDetectionConfig(
        normalizedConfig,
      );
    }
  }

  void resetToDefaults() {
    state = SettingsState();
    saveSettings();
  }

  Timer? _saveDebounceTimer;

  void _debounceSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), saveSettings);
  }

  SettingsState _normalizeState(SettingsState input) {
    final runtimeIds =
        LocalRuntimeId.values.map((runtime) => runtime.jsonValue).toSet();
    final runtimeId = runtimeIds.contains(input.localRuntimeId)
        ? input.localRuntimeId
        : LocalRuntimeId.cudaLlamaCpp.jsonValue;
    final acceptedTerms = input.acceptedModelBundleTerms.toSet();
    const selectionPolicy = ModelBundleSelectionPolicy(productionMode: false);
    final normalizedBundleIds = <String, String>{};
    for (final entry in input.modelBundleIdsByRole.entries) {
      ModelBundleRole? role;
      for (final candidate in ModelBundleRole.values) {
        if (candidate.name == entry.key) {
          role = candidate;
          break;
        }
      }
      if (role == null) continue;

      ModelBundleManifest? manifest;
      for (final candidate in ModelBundleCatalog.initialCandidates) {
        if (candidate.modelId == entry.value) {
          manifest = candidate;
          break;
        }
      }
      if (manifest == null) {
        continue;
      }
      if (!selectionPolicy.canSelect(
        manifest: manifest,
        role: role,
        localRuntimeId: runtimeId,
        acceptedTerms: acceptedTerms,
      )) {
        continue;
      }
      normalizedBundleIds[entry.key] = entry.value;
    }

    return input.copyWith(
      analysisSettings: _normalizeAnalysisSettings(input.analysisSettings),
      localRuntimeId: runtimeId,
      modelBundleIdsByRole: normalizedBundleIds,
      acceptedModelBundleTerms: acceptedTerms.toList(growable: false)..sort(),
    );
  }

  AnalysisSettings _normalizeAnalysisSettings(AnalysisSettings settings) =>
      settings.copyWith(
        contentDetectionConfig: _normalizeContentDetectionConfig(
          settings.contentDetectionConfig,
        ),
      );

  ContentDetectionConfig _normalizeContentDetectionConfig(
    ContentDetectionConfig config,
  ) =>
      config.copyWith(
        categories: ContentCategoryDefaults.normalizeCategories(
          config.categories,
        ),
      );
}
