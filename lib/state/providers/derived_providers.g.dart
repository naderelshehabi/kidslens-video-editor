// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derived_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingDetectionsHash() => r'3847b5efb4ff1396f1bbc0ce7c38807ec68235e7';

/// Pending detections that need user review
///
/// Copied from [pendingDetections].
@ProviderFor(pendingDetections)
final pendingDetectionsProvider = AutoDisposeProvider<List<Detection>>.internal(
  pendingDetections,
  name: r'pendingDetectionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingDetectionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingDetectionsRef = AutoDisposeProviderRef<List<Detection>>;
String _$detectionCountsHash() => r'4c8bc6863bf033817d7d8997503d765cb60a4c68';

/// Count of each detection type
///
/// Copied from [detectionCounts].
@ProviderFor(detectionCounts)
final detectionCountsProvider =
    AutoDisposeProvider<Map<DetectionType, int>>.internal(
  detectionCounts,
  name: r'detectionCountsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$detectionCountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DetectionCountsRef = AutoDisposeProviderRef<Map<DetectionType, int>>;
String _$canStartAnalysisHash() => r'f0b7ad366266fa06f20bccf96b762ecfee5702d7';

/// Whether analysis can be started
///
/// Copied from [canStartAnalysis].
@ProviderFor(canStartAnalysis)
final canStartAnalysisProvider = AutoDisposeProvider<bool>.internal(
  canStartAnalysis,
  name: r'canStartAnalysisProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canStartAnalysisHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanStartAnalysisRef = AutoDisposeProviderRef<bool>;
String _$canStartExportHash() => r'dc9c9905e8e2160497d48fa3ba0daaac8c243864';

/// Whether export can be started
///
/// Copied from [canStartExport].
@ProviderFor(canStartExport)
final canStartExportProvider = AutoDisposeProvider<bool>.internal(
  canStartExport,
  name: r'canStartExportProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canStartExportHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanStartExportRef = AutoDisposeProviderRef<bool>;
String _$totalModelDiskUsageHash() =>
    r'dec57bd16eb783294c128a3a13360414e8e95167';

/// Total disk space used by downloaded models
///
/// Copied from [totalModelDiskUsage].
@ProviderFor(totalModelDiskUsage)
final totalModelDiskUsageProvider = AutoDisposeProvider<int>.internal(
  totalModelDiskUsage,
  name: r'totalModelDiskUsageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalModelDiskUsageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalModelDiskUsageRef = AutoDisposeProviderRef<int>;
String _$detectionSummaryHash() => r'81a9afce9fa3e934a187eee2652b21e3bf4aa67f';

/// Detection statistics summary
///
/// Copied from [detectionSummary].
@ProviderFor(detectionSummary)
final detectionSummaryProvider = AutoDisposeProvider<DetectionSummary>.internal(
  detectionSummary,
  name: r'detectionSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$detectionSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DetectionSummaryRef = AutoDisposeProviderRef<DetectionSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
