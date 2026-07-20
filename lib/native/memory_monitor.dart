import 'dart:async';
import 'dart:io';

/// Monitor system memory and trigger pressure handling
class MemoryMonitor {
  static const Duration checkInterval = Duration(seconds: 5);
  static const double warningThreshold = 0.8; // 80% memory used
  static const double criticalThreshold = 0.9; // 90% memory used

  Timer? _timer;
  final List<MemoryPressureCallback> _callbacks = [];

  int _totalMemoryMB = 0;
  int _availableMemoryMB = 0;

  /// Start monitoring memory
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(checkInterval, (_) => _checkMemory());
    _checkMemory();
  }

  /// Stop monitoring memory
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Register a callback for memory pressure events
  void onMemoryPressure(MemoryPressureCallback callback) {
    _callbacks.add(callback);
  }

  /// Remove a memory pressure callback
  void removeCallback(MemoryPressureCallback callback) {
    _callbacks.remove(callback);
  }

  Future<void> _checkMemory() async {
    try {
      await _updateMemoryInfo();

      if (_totalMemoryMB == 0) return;

      final usedRatio = 1.0 - (_availableMemoryMB / _totalMemoryMB);

      if (usedRatio >= criticalThreshold) {
        _notifyCallbacks(MemoryPressureLevel.critical);
      } else if (usedRatio >= warningThreshold) {
        _notifyCallbacks(MemoryPressureLevel.warning);
      }
    } catch (_) {
      // Ignore errors during memory check
    }
  }

  Future<void> _updateMemoryInfo() async {
    if (Platform.isWindows) {
      await _updateWindowsMemory();
    } else if (Platform.isMacOS) {
      await _updateMacOSMemory();
    } else if (Platform.isLinux) {
      await _updateLinuxMemory();
    }
  }

  Future<void> _updateWindowsMemory() async {
    try {
      final result = await Process.run('wmic', [
        'OS',
        'get',
        'TotalVisibleMemorySize,FreePhysicalMemory',
        '/format:csv',
      ]);

      final lines = result.stdout.toString().trim().split('\n');
      if (lines.length >= 2) {
        final parts = lines[1].split(',');
        if (parts.length >= 3) {
          // Values are in KB
          _availableMemoryMB = (int.tryParse(parts[1]) ?? 0) ~/ 1024;
          _totalMemoryMB = (int.tryParse(parts[2]) ?? 0) ~/ 1024;
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _updateMacOSMemory() async {
    try {
      // Get total memory
      var result = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final totalBytes = int.tryParse(result.stdout.toString().trim()) ?? 0;
      _totalMemoryMB = totalBytes ~/ (1024 * 1024);

      // Get page size and free pages
      result = await Process.run('vm_stat', []);
      final output = result.stdout.toString();

      final pageSizeMatch =
          RegExp(r'page size of (\d+) bytes').firstMatch(output);
      final pageSize = int.tryParse(pageSizeMatch?.group(1) ?? '') ?? 4096;

      final freeMatch = RegExp(r'Pages free:\s+(\d+)').firstMatch(output);
      final freePages = int.tryParse(freeMatch?.group(1) ?? '') ?? 0;

      _availableMemoryMB = (freePages * pageSize) ~/ (1024 * 1024);
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _updateLinuxMemory() async {
    try {
      final file = File('/proc/meminfo');
      final content = await file.readAsString();

      final totalMatch = RegExp(r'MemTotal:\s+(\d+)').firstMatch(content);
      _totalMemoryMB = (int.tryParse(totalMatch?.group(1) ?? '') ?? 0) ~/ 1024;

      final availableMatch =
          RegExp(r'MemAvailable:\s+(\d+)').firstMatch(content);
      _availableMemoryMB =
          (int.tryParse(availableMatch?.group(1) ?? '') ?? 0) ~/ 1024;
    } catch (_) {
      // Ignore errors
    }
  }

  void _notifyCallbacks(MemoryPressureLevel level) {
    for (final callback in _callbacks) {
      callback(level, _availableMemoryMB, _totalMemoryMB);
    }
  }

  /// Get current memory usage percentage
  double get memoryUsageRatio {
    if (_totalMemoryMB == 0) return 0;
    return 1.0 - (_availableMemoryMB / _totalMemoryMB);
  }

  /// Get available memory in MB
  int get availableMemoryMB => _availableMemoryMB;

  /// Get total memory in MB
  int get totalMemoryMB => _totalMemoryMB;
}

/// Memory pressure level
enum MemoryPressureLevel {
  normal,
  warning,
  critical,
}

/// Callback type for memory pressure events
typedef MemoryPressureCallback = void Function(
  MemoryPressureLevel level,
  int availableMB,
  int totalMB,
);
