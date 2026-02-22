import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analysis_settings_provider.g.dart';

/// State for analysis-specific settings.
class AnalysisSettingsState {
  const AnalysisSettingsState({
    this.asrModelId = 'whisper-small',
    this.nsfwModelId = 'nsfw-gantman-mobilenet-v2-224',
    this.profanityThreshold = 0.8,
    this.enableProfanity = true,
    this.frameSamplingRate = 5,
    this.asrLanguage = 'en',
    this.useGpuAcceleration = true,
    this.cpuThreads = 4,
    this.contentDetectionConfig = const ContentDetectionConfig(),
  });

  factory AnalysisSettingsState.fromJson(Map<String, dynamic> json) =>
      AnalysisSettingsState(
        asrModelId: json['asrModelId'] as String? ?? 'whisper-small',
        nsfwModelId:
            json['nsfwModelId'] as String? ?? 'nsfw-gantman-mobilenet-v2-224',
        profanityThreshold:
            (json['profanityThreshold'] as num?)?.toDouble() ?? 0.8,
        enableProfanity: json['enableProfanity'] as bool? ?? true,
        frameSamplingRate: json['frameSamplingRate'] as int? ?? 5,
        asrLanguage: json['asrLanguage'] as String? ?? 'en',
        useGpuAcceleration: json['useGpuAcceleration'] as bool? ?? true,
        cpuThreads: json['cpuThreads'] as int? ?? 4,
        contentDetectionConfig: json['contentDetectionConfig'] != null
            ? ContentDetectionConfig.fromJson(
                json['contentDetectionConfig'] as Map<String, dynamic>,
              )
            : const ContentDetectionConfig(),
      );

  factory AnalysisSettingsState.withDefaults() => const AnalysisSettingsState();

  factory AnalysisSettingsState.strict() => const AnalysisSettingsState(
        profanityThreshold: 0.7,
        frameSamplingRate: 3,
      );

  factory AnalysisSettingsState.permissive() => const AnalysisSettingsState(
        profanityThreshold: 0.9,
        frameSamplingRate: 10,
      );

  final String asrModelId;
  final String nsfwModelId;
  final double profanityThreshold;
  final bool enableProfanity;
  final int frameSamplingRate;
  final String asrLanguage;
  final bool useGpuAcceleration;
  final int cpuThreads;
  final ContentDetectionConfig contentDetectionConfig;

  AnalysisSettingsState copyWith({
    String? asrModelId,
    String? nsfwModelId,
    double? profanityThreshold,
    bool? enableProfanity,
    int? frameSamplingRate,
    String? asrLanguage,
    bool? useGpuAcceleration,
    int? cpuThreads,
    ContentDetectionConfig? contentDetectionConfig,
  }) =>
      AnalysisSettingsState(
        asrModelId: asrModelId ?? this.asrModelId,
        nsfwModelId: nsfwModelId ?? this.nsfwModelId,
        profanityThreshold: profanityThreshold ?? this.profanityThreshold,
        enableProfanity: enableProfanity ?? this.enableProfanity,
        frameSamplingRate: frameSamplingRate ?? this.frameSamplingRate,
        asrLanguage: asrLanguage ?? this.asrLanguage,
        useGpuAcceleration: useGpuAcceleration ?? this.useGpuAcceleration,
        cpuThreads: cpuThreads ?? this.cpuThreads,
        contentDetectionConfig:
            contentDetectionConfig ?? this.contentDetectionConfig,
      );

  AnalysisSettings toAnalysisSettings() => AnalysisSettings(
        modelConfig: ModelConfig(
          asrModelId: asrModelId,
          nsfwModelId: nsfwModelId,
          asrLanguage: asrLanguage,
          useGpu: useGpuAcceleration,
          cpuThreads: cpuThreads,
        ),
        profanityConfig: ProfanityConfig.defaults().copyWith(
          fuzzyThreshold: profanityThreshold,
        ),
        enableProfanity: enableProfanity,
        frameSamplingRate: frameSamplingRate,
        contentDetectionConfig: contentDetectionConfig,
      );

  Map<String, dynamic> toJson() => {
        'asrModelId': asrModelId,
        'nsfwModelId': nsfwModelId,
        'profanityThreshold': profanityThreshold,
        'enableProfanity': enableProfanity,
        'frameSamplingRate': frameSamplingRate,
        'asrLanguage': asrLanguage,
        'useGpuAcceleration': useGpuAcceleration,
        'cpuThreads': cpuThreads,
        'contentDetectionConfig': contentDetectionConfig.toJson(),
      };
}

@Riverpod(keepAlive: true)
class AnalysisSettingsNotifier extends _$AnalysisSettingsNotifier {
  static const String _prefsKey = 'kidslens_analysis_settings';

  @override
  AnalysisSettingsState build() => const AnalysisSettingsState();

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AnalysisSettingsState.fromJson(json);
      }
    } catch (_) {
      state = const AnalysisSettingsState();
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

  void setAsrModel(String modelId) {
    state = state.copyWith(asrModelId: modelId);
    saveSettings();
  }

  void setNsfwModel(String modelId) {
    state = state.copyWith(nsfwModelId: modelId);
    saveSettings();
  }

  void setAsrLanguage(String language) {
    state = state.copyWith(asrLanguage: language);
    saveSettings();
  }

  void setProfanityThreshold(double threshold) {
    state = state.copyWith(profanityThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  void setProfanityEnabled({required bool enabled}) {
    state = state.copyWith(enableProfanity: enabled);
    saveSettings();
  }

  void setFrameSamplingRate(int rate) {
    state = state.copyWith(frameSamplingRate: rate.clamp(1, 30));
    saveSettings();
  }

  void setGpuAcceleration({required bool enabled}) {
    state = state.copyWith(useGpuAcceleration: enabled);
    saveSettings();
  }

  void setCpuThreads(int threads) {
    state = state.copyWith(cpuThreads: threads.clamp(1, 32));
    saveSettings();
  }

  void resetToDefaults() {
    state = const AnalysisSettingsState();
    saveSettings();
  }
}

@Riverpod(keepAlive: true)
AnalysisSettings currentAnalysisSettings(Ref ref) =>
    ref.watch(analysisSettingsNotifierProvider).toAnalysisSettings();
