// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detectionThresholdsHash() =>
    r'106445558641efb0c2a97a44a2fce46b1cb2bc44';

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
String _$settingsNotifierHash() => r'75767ce1aca67256c0043245a8520a0c47f5989a';

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
