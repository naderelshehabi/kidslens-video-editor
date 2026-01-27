// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derived_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingDetectionsHash() => r'86b07cc14807777b86a7376360cb2a7e6ee7d364';

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
String _$detectionCountsHash() => r'fd27524e21366cc7233facf6df7b2d97552f1b73';

/// Count of each detection type
///
/// Copied from [detectionCounts].
@ProviderFor(detectionCounts)
final detectionCountsProvider =
    AutoDisposeProvider<Map<ContentType, int>>.internal(
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
typedef DetectionCountsRef = AutoDisposeProviderRef<Map<ContentType, int>>;
String _$canStartAnalysisHash() => r'b74305ac25f5642fc8d6f1b2c9dbc2aa6d6b20f7';

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
String _$canStartExportHash() => r'd9813bc1b1be32b581aa0b494af1fcad3fdfa43c';

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
    r'd0dfa1d4aa6f293fdffd8d06d0530eb2a209b217';

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
String _$detectionSummaryHash() => r'dc3395d6dc8b003ad86a105f3e52b979694fb548';

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
