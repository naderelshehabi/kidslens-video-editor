import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

/// Application settings state
class SettingsState {
  SettingsState({
    AnalysisSettings? analysisSettings,
    this.selectedLanguage,
    this.useDarkTheme = false,
    this.showOnboarding = true,
    this.modelCachePath,
    this.exportPath,
  }) : analysisSettings = analysisSettings ?? AnalysisSettings.defaults();

  final AnalysisSettings analysisSettings;
  final String? selectedLanguage;
  final bool useDarkTheme;
  final bool showOnboarding;
  final String? modelCachePath;
  final String? exportPath;

  SettingsState copyWith({
    AnalysisSettings? analysisSettings,
    String? selectedLanguage,
    bool? useDarkTheme,
    bool? showOnboarding,
    String? modelCachePath,
    String? exportPath,
  }) =>
      SettingsState(
        analysisSettings: analysisSettings ?? this.analysisSettings,
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        useDarkTheme: useDarkTheme ?? this.useDarkTheme,
        showOnboarding: showOnboarding ?? this.showOnboarding,
        modelCachePath: modelCachePath ?? this.modelCachePath,
        exportPath: exportPath ?? this.exportPath,
      );
}

/// Provider for managing application settings
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() => SettingsState();

  void updateAnalysisSettings(AnalysisSettings settings) {
    state = state.copyWith(analysisSettings: settings);
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  void setDarkTheme({required bool useDark}) {
    state = state.copyWith(useDarkTheme: useDark);
  }

  void setOnboardingComplete() {
    state = state.copyWith(showOnboarding: false);
  }

  void setModelCachePath(String path) {
    state = state.copyWith(modelCachePath: path);
  }

  void setExportPath(String path) {
    state = state.copyWith(exportPath: path);
  }

  void resetToDefaults() {
    state = SettingsState();
  }
}
