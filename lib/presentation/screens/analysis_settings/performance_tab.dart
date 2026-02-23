import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/gpu_info.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/hardware_requirements.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/parameter_slider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for configuring performance settings
class PerformanceTab extends ConsumerStatefulWidget {
  const PerformanceTab({super.key});

  @override
  ConsumerState<PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends ConsumerState<PerformanceTab> {
  /// System capabilities detected from actual hardware
  SystemCapabilities? _systemCapabilities;
  GpuInfoDetails? _gpuDetails;
  List<CudaGpuDevice> _cudaDevices = const [];
  List<DirectMLDevice> _directmlDevices = const []; // Reserved for future DirectML device selection UI
  List<String> _availableProviders = const [];
  bool _isLoadingCapabilities = true;

  @override
  void initState() {
    super.initState();
    _loadSystemCapabilities();
  }

  Future<void> _loadSystemCapabilities() async {
    final gpuManager = ref.read(gpuAccelerationManagerProvider);

    try {
      // Detect actual GPU acceleration
      final accelerator = await gpuManager.detectAccelerator();

      // Get detailed GPU info
      final gpuDetails = await gpuManager.getGpuInfo();
      final cudaDevices = await gpuManager.getCudaDevices();
      final directmlDevices = await gpuManager.getDirectMLDevices();
      final availableProviders = await gpuManager.queryAvailableProviders();

      // Get system info
      final cpuCores = Platform.numberOfProcessors;
      final systemRam = await _getSystemRamMB();
      final availableRam = (systemRam * 0.6).round(); // Estimate available RAM

      // Get disk space
      final diskInfo = await _getDiskSpaceInfo();

      // Get execution providers
      final executionProviders = gpuManager.getOnnxExecutionProviders();

      if (mounted) {
        final settings = ref.read(settingsNotifierProvider).analysisSettings;
        if (cudaDevices.isNotEmpty &&
            !cudaDevices.any(
              (gpu) => gpu.index == settings.modelConfig.gpuDeviceIndex,
            )) {
          final updated = settings.copyWith(
            modelConfig: settings.modelConfig.copyWith(
              gpuDeviceIndex: cudaDevices.first.index,
            ),
          );
          ref
              .read(settingsNotifierProvider.notifier)
              .updateAnalysisSettings(updated);
        }

        setState(() {
          _gpuDetails = gpuDetails;
          _cudaDevices = cudaDevices;
          _directmlDevices = directmlDevices;
          _availableProviders = availableProviders;
          _systemCapabilities = SystemCapabilities(
            cpuCores: cpuCores,
            ramMB: systemRam,
            availableRamMB: availableRam,
            diskSpaceMB: diskInfo.total,
            availableDiskSpaceMB: diskInfo.available,
            accelerator:
                accelerator.type != AcceleratorType.cpu ? accelerator : null,
            supportedExecutionProviders: executionProviders,
          );
          _isLoadingCapabilities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCapabilities = false;
        });
      }
    }
  }

  Future<int> _getSystemRamMB() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
            'wmic', ['OS', 'get', 'TotalVisibleMemorySize', '/value'],);
        final match = RegExp(r'TotalVisibleMemorySize=(\d+)')
            .firstMatch(result.stdout.toString());
        if (match != null) {
          return (int.parse(match.group(1)!) / 1024).round();
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('sysctl', ['-n', 'hw.memsize']);
        final bytes = int.tryParse(result.stdout.toString().trim()) ?? 0;
        return bytes ~/ (1024 * 1024);
      } else if (Platform.isLinux) {
        final result = await Process.run('grep', ['MemTotal', '/proc/meminfo']);
        final match =
            RegExp(r'MemTotal:\s*(\d+)').firstMatch(result.stdout.toString());
        if (match != null) {
          return (int.parse(match.group(1)!) / 1024).round();
        }
      }
    } catch (_) {}
    return 8192; // Default fallback
  }

  Future<({int total, int available})> _getDiskSpaceInfo() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
            'wmic', ['logicaldisk', 'get', 'size,freespace', '/value'],);
        final sizeMatch =
            RegExp(r'Size=(\d+)').firstMatch(result.stdout.toString());
        final freeMatch =
            RegExp(r'FreeSpace=(\d+)').firstMatch(result.stdout.toString());
        if (sizeMatch != null && freeMatch != null) {
          final total = int.parse(sizeMatch.group(1)!) ~/ (1024 * 1024);
          final available = int.parse(freeMatch.group(1)!) ~/ (1024 * 1024);
          return (total: total, available: available);
        }
      }
    } catch (_) {}
    return (total: 512000, available: 256000); // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settings = settingsState.analysisSettings;
    final modelConfig = settings.modelConfig;
    final hasCudaDevices = _cudaDevices.isNotEmpty;
    final gpuAccelerationAvailable =
        hasCudaDevices || _systemCapabilities?.accelerator != null;
    final gpuDisplayName = hasCudaDevices
        ? _cudaDevices.first.name
        : (_systemCapabilities?.accelerator?.name ?? 'GPU');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Settings',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure hardware acceleration and resource usage for AI analysis.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Hardware Info Section
          _buildSectionHeader(context, 'Detected Hardware', Icons.memory),
          const SizedBox(height: 16),
          _buildHardwareInfo(context),
          const SizedBox(height: 32),

          // GPU Acceleration Section
          _buildSectionHeader(context, 'GPU Acceleration', Icons.bolt),
          const SizedBox(height: 16),

          // Execution Provider Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acceleration Method', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how AI models process frames',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(
                        value: 'auto',
                        label: Text('Auto'),
                        icon: Icon(Icons.auto_awesome),
                      ),
                      ButtonSegment(
                        value: 'cuda',
                        label: const Text('CUDA'),
                        icon: const Icon(Icons.bolt),
                        enabled: _availableProviders.contains('CUDAExecutionProvider'),
                      ),
                      ButtonSegment(
                        value: 'directml',
                        label: const Text('DirectML'),
                        icon: const Icon(Icons.dashboard_customize),
                        enabled: _availableProviders.contains('DmlExecutionProvider'),
                      ),
                      ButtonSegment(
                        value: 'coreml',
                        label: const Text('CoreML'),
                        icon: const Icon(Icons.apple),
                        enabled: _availableProviders.contains('CoreMLExecutionProvider'),
                      ),
                      const ButtonSegment(
                        value: 'cpu',
                        label: Text('CPU Only'),
                        icon: Icon(Icons.developer_board),
                      ),
                    ],
                    selected: {modelConfig.onnxExecutionProvider},
                    onSelectionChanged: (Set<String> selection) {
                      _updateModelConfig(
                        ref,
                        settings,
                        onnxExecutionProvider: selection.first,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProviderInfoBanner(modelConfig.onnxExecutionProvider),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // GPU toggle
          Card(
            child: SwitchListTile(
              title: const Text('Use GPU Acceleration'),
              subtitle: Text(
                gpuAccelerationAvailable
                    ? 'Use $gpuDisplayName for faster processing'
                    : 'No compatible GPU detected',
              ),
              value: modelConfig.useGpu,
              onChanged: gpuAccelerationAvailable
                  ? (value) => _updateModelConfig(
                        ref,
                        settings,
                        useGpu: value,
                      )
                  : null,
              secondary: Icon(
                Icons.memory,
                color: gpuAccelerationAvailable
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          ),
          if (_cudaDevices.isNotEmpty && modelConfig.asrGpuEnabled) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Transcript Generation GPU',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPU used for Whisper speech-to-text',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _resolveSelectedCudaIndex(modelConfig.asrGpuDevice),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _cudaDevices
                          .map(
                            (gpu) => DropdownMenuItem<int>(
                              value: gpu.index,
                              child: Text(
                                'GPU ${gpu.index}: ${gpu.name}'
                                '${gpu.memoryTotalMB != null ? ' (${(gpu.memoryTotalMB! / 1024).toStringAsFixed(1)} GB)' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: modelConfig.asrGpuEnabled
                          ? (value) {
                              if (value == null) return;
                              _updateModelConfig(
                                ref,
                                settings,
                                asrGpuDevice: value,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_cudaDevices.isNotEmpty && 
              modelConfig.onnxGpuEnabled && 
              modelConfig.onnxExecutionProvider == 'cuda') ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Content Analysis GPU',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPU used for visual content detection',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _resolveSelectedCudaIndex(modelConfig.onnxGpuDevice ?? 0),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _cudaDevices
                          .map(
                            (gpu) => DropdownMenuItem<int>(
                              value: gpu.index,
                              child: Text(
                                'GPU ${gpu.index}: ${gpu.name}'
                                '${gpu.memoryTotalMB != null ? ' (${(gpu.memoryTotalMB! / 1024).toStringAsFixed(1)} GB)' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: modelConfig.onnxGpuEnabled
                          ? (value) {
                              if (value == null) return;
                              _updateModelConfig(
                                ref,
                                settings,
                                onnxGpuDevice: value,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // FP16 toggle
          Card(
            child: SwitchListTile(
              title: const Text('Half Precision (FP16)'),
              subtitle: const Text(
                'Use 16-bit floating point for faster inference with minimal accuracy loss',
              ),
              value: modelConfig.useFp16,
              onChanged: modelConfig.useGpu
                  ? (value) => _updateModelConfig(
                        ref,
                        settings,
                        useFp16: value,
                      )
                  : null,
              secondary: const Icon(Icons.speed),
            ),
          ),
          const SizedBox(height: 32),

          // CPU Configuration Section
          _buildSectionHeader(
              context, 'CPU Configuration', Icons.developer_board,),
          const SizedBox(height: 16),

          // CPU threads slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CPU Threads',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Number of threads to use for CPU inference',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: modelConfig.cpuThreads.toDouble(),
                    min: 1,
                    max: (_systemCapabilities?.cpuCores ?? 8).toDouble(),
                    divisions: (_systemCapabilities?.cpuCores ?? 8) - 1,
                    label: '${modelConfig.cpuThreads} threads',
                    minLabel: '1',
                    maxLabel: '${_systemCapabilities?.cpuCores ?? 8}',
                    onChanged: (value) => _updateModelConfig(
                      ref,
                      settings,
                      cpuThreads: value.round(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCpuInfo(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Analysis Configuration Section
          _buildSectionHeader(context, 'Analysis Settings', Icons.analytics),
          const SizedBox(height: 16),

          // Max concurrent analyses slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Concurrent Analyses',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maximum number of frames to analyze simultaneously',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: settings.maxConcurrentAnalyses.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    label: '${settings.maxConcurrentAnalyses}',
                    minLabel: '1',
                    maxLabel: '16',
                    onChanged: (value) => _updateSettings(
                      ref,
                      settings,
                      maxConcurrentAnalyses: value.round(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Batch size slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Size',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Number of frames to process in each batch (higher = faster but more VRAM)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: modelConfig.batchSize.toDouble(),
                    min: 1,
                    max: 32,
                    divisions: 31,
                    label: '${modelConfig.batchSize}',
                    minLabel: '1',
                    maxLabel: '32',
                    onChanged: (value) => _updateModelConfig(
                      ref,
                      settings,
                      batchSize: value.round(),
                    ),
                  ),
                  if (_systemCapabilities?.accelerator != null) ...[
                    const SizedBox(height: 8),
                    _buildBatchSizeRecommendation(context),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Hardware requirements section
          _buildSectionHeader(context, 'Hardware Requirements', Icons.info),
          const SizedBox(height: 16),
          HardwareRequirements(
            systemCapabilities: _systemCapabilities,
            isLoading: _isLoadingCapabilities,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) =>
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );

  Widget _buildHardwareInfo(BuildContext context) {
    if (_isLoadingCapabilities) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final caps = _systemCapabilities;
    if (caps == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              const Text('Failed to detect system hardware'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CPU info
            _buildHardwareRow(
              context,
              icon: Icons.developer_board,
              label: 'CPU',
              value: '${caps.cpuCores} cores',
            ),
            const Divider(height: 24),
            // RAM info
            _buildHardwareRow(
              context,
              icon: Icons.memory,
              label: 'RAM',
              value: '${(caps.ramMB / 1024).toStringAsFixed(1)} GB total, '
                  '${(caps.availableRamMB / 1024).toStringAsFixed(1)} GB available',
            ),
            const Divider(height: 24),
            // GPU info
            if (caps.accelerator != null) ...[
              _buildHardwareRow(
                context,
                icon: Icons.videogame_asset,
                label: 'GPU',
                value: _gpuDetails?.name ?? caps.accelerator!.name,
              ),
              const Divider(height: 24),
              _buildHardwareRow(
                context,
                icon: Icons.storage,
                label: 'VRAM',
                value: _gpuDetails != null
                    ? '${(_gpuDetails!.vramMB / 1024).toStringAsFixed(1)} GB'
                        '${_gpuDetails!.memoryUsedMB != null ? ' (${(_gpuDetails!.memoryFreeMB / 1024).toStringAsFixed(1)} GB free)' : ''}'
                    : '${(caps.accelerator!.vramMB / 1024).toStringAsFixed(1)} GB',
              ),
              if (_gpuDetails?.driverVersion != null) ...[
                const Divider(height: 24),
                _buildHardwareRow(
                  context,
                  icon: Icons.system_update,
                  label: 'Driver',
                  value: _gpuDetails!.driverVersion,
                ),
              ],
              if (_gpuDetails?.temperature != null) ...[
                const Divider(height: 24),
                _buildHardwareRow(
                  context,
                  icon: Icons.thermostat,
                  label: 'GPU Temp',
                  value: '${_gpuDetails!.temperature}°C',
                  isWarning: _gpuDetails!.temperature! > 80,
                ),
              ],
            ] else
              _buildHardwareRow(
                context,
                icon: Icons.videogame_asset,
                label: 'GPU',
                value: 'No compatible GPU detected',
                isWarning: true,
              ),
            // Execution providers
            if (caps.supportedExecutionProviders.isNotEmpty) ...[
              const Divider(height: 24),
              _buildHardwareRow(
                context,
                icon: Icons.bolt,
                label: 'Acceleration',
                value: caps.supportedExecutionProviders.join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isWarning
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCpuInfo(BuildContext context) {
    final caps = _systemCapabilities;
    if (caps == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Detected ${caps.cpuCores} CPU cores. Leave some cores free for other applications.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSizeRecommendation(BuildContext context) {
    final recommended =
        _systemCapabilities?.accelerator?.recommendedBatchSize ?? 8;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recommended batch size for your GPU: $recommended',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  int? _resolveSelectedCudaIndex(int deviceIndex) {
    if (_cudaDevices.isEmpty) return null;
    final exists = _cudaDevices.any((gpu) => gpu.index == deviceIndex);
    return exists ? deviceIndex : _cudaDevices.first.index;
  }

  Widget _buildProviderInfoBanner(String provider) {
    final theme = Theme.of(context);
    
    final (icon, color, title, message) = switch (provider) {
      'cuda' => (
        Icons.rocket_launch,
        Colors.green,
        'Maximum Performance',
        'CUDA provides fastest inference on NVIDIA GPUs',
      ),
      'directml' => (
        Icons.info,
        Colors.blue,
        'Universal Compatibility',
        'DirectML works with NVIDIA, AMD, and Intel GPUs',
      ),
      'coreml' => (
        Icons.apple,
        Colors.blue,
        'Apple Silicon Optimized',
        'Leverages Neural Engine for efficient inference',
      ),
      'cpu' => (
        Icons.warning_amber,
        Colors.orange,
        'Limited Performance',
        'CPU-only mode is significantly slower',
      ),
      _ => (
        Icons.auto_awesome,
        Colors.blue,
        'Automatic Selection',
        'Automatically chooses the best available accelerator',
      ),
    };
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateModelConfig(
    WidgetRef ref,
    AnalysisSettings settings, {
    bool? useGpu,
    bool? useFp16,
    int? gpuDeviceIndex,
    int? cpuThreads,
    int? batchSize,
    int? asrGpuDevice,
    int? onnxGpuDevice,
    String? onnxExecutionProvider,
  }) {
    final updatedConfig = settings.modelConfig.copyWith(
      useGpu: useGpu ?? settings.modelConfig.useGpu,
      useFp16: useFp16 ?? settings.modelConfig.useFp16,
      gpuDeviceIndex: gpuDeviceIndex ?? settings.modelConfig.gpuDeviceIndex,
      cpuThreads: cpuThreads ?? settings.modelConfig.cpuThreads,
      batchSize: batchSize ?? settings.modelConfig.batchSize,
      asrGpuDevice: asrGpuDevice ?? settings.modelConfig.asrGpuDevice,
      onnxGpuDevice: onnxGpuDevice ?? settings.modelConfig.onnxGpuDevice,
      onnxExecutionProvider: onnxExecutionProvider ?? settings.modelConfig.onnxExecutionProvider,
    );
    final updated = settings.copyWith(modelConfig: updatedConfig);
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _updateSettings(
    WidgetRef ref,
    AnalysisSettings settings, {
    int? maxConcurrentAnalyses,
  }) {
    final updated = settings.copyWith(
      maxConcurrentAnalyses:
          maxConcurrentAnalyses ?? settings.maxConcurrentAnalyses,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }
}
