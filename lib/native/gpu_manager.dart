import 'dart:io';
import 'dart:math';

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
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=name,memory.total,memory.used,driver_version,temperature.gpu,utilization.gpu',
        '--format=csv,noheader,nounits',
      ]);
      
      if (result.exitCode != 0) return null;
      
      final parts = result.stdout.toString().trim().split(',').map((s) => s.trim()).toList();
      if (parts.length < 4) return null;
      
      // Get CUDA version
      String? cudaVersion;
      try {
        final cudaResult = await Process.run('nvidia-smi', ['--query-gpu=cuda_version', '--format=csv,noheader']);
        if (cudaResult.exitCode == 0) {
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
      // Check for nvidia-smi
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=name,memory.total,compute_cap',
        '--format=csv,noheader,nounits',
      ]);

      if (result.exitCode != 0) return null;

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return null;

      final parts = output.split(',').map((s) => s.trim()).toList();
      if (parts.length < 2) return null;

      final name = parts[0];
      final vramMB = int.tryParse(parts[1]) ?? 0;
      final computeCapability = parts.length > 2 ? parts[2] : null;

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
    _systemRamMB = null;
  }
}
