// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detectionThresholdsHash() =>
    r'06d87ee11d80f57e80ca0ea7c741e2dff788de67';

/// Provider for detection thresholds (convenience accessor)
///
/// Copied from [detectionThresholds].
@ProviderFor(detectionThresholds)
final detectionThresholdsProvider = Provider<DetectionThresholds>.internal(
  detectionThresholds,
  name: r'detectionThresholdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$detectionThresholdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DetectionThresholdsRef = ProviderRef<DetectionThresholds>;
String _$settingsNotifierHash() => r'9dea4717ec75308551d333910b2cbc63b7533ee9';

/// Provider for managing application settings
///
/// Copied from [SettingsNotifier].
@ProviderFor(SettingsNotifier)
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>.internal(
  SettingsNotifier.new,
  name: r'settingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsNotifier = Notifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
