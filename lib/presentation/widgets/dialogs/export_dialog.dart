import 'dart:async';
import 'dart:io' hide ContentType;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:path/path.dart' as p;

/// Format options for export
enum ExportFormat {
  mp4H264,
  mp4H265,
  webm,
  mov,
  audioOnly,
}

/// Quality presets for export
enum ExportQuality {
  low,
  medium,
  high,
  lossless,
}

/// Comprehensive export dialog with format, quality, and progress
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({
    required this.media,
    required this.editActions,
    super.key,
  });

  /// The media file to export
  final MediaFile media;

  /// Edit actions to apply during export
  final List<EditAction> editActions;

  /// Show the export dialog
  static Future<bool?> show({
    required BuildContext context,
    required MediaFile media,
    required List<EditAction> editActions,
  }) => showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportDialog(
        media: media,
        editActions: editActions,
      ),
    );

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  // Export settings
  ExportFormat _format = ExportFormat.mp4H264;
  ExportQuality _quality = ExportQuality.high;
  late String _outputPath;

  // Export state
  bool _isExporting = false;
  bool _isComplete = false;
  bool _isCancelled = false;
  double _progress = 0;
  String _currentPhase = '';
  String? _errorMessage;
  StreamSubscription<ExportProgress>? _exportSubscription;

  @override
  void initState() {
    super.initState();
    _initOutputPath();
  }

  @override
  void dispose() {
    _exportSubscription?.cancel();
    super.dispose();
  }

  void _initOutputPath() {
    final baseName = widget.media.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    final directory = p.dirname(widget.media.path);
    final extension = _getFileExtension(_format);
    _outputPath = p.join(directory, '${baseName}_exported$extension');
  }

  String _getFileExtension(ExportFormat format) => switch (format) {
      ExportFormat.mp4H264 => '.mp4',
      ExportFormat.mp4H265 => '.mp4',
      ExportFormat.webm => '.webm',
      ExportFormat.mov => '.mov',
      ExportFormat.audioOnly => '.aac',
    };

  void _updateOutputExtension() {
    final extension = _getFileExtension(_format);
    final currentExt = p.extension(_outputPath);
    if (currentExt.isNotEmpty) {
      _outputPath = _outputPath.replaceAll(RegExp(r'\.[^.]+$'), extension);
    } else {
      _outputPath = '$_outputPath$extension';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isComplete
                ? Icons.check_circle
                : _isExporting
                    ? Icons.downloading
                    : Icons.movie,
            color: _isComplete
                ? Colors.green
                : _isExporting
                    ? colorScheme.primary
                    : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(_isComplete
              ? 'Export Complete'
              : _isExporting
                  ? 'Exporting...'
                  : 'Export Video',),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _isExporting || _isComplete
            ? _buildProgressContent()
            : _buildSettingsContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildSettingsContent() {
    final theme = Theme.of(context);
    final enabledActions = widget.editActions.where((a) => a.enabled).toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media info
          _buildSection(
            title: 'Source',
            child: Row(
              children: [
                const Icon(Icons.video_file, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.media.name,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDuration(widget.media.duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Effects summary
          _buildSection(
            title: 'Effects to Apply (${enabledActions.length})',
            child: enabledActions.isEmpty
                ? Text(
                    'No effects will be applied',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: enabledActions.length,
                      itemBuilder: (context, index) {
                        final action = enabledActions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            _getIconForActionType(action.type),
                            size: 18,
                            color: _getColorForActionType(action.type),
                          ),
                          title: Text(
                            action.typeLabel,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Text(
                            '${_formatDuration(action.startTime)} - ${_formatDuration(action.endTime)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Format selection
          _buildSection(
            title: 'Output Format',
            child: DropdownButtonFormField<ExportFormat>(
              initialValue: _format,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: ExportFormat.values.map((format) => DropdownMenuItem(
                  value: format,
                  child: Row(
                    children: [
                      Icon(_getFormatIcon(format), size: 18),
                      const SizedBox(width: 8),
                      Text(_formatName(format)),
                    ],
                  ),
                ),).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _format = value;
                    _updateOutputExtension();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDescription(_format),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),

          // Quality selection
          _buildSection(
            title: 'Quality',
            child: SegmentedButton<ExportQuality>(
              segments: ExportQuality.values.map((quality) => ButtonSegment(
                  value: quality,
                  label: Text(_qualityName(quality)),
                  icon: Icon(_qualityIcon(quality), size: 16),
                ),).toList(),
              selected: {_quality},
              onSelectionChanged: (selection) {
                setState(() => _quality = selection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _qualityDescription(_quality),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),

          // Output path
          _buildSection(
            title: 'Output Location',
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _outputPath,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: Icon(Icons.folder, size: 20),
                    ),
                    onChanged: (value) {
                        _outputPath = value;
                        // Trigger rebuild to update path validity
                        if (mounted) setState(() {});
                    },
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _selectOutputPath,
                  tooltip: 'Browse',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isComplete && _errorMessage == null) ...[
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Export completed successfully!',
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _outputPath,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_errorMessage != null) ...[
          Icon(
            Icons.error,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Export failed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ] else ...[
          Icon(
            Icons.video_settings,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _currentPhase.isNotEmpty ? _currentPhase : 'Preparing...',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isComplete || _errorMessage != null) {
      return [
        if (_isComplete && _errorMessage == null)
          TextButton.icon(
            onPressed: _openFileLocation,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Location'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_isComplete),
          child: const Text('Close'),
        ),
      ];
    }

    if (_isExporting) {
      return [
        TextButton(
          onPressed: _cancelExport,
          child: const Text('Cancel'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _startExport,
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    ];
  }

  Future<void> _selectOutputPath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Select Export Location',
      fileName: p.basename(_outputPath),
      type: FileType.custom,
      allowedExtensions: [_getFileExtension(_format).substring(1)],
    );

    if (result != null) {
      setState(() => _outputPath = result);
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0;
      _currentPhase = 'Initializing...';
      _errorMessage = null;
      _isCancelled = false;
    });

    try {
      final exportService = ref.read(exportServiceProvider);

      // Build export settings from format and quality selections
      final settings = _createExportSettings();

      // Convert EditActions to UnifiedTimeline for ExportService
      final timeline = _buildTimelineFromEditActions();

      // Create output directory if needed
      final outputDir = Directory(p.dirname(_outputPath));
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      _exportSubscription = exportService
          .export(
        inputPath: widget.media.path,
        outputPath: _outputPath,
        timeline: timeline,
        settings: settings,
      )
          .listen(
        (progress) {
          if (mounted && !_isCancelled) {
            setState(() {
              _progress = progress.progress;
              _currentPhase = progress.phase;
            });
          }
        },
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _isExporting = false;
              _errorMessage = error.toString();
            });
          }
        },
        onDone: () {
          if (mounted && !_isCancelled) {
            setState(() {
              _isExporting = false;
              _isComplete = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _cancelExport() {
    _isCancelled = true;
    _exportSubscription?.cancel();
    Navigator.of(context).pop(false);
  }

  Future<void> _openFileLocation() async {
    // Open the folder containing the exported file
    final directory = p.dirname(_outputPath);
    if (Platform.isWindows) {
      await Process.run('explorer', [directory]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [directory]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [directory]);
    }
  }

  /// Convert EditActions to UnifiedTimeline for ExportService
  UnifiedTimeline _buildTimelineFromEditActions() {
    final enabledActions = widget.editActions.where((a) => a.enabled).toList();

    final audioSegments = <TimelineSegment>[];
    final videoSegments = <TimelineSegment>[];

    for (final action in enabledActions) {
      // Convert EditAction to Modification
      final modification = _actionToModification(action);
      if (modification == null) continue;

      final segment = TimelineSegment(
        id: 'seg_${action.id}',
        start: action.startTime,
        end: action.endTime,
        type: _actionToContentType(action),
        confidence: 1,
        modification: modification,
      );

      if (action.affectsAudio) {
        audioSegments.add(segment);
      } else if (action.affectsVideo) {
        videoSegments.add(segment);
      }
    }

    return UnifiedTimeline(
      id: 'export_timeline',
      mediaDuration: widget.media.duration,
      tracks: [
        TimelineTrack.video().copyWith(segments: videoSegments),
        TimelineTrack.audio().copyWith(segments: audioSegments),
      ],
    );
  }

  /// Convert EditAction to Modification
  Modification? _actionToModification(EditAction action) => switch (action.type) {
      EditActionType.mute => const Modification.audioMute(),
      EditActionType.beep => Modification.audioBeep(
          frequency: action.beepFrequency.round(),
        ),
      EditActionType.blur => Modification.videoBlur(
          intensity: (action.blurIntensity * 100).round().clamp(1, 100),
        ),
      EditActionType.cut => const Modification.videoSkip(),
      EditActionType.skip => const Modification.videoSkip(),
    };

  /// Convert EditAction type to ContentType for segment
  ContentType _actionToContentType(EditAction action) => switch (action.type) {
      EditActionType.mute => ContentType.profanity,
      EditActionType.beep => ContentType.profanity,
      EditActionType.blur => ContentType.nsfw,
      EditActionType.cut => ContentType.violence,
      EditActionType.skip => ContentType.violence,
    };

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
        // Use libopenh264 or h264 relative to what's available
        // libx264 is not available in the bundled build
        videoCodec = 'libopenh264'; 
        audioCodec = 'aac';
      case ExportFormat.mp4H265:
        // Use libkvazaar as libx265 is not available
        videoCodec = 'libkvazaar';
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
    // Note: libopenh264 does not support standard presets (slow, fast, etc.)
    // We only set preset for other codecs or if we change implementation.
    // For now, we clear preset for libopenh264/libkvazaar to avoid errors/warnings,
    // or keep it if they handle it gracefully (libkvazaar supports presets).
    
    switch (_quality) {
      case ExportQuality.low:
        videoBitrate = '2M';
        audioBitrate = '128k';
        preset = (videoCodec == 'libopenh264') ? null : 'fast';
      case ExportQuality.medium:
        videoBitrate = '5M';
        audioBitrate = '192k';
        preset = (videoCodec == 'libopenh264') ? null : 'medium';
      case ExportQuality.high:
        videoBitrate = '10M';
        audioBitrate = '256k';
        preset = (videoCodec == 'libopenh264') ? null : 'slow';
      case ExportQuality.lossless:
        videoBitrate = null;
        audioBitrate = '320k';
        preset = (videoCodec == 'libopenh264') ? null : 'veryslow';
    }

    return ExportSettings(
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      videoBitrate: videoBitrate,
      audioBitrate: audioBitrate,
      preset: preset,
    );
  }

  // Helper methods for formatting and icons
  String _formatName(ExportFormat format) => switch (format) {
      ExportFormat.mp4H264 => 'MP4 (H.264)',
      ExportFormat.mp4H265 => 'MP4 (H.265/HEVC)',
      ExportFormat.webm => 'WebM (VP9)',
      ExportFormat.mov => 'MOV (ProRes)',
      ExportFormat.audioOnly => 'Audio Only (AAC)',
    };

  String _formatDescription(ExportFormat format) => switch (format) {
      ExportFormat.mp4H264 =>
        'Most compatible format. Works on all devices and platforms.',
      ExportFormat.mp4H265 =>
        'Better compression, smaller file size. May not play on older devices.',
      ExportFormat.webm =>
        'Open format, great for web. Not widely supported offline.',
      ExportFormat.mov =>
        'High quality for editing. Large file size, Mac/iOS focused.',
      ExportFormat.audioOnly => 'Extract audio only, no video.',
    };

  IconData _getFormatIcon(ExportFormat format) => switch (format) {
      ExportFormat.mp4H264 => Icons.video_file,
      ExportFormat.mp4H265 => Icons.video_file,
      ExportFormat.webm => Icons.web,
      ExportFormat.mov => Icons.movie,
      ExportFormat.audioOnly => Icons.audio_file,
    };

  String _qualityName(ExportQuality quality) => switch (quality) {
      ExportQuality.low => 'Low',
      ExportQuality.medium => 'Medium',
      ExportQuality.high => 'High',
      ExportQuality.lossless => 'Lossless',
    };

  IconData _qualityIcon(ExportQuality quality) => switch (quality) {
      ExportQuality.low => Icons.sd,
      ExportQuality.medium => Icons.hd,
      ExportQuality.high => Icons.four_k,
      ExportQuality.lossless => Icons.high_quality,
    };

  String _qualityDescription(ExportQuality quality) => switch (quality) {
      ExportQuality.low =>
        'Smaller file size, lower quality. Good for sharing.',
      ExportQuality.medium => 'Balanced quality and file size.',
      ExportQuality.high => 'High quality, larger file size.',
      ExportQuality.lossless => 'No quality loss, very large file size.',
    };

  IconData _getIconForActionType(EditActionType type) => switch (type) {
      EditActionType.mute => Icons.volume_off,
      EditActionType.beep => Icons.notifications_active,
      EditActionType.blur => Icons.blur_on,
      EditActionType.cut => Icons.content_cut,
      EditActionType.skip => Icons.skip_next,
    };

  Color _getColorForActionType(EditActionType type) => switch (type) {
      EditActionType.mute => Colors.orange,
      EditActionType.beep => Colors.purple,
      EditActionType.blur => Colors.blue,
      EditActionType.cut => Colors.red,
      EditActionType.skip => Colors.grey,
    };

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
