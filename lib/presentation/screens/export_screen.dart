import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../services/export_service.dart';
import '../../state/providers/media_provider.dart';
import '../../state/providers/service_providers.dart';
import '../../state/providers/timeline_provider.dart';
import '../widgets/common/progress_card.dart';

/// Format options for export
enum ExportFormat {
  mp4H264,
  mp4H265,
  webm,
  mov,
  audioOnly,
}

/// Quality options for export
enum ExportQuality {
  low,
  medium,
  high,
  lossless,
}

/// Screen for configuring and executing export
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _format = ExportFormat.mp4H264;
  ExportQuality _quality = ExportQuality.high;
  String _outputPath = '';
  bool _isExporting = false;
  double _progress = 0;
  String? _currentPhase;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initOutputPath();
  }

  void _initOutputPath() {
    final media = ref.read(mediaNotifierProvider).currentMedia;
    if (media != null) {
      final baseName = media.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final directory = p.dirname(media.path);
      _outputPath = '$directory/${baseName}_cleaned.mp4';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
      ),
      body: _isExporting ? _buildExportProgress() : _buildExportSettings(),
    );
  }

  Widget _buildExportSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormatSection(),
          const SizedBox(height: 16),
          _buildQualitySection(),
          const SizedBox(height: 16),
          _buildOutputSection(),
          const SizedBox(height: 24),
          _buildExportButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Format',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExportFormat>(
              value: _format,
              decoration: const InputDecoration(
                labelText: 'Format',
                prefixIcon: Icon(Icons.video_file),
              ),
              items: ExportFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(_formatName(format)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _format = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _formatDescription(_format),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ExportQuality>(
              segments: ExportQuality.values.map((quality) {
                return ButtonSegment(
                  value: quality,
                  label: Text(_qualityName(quality)),
                  icon: Icon(_qualityIcon(quality)),
                );
              }).toList(),
              selected: {_quality},
              onSelectionChanged: (selection) {
                setState(() => _quality = selection.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _qualityDescription(_quality),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _outputPath,
              decoration: InputDecoration(
                labelText: 'Output Path',
                prefixIcon: const Icon(Icons.folder),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _selectOutputPath,
                  tooltip: 'Browse',
                ),
              ),
              onChanged: (value) => _outputPath = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return FilledButton.icon(
      onPressed: _startExport,
      icon: const Icon(Icons.download),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Start Export'),
      ),
    );
  }

  Widget _buildExportProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.video_settings,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Exporting Video',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _currentPhase ?? 'Preparing...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ProgressCard(
            title: 'Export Progress',
            progress: _progress,
            status: '${(_progress * 100).toStringAsFixed(1)}%',
            icon: Icons.downloading,
            onCancel: _cancelExport,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _formatName(ExportFormat format) {
    return switch (format) {
      ExportFormat.mp4H264 => 'MP4 (H.264)',
      ExportFormat.mp4H265 => 'MP4 (H.265/HEVC)',
      ExportFormat.webm => 'WebM (VP9)',
      ExportFormat.mov => 'MOV (ProRes)',
      ExportFormat.audioOnly => 'Audio Only (AAC)',
    };
  }

  String _formatDescription(ExportFormat format) {
    return switch (format) {
      ExportFormat.mp4H264 =>
        'Most compatible format. Works on all devices and platforms.',
      ExportFormat.mp4H265 =>
        'Better compression, smaller file size. May not play on older devices.',
      ExportFormat.webm => 'Open format, great for web. Not widely supported.',
      ExportFormat.mov =>
        'High quality for editing. Large file size, Mac/iOS focused.',
      ExportFormat.audioOnly => 'Extract audio only, no video.',
    };
  }

  String _qualityName(ExportQuality quality) {
    return switch (quality) {
      ExportQuality.low => 'Low',
      ExportQuality.medium => 'Medium',
      ExportQuality.high => 'High',
      ExportQuality.lossless => 'Lossless',
    };
  }

  IconData _qualityIcon(ExportQuality quality) {
    return switch (quality) {
      ExportQuality.low => Icons.sd,
      ExportQuality.medium => Icons.hd,
      ExportQuality.high => Icons.four_k,
      ExportQuality.lossless => Icons.high_quality,
    };
  }

  String _qualityDescription(ExportQuality quality) {
    return switch (quality) {
      ExportQuality.low => 'Smaller file size, lower quality. Good for sharing.',
      ExportQuality.medium => 'Balanced quality and file size.',
      ExportQuality.high => 'High quality, larger file size.',
      ExportQuality.lossless => 'No quality loss, very large file size.',
    };
  }

  Future<void> _selectOutputPath() async {
    // TODO: Implement file picker for output path
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker not yet implemented')),
    );
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0;
      _currentPhase = 'Initializing...';
      _errorMessage = null;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final media = ref.read(mediaNotifierProvider).currentMedia;
      final timelineState = ref.read(timelineNotifierProvider);

      if (media == null) {
        throw Exception('No media loaded');
      }

      if (timelineState.timeline == null) {
        throw Exception('No timeline available');
      }

      // Build export settings from format and quality selections
      final settings = _createExportSettings();

      await for (final progress in exportService.export(
        inputPath: media.path,
        outputPath: _outputPath,
        timeline: timelineState.timeline!,
        settings: settings,
      )) {
        if (mounted) {
          setState(() {
            _progress = progress.progress;
            _currentPhase = progress.phase;
          });
        }
      }

      if (mounted) {
        _showExportComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Build ExportSettings based on selected format and quality
  ExportSettings _createExportSettings() {
    String? videoCodec;
    String? audioCodec;
    String? videoBitrate;
    String? audioBitrate;
    String? preset;

    // Set codec based on format
    switch (_format) {
      case ExportFormat.mp4H264:
        videoCodec = 'libx264';
        audioCodec = 'aac';
      case ExportFormat.mp4H265:
        videoCodec = 'libx265';
        audioCodec = 'aac';
      case ExportFormat.webm:
        videoCodec = 'libvpx-vp9';
        audioCodec = 'libopus';
      case ExportFormat.mov:
        videoCodec = 'prores_ks';
        audioCodec = 'pcm_s16le';
      case ExportFormat.audioOnly:
        videoCodec = null;
        audioCodec = 'aac';
    }

    // Set bitrate and preset based on quality
    switch (_quality) {
      case ExportQuality.low:
        videoBitrate = '2M';
        audioBitrate = '128k';
        preset = 'fast';
      case ExportQuality.medium:
        videoBitrate = '5M';
        audioBitrate = '192k';
        preset = 'medium';
      case ExportQuality.high:
        videoBitrate = '10M';
        audioBitrate = '256k';
        preset = 'slow';
      case ExportQuality.lossless:
        videoBitrate = null; // Let codec decide
        audioBitrate = '320k';
        preset = 'veryslow';
    }

    return ExportSettings(
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      videoBitrate: videoBitrate,
      audioBitrate: audioBitrate,
      preset: preset,
    );
  }

  void _cancelExport() {
    setState(() {
      _isExporting = false;
    });
    // TODO: Actually cancel the export
  }

  void _showExportComplete() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Export Complete'),
        content: Text('Video exported to:\n$_outputPath'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Open file location
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Open Location'),
          ),
        ],
      ),
    );
  }
}
