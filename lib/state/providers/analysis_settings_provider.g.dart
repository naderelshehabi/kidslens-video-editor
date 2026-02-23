// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentAnalysisSettingsHash() =>
    r'212d02471531bd402dfb74d1760d8b4a30c71ad6';

/// See also [currentAnalysisSettings].
@ProviderFor(currentAnalysisSettings)
final currentAnalysisSettingsProvider = Provider<AnalysisSettings>.internal(
  currentAnalysisSettings,
  name: r'currentAnalysisSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentAnalysisSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentAnalysisSettingsRef = ProviderRef<AnalysisSettings>;
String _$analysisSettingsNotifierHash() =>
    r'8a09197ea87c1eb4cd0ec9aaaeb7171c7e6b53d4';

/// See also [AnalysisSettingsNotifier].
@ProviderFor(AnalysisSettingsNotifier)
final analysisSettingsNotifierProvider =
    NotifierProvider<AnalysisSettingsNotifier, AnalysisSettingsState>.internal(
  AnalysisSettingsNotifier.new,
  name: r'analysisSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analysisSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalysisSettingsNotifier = Notifier<AnalysisSettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
