import 'package:freezed_annotation/freezed_annotation.dart';

part 'gpu_info.freezed.dart';
part 'gpu_info.g.dart';

/// Type of GPU accelerator
enum AcceleratorType {
  cpu,
  cuda,
  metal,
  rocm,
  vulkan,
  oneapi,
}

/// Information about available GPU acceleration
@freezed
class AcceleratorInfo with _$AcceleratorInfo {
  const factory AcceleratorInfo({
    required AcceleratorType type,
    required String name,
    required int vramMB,
    required int recommendedBatchSize,
    String? computeCapability,
    @Default(false) bool isAppleSilicon,
  }) = _AcceleratorInfo;
  
  factory AcceleratorInfo.fromJson(Map<String, dynamic> json) =>
      _$AcceleratorInfoFromJson(json);
}

/// Hardware capabilities of the system
@freezed
class SystemCapabilities with _$SystemCapabilities {
  const factory SystemCapabilities({
    required int cpuCores,
    required int ramMB,
    required int availableRamMB,
    required int diskSpaceMB,
    required int availableDiskSpaceMB,
    AcceleratorInfo? accelerator,
    @Default([]) List<String> supportedExecutionProviders,
  }) = _SystemCapabilities;
  
  factory SystemCapabilities.fromJson(Map<String, dynamic> json) =>
      _$SystemCapabilitiesFromJson(json);
}
