import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// Export quality options
enum ExportQuality {
  low(480, 'Low (480p)'),
  medium(720, 'Medium (720p)'),
  high(1080, 'High (1080p)'),
  ultra(2160, 'Ultra (4K)');

  const ExportQuality(this.height, this.displayName);
  final int height;
  final String displayName;
}

/// Export format options
enum ExportFormat {
  mp4('mp4', 'MP4 (H.264)'),
  webm('webm', 'WebM (VP9)'),
  mov('mov', 'MOV (ProRes)');

  const ExportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

/// Application settings state
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
    this.detectionThresholds = const DetectionThresholds(),
  }) : analysisSettings = analysisSettings ?? AnalysisSettings.defaults();

  /// Create from JSON for persistence
  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
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
        detectionThresholds: json['detectionThresholds'] != null
            ? DetectionThresholds.fromJson(
                json['detectionThresholds'] as Map<String, dynamic>,
              )
            : const DetectionThresholds(),
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
  final DetectionThresholds detectionThresholds;

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
    DetectionThresholds? detectionThresholds,
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
        detectionThresholds: detectionThresholds ?? this.detectionThresholds,
      );

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'selectedLanguage': selectedLanguage,
        'themeMode': themeMode.index,
        'useDarkTheme': useDarkTheme,
        'showOnboarding': showOnboarding,
        'modelCachePath': modelCachePath,
        'exportPath': exportPath,
        'defaultExportQuality': defaultExportQuality.index,
        'defaultExportFormat': defaultExportFormat.index,
        'autoSaveIntervalMinutes': autoSaveInterval.inMinutes,
        'detectionThresholds': detectionThresholds.toJson(),
      };
}

/// Detection thresholds for different content types
class DetectionThresholds {
  const DetectionThresholds({
    this.nsfwThreshold = 0.6,
    this.violenceThreshold = 0.6,
    this.bloodThreshold = 0.6,
    this.weaponsThreshold = 0.6,
    this.profanityConfidence = 0.8,
  });

  factory DetectionThresholds.fromJson(Map<String, dynamic> json) =>
      DetectionThresholds(
        nsfwThreshold: (json['nsfwThreshold'] as num?)?.toDouble() ?? 0.6,
        violenceThreshold:
            (json['violenceThreshold'] as num?)?.toDouble() ?? 0.6,
        bloodThreshold: (json['bloodThreshold'] as num?)?.toDouble() ?? 0.6,
        weaponsThreshold: (json['weaponsThreshold'] as num?)?.toDouble() ?? 0.6,
        profanityConfidence:
            (json['profanityConfidence'] as num?)?.toDouble() ?? 0.8,
      );

  /// Strict thresholds (more sensitive detection)
  factory DetectionThresholds.strict() => const DetectionThresholds(
        nsfwThreshold: 0.4,
        violenceThreshold: 0.4,
        bloodThreshold: 0.4,
        weaponsThreshold: 0.4,
        profanityConfidence: 0.7,
      );

  /// Permissive thresholds (fewer false positives)
  factory DetectionThresholds.permissive() => const DetectionThresholds(
        nsfwThreshold: 0.8,
        violenceThreshold: 0.8,
        bloodThreshold: 0.8,
        weaponsThreshold: 0.8,
        profanityConfidence: 0.9,
      );

  final double nsfwThreshold;
  final double violenceThreshold;
  final double bloodThreshold;
  final double weaponsThreshold;
  final double profanityConfidence;

  DetectionThresholds copyWith({
    double? nsfwThreshold,
    double? violenceThreshold,
    double? bloodThreshold,
    double? weaponsThreshold,
    double? profanityConfidence,
  }) =>
      DetectionThresholds(
        nsfwThreshold: nsfwThreshold ?? this.nsfwThreshold,
        violenceThreshold: violenceThreshold ?? this.violenceThreshold,
        bloodThreshold: bloodThreshold ?? this.bloodThreshold,
        weaponsThreshold: weaponsThreshold ?? this.weaponsThreshold,
        profanityConfidence: profanityConfidence ?? this.profanityConfidence,
      );

  Map<String, dynamic> toJson() => {
        'nsfwThreshold': nsfwThreshold,
        'violenceThreshold': violenceThreshold,
        'bloodThreshold': bloodThreshold,
        'weaponsThreshold': weaponsThreshold,
        'profanityConfidence': profanityConfidence,
      };
}

/// Provider for managing application settings
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const String _prefsKey = 'kidslens_settings';

  @override
  SettingsState build() => SettingsState();

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = SettingsState.fromJson(json);
      }
    } catch (e) {
      // If loading fails, keep default settings
      state = SettingsState();
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

  void updateAnalysisSettings(AnalysisSettings settings) {
    state = state.copyWith(analysisSettings: settings);
    saveSettings();
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

  void setDetectionThresholds(DetectionThresholds thresholds) {
    state = state.copyWith(detectionThresholds: thresholds);
    saveSettings();
  }

  void updateNsfwThreshold(double threshold) {
    state = state.copyWith(
      detectionThresholds: state.detectionThresholds.copyWith(
        nsfwThreshold: threshold.clamp(0.0, 1.0),
      ),
    );
    saveSettings();
  }

  void updateViolenceThreshold(double threshold) {
    state = state.copyWith(
      detectionThresholds: state.detectionThresholds.copyWith(
        violenceThreshold: threshold.clamp(0.0, 1.0),
      ),
    );
    saveSettings();
  }

  void updateBloodThreshold(double threshold) {
    state = state.copyWith(
      detectionThresholds: state.detectionThresholds.copyWith(
        bloodThreshold: threshold.clamp(0.0, 1.0),
      ),
    );
    saveSettings();
  }

  void updateWeaponsThreshold(double threshold) {
    state = state.copyWith(
      detectionThresholds: state.detectionThresholds.copyWith(
        weaponsThreshold: threshold.clamp(0.0, 1.0),
      ),
    );
    saveSettings();
  }

  void updateProfanityConfidence(double confidence) {
    state = state.copyWith(
      detectionThresholds: state.detectionThresholds.copyWith(
        profanityConfidence: confidence.clamp(0.0, 1.0),
      ),
    );
    saveSettings();
  }

  void resetToDefaults() {
    state = SettingsState();
    saveSettings();
  }
}

/// Provider for detection thresholds (convenience accessor)
@Riverpod(keepAlive: true)
DetectionThresholds detectionThresholds(Ref ref) =>
    ref.watch(settingsNotifierProvider).detectionThresholds;
