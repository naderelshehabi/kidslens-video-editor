import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analysis_settings_provider.g.dart';

/// State for analysis-specific settings (model selection, thresholds)
class AnalysisSettingsState {
  const AnalysisSettingsState({
    this.asrModelId = 'whisper-small',
    this.visualModelIds = const {},
    this.nsfwThreshold = 0.6,
    this.violenceThreshold = 0.6,
    this.bloodThreshold = 0.6,
    this.weaponsThreshold = 0.6,
    this.profanityThreshold = 0.8,
    this.enableNsfw = true,
    this.enableViolence = true,
    this.enableBlood = true,
    this.enableWeapons = true,
    this.enableProfanity = true,
    this.frameSamplingRate = 5,
    this.asrLanguage = 'en',
    this.useGpuAcceleration = true,
    this.cpuThreads = 4,
  });

  /// Create from JSON for persistence
  factory AnalysisSettingsState.fromJson(Map<String, dynamic> json) {
    final visualModelIdsJson =
        json['visualModelIds'] as Map<String, dynamic>? ?? {};
    final visualModelIds = <HuggingFaceModelType, String>{};
    for (final entry in visualModelIdsJson.entries) {
      final type = HuggingFaceModelType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => HuggingFaceModelType.nsfw,
      );
      visualModelIds[type] = entry.value as String;
    }

    return AnalysisSettingsState(
      asrModelId: json['asrModelId'] as String? ?? 'whisper-small',
      visualModelIds: visualModelIds,
      nsfwThreshold: (json['nsfwThreshold'] as num?)?.toDouble() ?? 0.6,
      violenceThreshold: (json['violenceThreshold'] as num?)?.toDouble() ?? 0.6,
      bloodThreshold: (json['bloodThreshold'] as num?)?.toDouble() ?? 0.6,
      weaponsThreshold: (json['weaponsThreshold'] as num?)?.toDouble() ?? 0.6,
      profanityThreshold:
          (json['profanityThreshold'] as num?)?.toDouble() ?? 0.8,
      enableNsfw: json['enableNsfw'] as bool? ?? true,
      enableViolence: json['enableViolence'] as bool? ?? true,
      enableBlood: json['enableBlood'] as bool? ?? true,
      enableWeapons: json['enableWeapons'] as bool? ?? true,
      enableProfanity: json['enableProfanity'] as bool? ?? true,
      frameSamplingRate: json['frameSamplingRate'] as int? ?? 5,
      asrLanguage: json['asrLanguage'] as String? ?? 'en',
      useGpuAcceleration: json['useGpuAcceleration'] as bool? ?? true,
      cpuThreads: json['cpuThreads'] as int? ?? 4,
    );
  }

  /// Create with default recommended models
  factory AnalysisSettingsState.withDefaults() => const AnalysisSettingsState(
        visualModelIds: {
          HuggingFaceModelType.nsfw: 'nsfw-efficientnet-b4',
          HuggingFaceModelType.violence: 'violence-vit-base',
          HuggingFaceModelType.blood: 'gore-efficientnet-b2',
          HuggingFaceModelType.weapons: 'weapons-yolov8-small',
        },
      );

  /// Create strict settings for maximum detection
  factory AnalysisSettingsState.strict() => const AnalysisSettingsState(
        nsfwThreshold: 0.4,
        violenceThreshold: 0.4,
        bloodThreshold: 0.4,
        weaponsThreshold: 0.4,
        profanityThreshold: 0.7,
        frameSamplingRate: 3,
      );

  /// Create permissive settings for fewer false positives
  factory AnalysisSettingsState.permissive() => const AnalysisSettingsState(
        nsfwThreshold: 0.8,
        violenceThreshold: 0.8,
        bloodThreshold: 0.8,
        weaponsThreshold: 0.8,
        profanityThreshold: 0.9,
        frameSamplingRate: 10,
      );

  /// Selected ASR model ID
  final String asrModelId;

  /// Selected visual model IDs mapped by type (e.g., nsfw -> 'nsfw-mobilenet-v2')
  final Map<HuggingFaceModelType, String> visualModelIds;

  /// Detection thresholds (0.0 - 1.0)
  final double nsfwThreshold;
  final double violenceThreshold;
  final double bloodThreshold;
  final double weaponsThreshold;
  final double profanityThreshold;

  /// Enabled detection types
  final bool enableNsfw;
  final bool enableViolence;
  final bool enableBlood;
  final bool enableWeapons;
  final bool enableProfanity;

  /// Frame sampling rate (analyze every Nth frame)
  final int frameSamplingRate;

  /// ASR language code
  final String asrLanguage;

  /// GPU acceleration setting
  final bool useGpuAcceleration;

  /// Number of CPU threads for inference
  final int cpuThreads;

  AnalysisSettingsState copyWith({
    String? asrModelId,
    Map<HuggingFaceModelType, String>? visualModelIds,
    double? nsfwThreshold,
    double? violenceThreshold,
    double? bloodThreshold,
    double? weaponsThreshold,
    double? profanityThreshold,
    bool? enableNsfw,
    bool? enableViolence,
    bool? enableBlood,
    bool? enableWeapons,
    bool? enableProfanity,
    int? frameSamplingRate,
    String? asrLanguage,
    bool? useGpuAcceleration,
    int? cpuThreads,
  }) =>
      AnalysisSettingsState(
        asrModelId: asrModelId ?? this.asrModelId,
        visualModelIds: visualModelIds ?? this.visualModelIds,
        nsfwThreshold: nsfwThreshold ?? this.nsfwThreshold,
        violenceThreshold: violenceThreshold ?? this.violenceThreshold,
        bloodThreshold: bloodThreshold ?? this.bloodThreshold,
        weaponsThreshold: weaponsThreshold ?? this.weaponsThreshold,
        profanityThreshold: profanityThreshold ?? this.profanityThreshold,
        enableNsfw: enableNsfw ?? this.enableNsfw,
        enableViolence: enableViolence ?? this.enableViolence,
        enableBlood: enableBlood ?? this.enableBlood,
        enableWeapons: enableWeapons ?? this.enableWeapons,
        enableProfanity: enableProfanity ?? this.enableProfanity,
        frameSamplingRate: frameSamplingRate ?? this.frameSamplingRate,
        asrLanguage: asrLanguage ?? this.asrLanguage,
        useGpuAcceleration: useGpuAcceleration ?? this.useGpuAcceleration,
        cpuThreads: cpuThreads ?? this.cpuThreads,
      );

  /// Get threshold for a specific visual detection type
  double getThreshold(HuggingFaceModelType type) {
    switch (type) {
      case HuggingFaceModelType.nsfw:
        return nsfwThreshold;
      case HuggingFaceModelType.violence:
        return violenceThreshold;
      case HuggingFaceModelType.blood:
        return bloodThreshold;
      case HuggingFaceModelType.weapons:
        return weaponsThreshold;
      case HuggingFaceModelType.asr:
        return 1; // ASR doesn't have a threshold
    }
  }

  /// Check if a detection type is enabled
  bool isEnabled(HuggingFaceModelType type) {
    switch (type) {
      case HuggingFaceModelType.nsfw:
        return enableNsfw;
      case HuggingFaceModelType.violence:
        return enableViolence;
      case HuggingFaceModelType.blood:
        return enableBlood;
      case HuggingFaceModelType.weapons:
        return enableWeapons;
      case HuggingFaceModelType.asr:
        return true; // ASR is always enabled
    }
  }

  /// Get visual model ID for a specific type
  String? getVisualModelId(HuggingFaceModelType type) => visualModelIds[type];

  /// Convert to AnalysisSettings for compatibility
  AnalysisSettings toAnalysisSettings() => AnalysisSettings(
      modelConfig: ModelConfig(
        asrModelId: asrModelId,
        visualModelId:
            visualModelIds[HuggingFaceModelType.nsfw] ?? 'nsfw-mobilenet-v2',
        nsfwModelId:
            visualModelIds[HuggingFaceModelType.nsfw] ?? 'nsfw-mobilenet-v2',
        violenceModelId:
            visualModelIds[HuggingFaceModelType.violence] ?? 'violence-mobilenet',
        bloodModelId:
            visualModelIds[HuggingFaceModelType.blood] ?? 'gore-efficientnet-b2',
        weaponsModelId:
            visualModelIds[HuggingFaceModelType.weapons] ?? 'weapons-yolov8-small',
        asrLanguage: asrLanguage,
        useGpu: useGpuAcceleration,
        cpuThreads: cpuThreads,
      ),
      profanityConfig: ProfanityConfig.defaults(),
      nsfwThreshold: nsfwThreshold,
      violenceThreshold: violenceThreshold,
      bloodThreshold: bloodThreshold,
      weaponsThreshold: weaponsThreshold,
      enableNsfw: enableNsfw,
      enableViolence: enableViolence,
      enableBlood: enableBlood,
      enableWeapons: enableWeapons,
      enableProfanity: enableProfanity,
      frameSamplingRate: frameSamplingRate,
    );

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'asrModelId': asrModelId,
        'visualModelIds': visualModelIds.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'nsfwThreshold': nsfwThreshold,
        'violenceThreshold': violenceThreshold,
        'bloodThreshold': bloodThreshold,
        'weaponsThreshold': weaponsThreshold,
        'profanityThreshold': profanityThreshold,
        'enableNsfw': enableNsfw,
        'enableViolence': enableViolence,
        'enableBlood': enableBlood,
        'enableWeapons': enableWeapons,
        'enableProfanity': enableProfanity,
        'frameSamplingRate': frameSamplingRate,
        'asrLanguage': asrLanguage,
        'useGpuAcceleration': useGpuAcceleration,
        'cpuThreads': cpuThreads,
      };
}

/// Provider for managing analysis settings
@Riverpod(keepAlive: true)
class AnalysisSettingsNotifier extends _$AnalysisSettingsNotifier {
  static const String _prefsKey = 'kidslens_analysis_settings';

  @override
  AnalysisSettingsState build() => const AnalysisSettingsState();

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AnalysisSettingsState.fromJson(json);
      }
    } catch (e) {
      // If loading fails, keep default settings
      state = const AnalysisSettingsState();
    }
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      // Silently fail - settings will be saved next time
    }
  }

  // ============================================================
  // Model Selection Methods
  // ============================================================

  /// Set the ASR model
  void setAsrModel(String modelId) {
    state = state.copyWith(asrModelId: modelId);
    saveSettings();
  }

  /// Set a visual model for a specific type
  void setVisualModel(HuggingFaceModelType type, String modelId) {
    state = state.copyWith(
      visualModelIds: {...state.visualModelIds, type: modelId},
    );
    saveSettings();
  }

  /// Set the ASR language
  void setAsrLanguage(String language) {
    state = state.copyWith(asrLanguage: language);
    saveSettings();
  }

  // ============================================================
  // Threshold Methods
  // ============================================================

  /// Set NSFW detection threshold
  void setNsfwThreshold(double threshold) {
    state = state.copyWith(nsfwThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  /// Set violence detection threshold
  void setViolenceThreshold(double threshold) {
    state = state.copyWith(violenceThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  /// Set blood/gore detection threshold
  void setBloodThreshold(double threshold) {
    state = state.copyWith(bloodThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  /// Set weapons detection threshold
  void setWeaponsThreshold(double threshold) {
    state = state.copyWith(weaponsThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  /// Set profanity detection threshold
  void setProfanityThreshold(double threshold) {
    state = state.copyWith(profanityThreshold: threshold.clamp(0.0, 1.0));
    saveSettings();
  }

  /// Set all thresholds at once
  void setAllThresholds({
    double? nsfw,
    double? violence,
    double? blood,
    double? weapons,
    double? profanity,
  }) {
    state = state.copyWith(
      nsfwThreshold: (nsfw ?? state.nsfwThreshold).clamp(0.0, 1.0),
      violenceThreshold: (violence ?? state.violenceThreshold).clamp(0.0, 1.0),
      bloodThreshold: (blood ?? state.bloodThreshold).clamp(0.0, 1.0),
      weaponsThreshold: (weapons ?? state.weaponsThreshold).clamp(0.0, 1.0),
      profanityThreshold:
          (profanity ?? state.profanityThreshold).clamp(0.0, 1.0),
    );
    saveSettings();
  }

  // ============================================================
  // Enable/Disable Methods
  // ============================================================

  /// Enable/disable NSFW detection
  void setNsfwEnabled({required bool enabled}) {
    state = state.copyWith(enableNsfw: enabled);
    saveSettings();
  }

  /// Enable/disable violence detection
  void setViolenceEnabled({required bool enabled}) {
    state = state.copyWith(enableViolence: enabled);
    saveSettings();
  }

  /// Enable/disable blood detection
  void setBloodEnabled({required bool enabled}) {
    state = state.copyWith(enableBlood: enabled);
    saveSettings();
  }

  /// Enable/disable weapons detection
  void setWeaponsEnabled({required bool enabled}) {
    state = state.copyWith(enableWeapons: enabled);
    saveSettings();
  }

  /// Enable/disable profanity detection
  void setProfanityEnabled({required bool enabled}) {
    state = state.copyWith(enableProfanity: enabled);
    saveSettings();
  }

  /// Enable/disable all visual detection types
  void setAllVisualEnabled({required bool enabled}) {
    state = state.copyWith(
      enableNsfw: enabled,
      enableViolence: enabled,
      enableBlood: enabled,
      enableWeapons: enabled,
    );
    saveSettings();
  }

  // ============================================================
  // Performance Methods
  // ============================================================

  /// Set frame sampling rate
  void setFrameSamplingRate(int rate) {
    state = state.copyWith(frameSamplingRate: rate.clamp(1, 30));
    saveSettings();
  }

  /// Enable/disable GPU acceleration
  void setGpuAcceleration({required bool enabled}) {
    state = state.copyWith(useGpuAcceleration: enabled);
    saveSettings();
  }

  /// Set number of CPU threads
  void setCpuThreads(int threads) {
    state = state.copyWith(cpuThreads: threads.clamp(1, 32));
    saveSettings();
  }

  // ============================================================
  // Preset Methods
  // ============================================================

  /// Apply strict settings
  void applyStrictSettings() {
    final strict = AnalysisSettingsState.strict();
    state = state.copyWith(
      nsfwThreshold: strict.nsfwThreshold,
      violenceThreshold: strict.violenceThreshold,
      bloodThreshold: strict.bloodThreshold,
      weaponsThreshold: strict.weaponsThreshold,
      profanityThreshold: strict.profanityThreshold,
      frameSamplingRate: strict.frameSamplingRate,
    );
    saveSettings();
  }

  /// Apply permissive settings
  void applyPermissiveSettings() {
    final permissive = AnalysisSettingsState.permissive();
    state = state.copyWith(
      nsfwThreshold: permissive.nsfwThreshold,
      violenceThreshold: permissive.violenceThreshold,
      bloodThreshold: permissive.bloodThreshold,
      weaponsThreshold: permissive.weaponsThreshold,
      profanityThreshold: permissive.profanityThreshold,
      frameSamplingRate: permissive.frameSamplingRate,
    );
    saveSettings();
  }

  /// Reset to default settings
  void resetToDefaults() {
    state = const AnalysisSettingsState();
    saveSettings();
  }
}

/// Provider for getting the current AnalysisSettings (compatibility)
@Riverpod(keepAlive: true)
AnalysisSettings currentAnalysisSettings(Ref ref) => ref.watch(analysisSettingsNotifierProvider).toAnalysisSettings();
