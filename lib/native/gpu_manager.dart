import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:kidslens_video_editor/data/models/gpu_info.dart';

/// Structured GPU information returned by getGpuInfo()
class GpuInfoDetails {
  const GpuInfoDetails({
    required this.name,
    required this.vendor,
    required this.vramMB,
    required this.driverVersion,
    required this.acceleratorType,
    this.computeCapability,
    this.cudaVersion,
    this.vulkanVersion,
    this.metalVersion,
    this.temperature,
    this.utilizationPercent,
    this.memoryUsedMB,
  });

  final String name;
  final String vendor;
  final int vramMB;
  final String driverVersion;
  final AcceleratorType acceleratorType;
  final String? computeCapability;
  final String? cudaVersion;
  final String? vulkanVersion;
  final String? metalVersion;
  final int? temperature;
  final int? utilizationPercent;
  final int? memoryUsedMB;
  
  int get memoryFreeMB => vramMB - (memoryUsedMB ?? 0);
  
  @override
  String toString() => 'GpuInfoDetails($name, $vramMB MB, $vendor)';
}

class CudaGpuDevice {
  const CudaGpuDevice({
    required this.index,
    required this.name,
    this.memoryTotalMB,
    this.computeCapability,
  });

  final int index;
  final String name;
  final int? memoryTotalMB;
  final String? computeCapability;
}

/// DirectML GPU device information (Windows)
class DirectMLDevice {
  const DirectMLDevice({
    required this.deviceId,
    required this.name,
    required this.adapterRAM,
    this.driverVersion,
  });

  final int deviceId;
  final String name;
  final int adapterRAM; // in bytes
  final String? driverVersion;

  int get vramMB => (adapterRAM / (1024 * 1024)).round();

  @override
  String toString() => 'DirectMLDevice($deviceId: $name, ${vramMB}MB)';
}

/// Result of system requirements check
class RequirementsCheckResult {
  const RequirementsCheckResult({
    required this.passed,
    required this.ramAvailable,
    required this.ramRequired,
    required this.vramAvailable,
    required this.vramRequired,
    this.warnings = const [],
    this.suggestions = const [],
  });

  final bool passed;
  final int ramAvailable;
  final int ramRequired;
  final int vramAvailable;
  final int vramRequired;
  final List<String> warnings;
  final List<String> suggestions;
  
  bool get ramSufficient => ramAvailable >= ramRequired;
  bool get vramSufficient => vramAvailable >= vramRequired;
}

/// Detect GPU capabilities and select optimal acceleration
class GPUAccelerationManager {
  AcceleratorInfo? _detectedAccelerator;
  GpuInfoDetails? _gpuDetails;
  List<CudaGpuDevice>? _cudaDevices;
  List<DirectMLDevice>? _directmlDevices;
  bool _initialized = false;
  int? _systemRamMB;

  /// Detect available GPU acceleration
  Future<AcceleratorInfo> detectAccelerator() async {
    if (_initialized) return _detectedAccelerator!;

    // Try different acceleration backends in order of preference
    _detectedAccelerator = await _tryNvidiaCuda();
    _detectedAccelerator ??= await _tryAppleMetal();
    _detectedAccelerator ??= await _tryVulkan();
    _detectedAccelerator ??= await _tryAmdRocm();
    _detectedAccelerator ??= _cpuFallback();
    
    // Cache system RAM for requirements checking
    _systemRamMB = await _getSystemRamMB();

    _initialized = true;
    return _detectedAccelerator!;
  }
  
  /// Get detailed GPU information
  /// 
  /// Returns structured data about the detected GPU including:
  /// - Hardware specifications (name, vendor, VRAM)
  /// - Driver and API versions
  /// - Real-time metrics (temperature, utilization) when available
  Future<GpuInfoDetails?> getGpuInfo() async {
    if (!_initialized) {
      await detectAccelerator();
    }
    
    if (_gpuDetails != null) {
      return _gpuDetails;
    }
    
    // Build GPU details based on accelerator type
    switch (_detectedAccelerator?.type) {
      case AcceleratorType.cuda:
        _gpuDetails = await _getNvidiaGpuDetails();
      case AcceleratorType.metal:
        _gpuDetails = await _getAppleGpuDetails();
      case AcceleratorType.vulkan:
        _gpuDetails = await _getVulkanGpuDetails();
      case AcceleratorType.rocm:
        _gpuDetails = await _getAmdGpuDetails();
      default:
        return null;
    }
    
    return _gpuDetails;
  }
  
  Future<GpuInfoDetails?> _getNvidiaGpuDetails() async {
    try {
      final result = await _runNvidiaSmi(<String>[
        '--query-gpu=name,memory.total,memory.used,driver_version,temperature.gpu,utilization.gpu',
        '--format=csv,noheader,nounits',
      ]);
      
      if (result == null || result.exitCode != 0) return null;
      
      final lines = result.stdout
          .toString()
          .trim()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) return null;
      final parts = lines.first.split(',').map((s) => s.trim()).toList();
      if (parts.length < 4) return null;
      
      // Get CUDA version
      String? cudaVersion;
      try {
        final cudaResult = await _runNvidiaSmi(<String>[
          '--query-gpu=cuda_version',
          '--format=csv,noheader',
        ]);
        if (cudaResult != null && cudaResult.exitCode == 0) {
          cudaVersion = cudaResult.stdout.toString().trim();
        }
      } catch (_) {}
      
      return GpuInfoDetails(
        name: parts[0],
        vendor: 'NVIDIA',
        vramMB: int.tryParse(parts[1]) ?? 0,
        memoryUsedMB: int.tryParse(parts[2]),
        driverVersion: parts[3],
        acceleratorType: AcceleratorType.cuda,
        temperature: parts.length > 4 ? int.tryParse(parts[4]) : null,
        utilizationPercent: parts.length > 5 ? int.tryParse(parts[5].replaceAll('%', '')) : null,
        cudaVersion: cudaVersion,
      );
    } catch (_) {
      return null;
    }
  }
  
  Future<GpuInfoDetails?> _getAppleGpuDetails() async {
    try {
      // Get GPU name using system_profiler
      final gpuResult = await Process.run('system_profiler', ['SPDisplaysDataType', '-json']);
      
      var gpuName = 'Apple GPU';
      const vendor = 'Apple';
      
      if (gpuResult.exitCode == 0) {
        // Parse minimal info from output
        final output = gpuResult.stdout.toString();
        if (output.contains('Apple M')) {
          final match = RegExp(r'Apple M\d+( Pro| Max| Ultra)?').firstMatch(output);
          if (match != null) {
            gpuName = match.group(0)!;
          }
        }
      }
      
      // Get macOS version for Metal version approximation
      final osResult = await Process.run('sw_vers', ['-productVersion']);
      final osVersion = osResult.stdout.toString().trim();
      var metalVersion = 'Metal 3';
      if (osVersion.startsWith('12.')) {
        metalVersion = 'Metal 2.4';
      } else if (osVersion.startsWith('11.')) {
        metalVersion = 'Metal 2.3';
      }
      
      return GpuInfoDetails(
        name: gpuName,
        vendor: vendor,
        vramMB: _detectedAccelerator?.vramMB ?? 0,
        driverVersion: osVersion,
        acceleratorType: AcceleratorType.metal,
        metalVersion: metalVersion,
      );
    } catch (_) {
      return null;
    }
  }
  
  Future<GpuInfoDetails?> _getVulkanGpuDetails() async {
    // Vulkan details populated during _tryVulkan()
    if (_detectedAccelerator?.type != AcceleratorType.vulkan) return null;
    
    return GpuInfoDetails(
      name: _detectedAccelerator?.name ?? 'Vulkan GPU',
      vendor: 'Unknown',
      vramMB: _detectedAccelerator?.vramMB ?? 0,
      driverVersion: 'Unknown',
      acceleratorType: AcceleratorType.vulkan,
      vulkanVersion: '1.3', // Would be populated from vulkaninfo
    );
  }
  
  Future<GpuInfoDetails?> _getAmdGpuDetails() async {
    try {
      // Try rocm-smi for AMD GPUs
      final result = await Process.run('rocm-smi', ['--showproductname', '--showmeminfo', 'vram']);
      
      if (result.exitCode != 0) return null;
      
      final output = result.stdout.toString();
      var gpuName = 'AMD GPU';
      var vramMB = 0;
      
      // Parse product name
      final nameMatch = RegExp(r'GPU\[\d+\].*?:\s*(.+)').firstMatch(output);
      if (nameMatch != null) {
        gpuName = nameMatch.group(1)!.trim();
      }
      
      // Parse VRAM
      final vramMatch = RegExp(r'VRAM Total Memory.*?:\s*(\d+)').firstMatch(output);
      if (vramMatch != null) {
        vramMB = int.tryParse(vramMatch.group(1)!) ?? 0;
      }
      
      return GpuInfoDetails(
        name: gpuName,
        vendor: 'AMD',
        vramMB: vramMB,
        driverVersion: 'ROCm',
        acceleratorType: AcceleratorType.rocm,
      );
    } catch (_) {
      return null;
    }
  }
  
  /// Check if system meets memory requirements
  /// 
  /// [ramRequired] Required system RAM in MB
  /// [vramRequired] Required GPU VRAM in MB (0 for CPU-only workloads)
  /// 
  /// Returns detailed result with pass/fail status and suggestions
  Future<RequirementsCheckResult> checkRequirements(int ramRequired, int vramRequired) async {
    if (!_initialized) {
      await detectAccelerator();
    }
    
    final systemRam = _systemRamMB ?? 0;
    final vramAvailable = _detectedAccelerator?.vramMB ?? 0;
    
    final warnings = <String>[];
    final suggestions = <String>[];
    
    // Check RAM
    if (systemRam < ramRequired) {
      warnings.add('Insufficient system RAM: ${systemRam}MB available, ${ramRequired}MB required');
      suggestions.add('Close other applications to free memory');
      if (systemRam < ramRequired * 0.5) {
        suggestions.add('Consider upgrading system RAM for better performance');
      }
    }
    
    // Check VRAM
    if (vramRequired > 0) {
      if (vramAvailable < vramRequired) {
        if (_detectedAccelerator?.type == AcceleratorType.cpu) {
          warnings.add('No GPU detected. VRAM requirement: ${vramRequired}MB');
          suggestions
            ..add('Install compatible GPU for hardware acceleration')
            ..add('Alternatively, reduce batch size or use smaller models');
        } else {
          warnings.add('Insufficient VRAM: ${vramAvailable}MB available, ${vramRequired}MB required');
          suggestions
            ..add('Use a smaller model or reduce batch size')
            ..add('Close other GPU-intensive applications');
        }
      } else if (vramAvailable < vramRequired * 1.2) {
        // Warn if less than 20% headroom
        warnings.add('Low VRAM headroom: ${vramAvailable}MB available, ${vramRequired}MB required');
        suggestions.add('Performance may be reduced due to memory swapping');
      }
    }
    
    final passed = systemRam >= ramRequired && 
                   (vramRequired == 0 || vramAvailable >= vramRequired);
    
    return RequirementsCheckResult(
      passed: passed,
      ramAvailable: systemRam,
      ramRequired: ramRequired,
      vramAvailable: vramAvailable,
      vramRequired: vramRequired,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Get available DirectML devices (Windows only)
  /// 
  /// Returns list of DirectML-capable GPUs using WMI query
  Future<List<DirectMLDevice>> getDirectMLDevices() async {
    if (_directmlDevices != null) return _directmlDevices!;
    if (!Platform.isWindows) return const [];

    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-WmiObject -Class Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | ConvertTo-Json',
        ],
        runInShell: true,
      );

      if (result.exitCode != 0) return const [];

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return const [];

      // Parse JSON output
      final devices = <DirectMLDevice>[];
      try {
        // Handle both single object and array
        final List<dynamic> jsonData;
        if (output.startsWith('[')) {
          jsonData = jsonDecode(output) as List<dynamic>;
        } else {
          jsonData = [jsonDecode(output)];
        }

        var deviceId = 0;
        for (final item in jsonData) {
          final itemMap = item as Map<String, dynamic>;
          final name = itemMap['Name'] as String? ?? 'Unknown GPU';
          final ram = itemMap['AdapterRAM'] as int? ?? 0;
          final driver = itemMap['DriverVersion'] as String?;

          devices.add(
            DirectMLDevice(
              deviceId: deviceId++,
              name: name,
              adapterRAM: ram,
              driverVersion: driver,
            ),
          );
        }
      } catch (_) {
        // Parsing failed, return empty list
        return const [];
      }

      devices.sort((a, b) => a.deviceId.compareTo(b.deviceId));
      _directmlDevices = devices;
      return devices;
    } catch (_) {
      return const [];
    }
  }

  /// Query available ONNX Runtime execution providers
  /// 
  /// Returns a list of provider names that can be used with the current system
  Future<List<String>> queryAvailableProviders() async {
    final providers = <String>[
      // Always available
      'CPUExecutionProvider',
    ];

    // Check CUDA
    if (Platform.isWindows || Platform.isLinux) {
      final cudaDevices = await getCudaDevices();
      if (cudaDevices.isNotEmpty) {
        providers.add('CUDAExecutionProvider');
      }
    }

    // Check DirectML
    if (Platform.isWindows) {
      final directMLDevices = await getDirectMLDevices();
      if (directMLDevices.isNotEmpty) {
        providers.add('DmlExecutionProvider');
      }
    }

    // Check CoreML
    if (Platform.isMacOS) {
      // CoreML is available on all modern macOS systems
      providers.add('CoreMLExecutionProvider');
    }

    // Check ROCm
    if (Platform.isLinux) {
      try {
        final result = await Process.run('which', ['rocm-smi']);
        if (result.exitCode == 0) {
          providers.add('ROCMExecutionProvider');
        }
      } catch (_) {}
    }

    return providers;
  }
  
  Future<int> _getSystemRamMB() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', ['OS', 'get', 'TotalVisibleMemorySize', '/value']);
        final match = RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(result.stdout.toString());
        if (match != null) {
          // wmic returns KB, convert to MB
          return (int.parse(match.group(1)!) / 1024).round();
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('sysctl', ['-n', 'hw.memsize']);
        final bytes = int.tryParse(result.stdout.toString().trim()) ?? 0;
        return bytes ~/ (1024 * 1024);
      } else if (Platform.isLinux) {
        final result = await Process.run('grep', ['MemTotal', '/proc/meminfo']);
        final match = RegExp(r'MemTotal:\s*(\d+)').firstMatch(result.stdout.toString());
        if (match != null) {
          // /proc/meminfo returns kB, convert to MB
          return (int.parse(match.group(1)!) / 1024).round();
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<AcceleratorInfo?> _tryNvidiaCuda() async {
    if (!Platform.isWindows && !Platform.isLinux) return null;

    try {
      final devices = await getCudaDevices();
      if (devices.isEmpty) return null;
      final first = devices.first;
      final name = first.name;
      final vramMB = first.memoryTotalMB ?? 0;
      final computeCapability = first.computeCapability;

      return AcceleratorInfo(
        type: AcceleratorType.cuda,
        name: name,
        vramMB: vramMB,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
        computeCapability: computeCapability,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<CudaGpuDevice>> getCudaDevices() async {
    if (_cudaDevices != null) return _cudaDevices!;
    if (!Platform.isWindows && !Platform.isLinux) return const [];

    try {
      final result = await _runNvidiaSmi(<String>[
        '--query-gpu=index,name,memory.total',
        '--format=csv,noheader,nounits',
      ]);
      if (result == null || result.exitCode != 0) return const [];

      final lines = result.stdout
          .toString()
          .trim()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) return const [];

      List<String>? computeCaps;
      try {
        final capResult = await _runNvidiaSmi(<String>[
          '--query-gpu=compute_cap',
          '--format=csv,noheader,nounits',
        ]);
        if (capResult != null && capResult.exitCode == 0) {
          final caps = capResult.stdout
              .toString()
              .trim()
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          if (caps.isNotEmpty) {
            computeCaps = caps;
          }
        }
      } catch (_) {
        computeCaps = null;
      }

      final devices = <CudaGpuDevice>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final parts = line.split(',').map((s) => s.trim()).toList();
        if (parts.length < 3) continue;
        final index = int.tryParse(parts[0]);
        if (index == null) continue;
        devices.add(
          CudaGpuDevice(
            index: index,
            name: parts[1],
            memoryTotalMB: int.tryParse(parts[2]),
            computeCapability:
                computeCaps != null && i < computeCaps.length ? computeCaps[i] : null,
          ),
        );
      }

      devices.sort((a, b) => a.index.compareTo(b.index));
      _cudaDevices = devices;
      return devices;
    } catch (_) {
      return const [];
    }
  }

  /// Map a CUDA device index to the corresponding DirectML device index
  ///
  /// This is necessary because DirectML enumerates ALL GPUs (integrated + discrete),
  /// while CUDA only shows NVIDIA GPUs. For example, on a laptop with Intel iGPU
  /// and NVIDIA dGPU:
  /// - CUDA GPU 0 = NVIDIA dGPU
  /// - DirectML GPU 0 = Intel iGPU, DirectML GPU 1 = NVIDIA dGPU
  ///
  /// Returns the mapped DirectML device index. Falls back to searching for any
  /// NVIDIA/discrete GPU in the DirectML list if name matching fails.
  Future<int> mapCudaToDirectMLDeviceIndex(int cudaIndex) async {
    final cudaDevices = await getCudaDevices();
    final directmlDevices = await getDirectMLDevices();

    if (directmlDevices.isEmpty) {
      return 0; // No DirectML devices; use default
    }
    if (directmlDevices.length == 1) {
      return directmlDevices.first.deviceId; // Only one GPU, use it
    }
    if (cudaDevices.isEmpty) {
      // No CUDA devices enumerated; find any NVIDIA GPU in DirectML list
      return _findDiscreteGpuInDirectML(directmlDevices);
    }

    // Get the CUDA device at the specified index
    final cudaDevice =
        cudaDevices.where((d) => d.index == cudaIndex).firstOrNull;
    if (cudaDevice == null) {
      // Invalid CUDA index; find any NVIDIA GPU in DirectML list
      debugPrint(
        'GPU mapping: CUDA device index $cudaIndex not found '
        '(available: ${cudaDevices.map((d) => d.index).toList()}). '
        'Searching DirectML devices by name.',
      );
      return _findDiscreteGpuInDirectML(directmlDevices);
    }

    // Find matching DirectML device by name (strict matching)
    for (final dmlDevice in directmlDevices) {
      if (_deviceNamesMatch(cudaDevice.name, dmlDevice.name)) {
        return dmlDevice.deviceId;
      }
    }

    // Name matching failed; find any NVIDIA/discrete GPU in DirectML list
    debugPrint(
      'GPU mapping: Could not match CUDA device "${cudaDevice.name}" '
      'to any DirectML device by name. '
      'DirectML devices: ${directmlDevices.map((d) => '${d.deviceId}:${d.name}').toList()}. '
      'Searching for discrete GPU.',
    );
    return _findDiscreteGpuInDirectML(directmlDevices);
  }

  /// Find a discrete (non-integrated) GPU in the DirectML device list.
  ///
  /// Prefers NVIDIA GPUs, then any non-Intel/non-integrated GPU.
  /// Falls back to device 0 if no discrete GPU found.
  int _findDiscreteGpuInDirectML(List<DirectMLDevice> devices) {
    // First pass: look for NVIDIA GPU
    for (final device in devices) {
      final nameLower = device.name.toLowerCase();
      if (nameLower.contains('nvidia') || nameLower.contains('geforce') ||
          nameLower.contains('quadro') || nameLower.contains('tesla')) {
        return device.deviceId;
      }
    }
    // Second pass: look for AMD discrete GPU (not integrated)
    for (final device in devices) {
      final nameLower = device.name.toLowerCase();
      if ((nameLower.contains('amd') || nameLower.contains('radeon')) &&
          !nameLower.contains('integrated') &&
          !nameLower.contains('vega') &&  // Vega iGPUs
          device.vramMB > 1024) {  // Discrete GPUs have >1GB VRAM
        return device.deviceId;
      }
    }
    // Final fallback: return first device
    return devices.first.deviceId;
  }

  /// Check if two GPU names refer to the same device.
  ///
  /// Uses multiple matching strategies in order of reliability:
  /// 1. Direct substring containment
  /// 2. NVIDIA model number matching (e.g., "3060", "4090")
  /// 3. GPU series + model number matching (e.g., "RTX 4090")
  ///
  /// Does NOT assume two arbitrary NVIDIA GPUs are the same device.
  bool _deviceNamesMatch(String name1, String name2) {
    final n1 = name1.toLowerCase().trim();
    final n2 = name2.toLowerCase().trim();

    // Direct substring match (handles cases like "NVIDIA GeForce RTX 4090"
    // contained in the other string)
    if (n1.contains(n2) || n2.contains(n1)) return true;

    // Normalize whitespace and common separators for comparison
    final norm1 = n1.replaceAll(RegExp(r'[\s_-]+'), ' ');
    final norm2 = n2.replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (norm1.contains(norm2) || norm2.contains(norm1)) return true;

    // Extract GPU model identifiers for matching
    // Match patterns like: RTX 4090, GTX 1080, RTX A6000, Quadro P5000, etc.
    final modelPattern = RegExp(
      r'(rtx|gtx|quadro|tesla|a)\s*(\d{3,5})',
      caseSensitive: false,
    );
    final models1 = modelPattern.allMatches(norm1).toList();
    final models2 = modelPattern.allMatches(norm2).toList();

    if (models1.isNotEmpty && models2.isNotEmpty) {
      // Compare extracted model identifiers
      for (final m1 in models1) {
        for (final m2 in models2) {
          final series1 = m1.group(1)!.toLowerCase();
          final number1 = m1.group(2)!;
          final series2 = m2.group(1)!.toLowerCase();
          final number2 = m2.group(2)!;
          if (series1 == series2 && number1 == number2) return true;
        }
      }
      // Both have model identifiers but they differ → different devices
      return false;
    }

    // Fallback: extract any 4-digit model number
    final digits1 = RegExp(r'\b(\d{4})\b').allMatches(norm1).map((m) => m.group(1)!).toSet();
    final digits2 = RegExp(r'\b(\d{4})\b').allMatches(norm2).map((m) => m.group(1)!).toSet();
    if (digits1.isNotEmpty && digits2.isNotEmpty) {
      return digits1.intersection(digits2).isNotEmpty;
    }

    // Cannot determine — do not assume they match
    return false;
  }

  Future<AcceleratorInfo?> _tryAppleMetal() async {
    if (!Platform.isMacOS) return null;

    try {
      // Check for Apple Silicon
      final result = await Process.run('sysctl', ['-n', 'machdep.cpu.brand_string']);
      final cpuBrand = result.stdout.toString().trim();
      final isAppleSilicon = cpuBrand.contains('Apple');

      // Get memory info
      final memResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final memBytes = int.tryParse(memResult.stdout.toString().trim()) ?? 0;
      final memMB = memBytes ~/ (1024 * 1024);

      // Apple Silicon shares unified memory
      final vramMB = isAppleSilicon ? (memMB ~/ 2) : 2048;

      return AcceleratorInfo(
        type: AcceleratorType.metal,
        name: isAppleSilicon ? 'Apple Silicon GPU' : 'Intel/AMD GPU',
        vramMB: vramMB,
        isAppleSilicon: isAppleSilicon,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
      );
    } catch (_) {
      return null;
    }
  }

  /// Detect Vulkan-capable GPUs
  /// 
  /// Implementation Details:
  /// 1. Try running vulkaninfo to detect Vulkan support
  /// 2. On Windows, also check for Intel/AMD GPUs via dxdiag fallback
  /// 3. Parse GPU name and memory from vulkaninfo output
  /// 4. Return AcceleratorInfo with Vulkan type if found
  Future<AcceleratorInfo?> _tryVulkan() async {
    try {
      // Try vulkaninfo first (available if Vulkan SDK or drivers installed)
      ProcessResult? vulkanResult;
      
      if (Platform.isWindows) {
        // Try common Vulkan SDK locations
        final vulkanPaths = [
          'vulkaninfo',
          r'C:\VulkanSDK\vulkaninfo.exe',
          r'%VULKAN_SDK%\Bin\vulkaninfo.exe',
        ];
        
        for (final path in vulkanPaths) {
          try {
            vulkanResult = await Process.run(path, ['--summary']);
            if (vulkanResult.exitCode == 0) break;
          } catch (_) {
            continue;
          }
        }
      } else if (Platform.isLinux) {
        vulkanResult = await Process.run('vulkaninfo', ['--summary']);
      }
      
      if (vulkanResult != null && vulkanResult.exitCode == 0) {
        final output = vulkanResult.stdout.toString();
        
        // Parse GPU name from vulkaninfo output
        // Format varies but typically: "GPU0: NVIDIA GeForce RTX 3080" or similar
        String? gpuName;
        var vramMB = 2048; // Default estimate
        
        final gpuMatch = RegExp(r'GPU\d+:\s*(.+)').firstMatch(output);
        if (gpuMatch != null) {
          gpuName = gpuMatch.group(1)?.trim();
        }
        
        // Try to extract memory size
        final memMatch = RegExp(r'deviceLocalMemory:\s*(\d+)\s*MB', caseSensitive: false).firstMatch(output);
        if (memMatch != null) {
          vramMB = int.tryParse(memMatch.group(1)!) ?? vramMB;
        }
        
        // Fallback memory detection from heap size
        if (vramMB == 2048) {
          final heapMatch = RegExp(r'size\s*=\s*(\d+)\s*\(').firstMatch(output);
          if (heapMatch != null) {
            final heapBytes = int.tryParse(heapMatch.group(1)!) ?? 0;
            if (heapBytes > 0) {
              vramMB = heapBytes ~/ (1024 * 1024);
            }
          }
        }
        
        if (gpuName != null && gpuName.isNotEmpty) {
          return AcceleratorInfo(
            type: AcceleratorType.vulkan,
            name: gpuName,
            vramMB: vramMB,
            recommendedBatchSize: _calculateOptimalBatch(vramMB),
          );
        }
      }
      
      // Fallback for Windows: try dxdiag for basic GPU detection
      if (Platform.isWindows) {
        return await _tryWindowsDxDiag();
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Windows fallback using dxdiag for GPU detection
  Future<AcceleratorInfo?> _tryWindowsDxDiag() async {
    try {
      // Use wmic for faster GPU detection than dxdiag
      final result = await Process.run('wmic', [
        'path', 'win32_VideoController', 
        'get', 'name,AdapterRAM',
        '/format:csv',
      ]);
      
      if (result.exitCode != 0) return null;
      
      final lines = result.stdout.toString().split('\n')
          .where((l) => l.trim().isNotEmpty && !l.contains('Node'))
          .toList();
      
      if (lines.isEmpty) return null;
      
      // Parse first GPU entry
      final parts = lines.first.split(',');
      if (parts.length < 3) return null;
      
      final adapterRam = int.tryParse(parts[1]) ?? 0;
      final gpuName = parts[2].trim();
      final vramMB = adapterRam ~/ (1024 * 1024);
      
      // Skip if it's an integrated GPU with minimal VRAM
      if (vramMB < 512) return null;
      
      return AcceleratorInfo(
        type: AcceleratorType.vulkan,
        name: gpuName,
        vramMB: vramMB,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
      );
    } catch (_) {
      return null;
    }
  }
  
  /// Detect AMD ROCm GPUs (Linux)
  Future<AcceleratorInfo?> _tryAmdRocm() async {
    if (!Platform.isLinux) return null;
    
    try {
      final result = await Process.run('rocm-smi', ['--showproductname']);
      
      if (result.exitCode != 0) return null;
      
      final output = result.stdout.toString();
      final nameMatch = RegExp(r'GPU\[\d+\].*?:\s*(.+)').firstMatch(output);
      
      if (nameMatch == null) return null;
      
      final gpuName = nameMatch.group(1)!.trim();
      
      // Get VRAM
      final memResult = await Process.run('rocm-smi', ['--showmeminfo', 'vram']);
      var vramMB = 8192; // Default estimate for AMD GPUs
      
      if (memResult.exitCode == 0) {
        final memMatch = RegExp(r'Total Memory.*?:\s*(\d+)').firstMatch(memResult.stdout.toString());
        if (memMatch != null) {
          vramMB = int.tryParse(memMatch.group(1)!) ?? vramMB;
        }
      }
      
      return AcceleratorInfo(
        type: AcceleratorType.rocm,
        name: gpuName,
        vramMB: vramMB,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
      );
    } catch (_) {
      return null;
    }
  }

  AcceleratorInfo _cpuFallback() => const AcceleratorInfo(
        type: AcceleratorType.cpu,
        name: 'CPU (No GPU acceleration)',
        vramMB: 0,
        recommendedBatchSize: 1,
      );

  int _calculateOptimalBatch(int vramMB) {
    // Assuming ~200MB per batch item for typical models
    final maxBatch = vramMB ~/ 200;
    return min(max(maxBatch, 1), 16); // Clamp to 1-16
  }

  /// Get ONNX execution providers in priority order
  List<String> getOnnxExecutionProviders() {
    switch (_detectedAccelerator?.type) {
      case AcceleratorType.cuda:
        return ['CUDAExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.metal:
        return ['CoreMLExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.rocm:
        return ['ROCMExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.vulkan:
        return ['CPUExecutionProvider'];
      case AcceleratorType.oneapi:
        return ['DnnlExecutionProvider', 'CPUExecutionProvider'];
      default:
        return ['CPUExecutionProvider'];
    }
  }

  /// Check if GPU acceleration is available
  bool get hasGpuAcceleration =>
      _detectedAccelerator?.type != AcceleratorType.cpu;

  /// Get the detected accelerator info
  AcceleratorInfo? get accelerator => _detectedAccelerator;
  
  /// Reset detection state (useful for re-detection after hardware changes)
  void reset() {
    _initialized = false;
    _detectedAccelerator = null;
    _gpuDetails = null;
    _cudaDevices = null;
    _directmlDevices = null;
    _systemRamMB = null;
  }

  Future<ProcessResult?> _runNvidiaSmi(List<String> args) async {
    final candidates = <String>[
      'nvidia-smi',
      if (Platform.isWindows)
        r'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe',
    ];

    for (final cmd in candidates) {
      try {
        final result = await Process.run(
          cmd,
          args,
          runInShell: Platform.isWindows,
        );
        if (result.exitCode == 0) {
          return result;
        }
      } catch (_) {
        // try next candidate
      }
    }
    return null;
  }
}
