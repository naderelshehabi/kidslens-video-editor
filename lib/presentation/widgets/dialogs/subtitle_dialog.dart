import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/data/models/transcription_progress.dart';
import 'package:kidslens_video_editor/services/subtitle_service.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:path/path.dart' as p;

/// Dialog for generating subtitles from media using ASR
class SubtitleDialog extends ConsumerStatefulWidget {
  const SubtitleDialog({
    required this.media,
    super.key,
  });

  /// The media file to generate subtitles for
  final MediaFile media;

  /// Show the subtitle dialog
  static Future<bool?> show({
    required BuildContext context,
    required WidgetRef ref,
    required MediaFile media,
  }) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SubtitleDialog(media: media),
      );

  @override
  ConsumerState<SubtitleDialog> createState() => _SubtitleDialogState();
}

class _SubtitleDialogState extends ConsumerState<SubtitleDialog> {
  // Subtitle settings
  SubtitleFormat _format = SubtitleFormat.srt;
  String? _selectedModelId;
  late String _outputPath;

  // Generation state
  bool _isGenerating = false;
  bool _isComplete = false;
  double _progress = 0;
  String _currentPhase = '';
  String? _errorMessage;
  Transcript? _transcript;
  StreamSubscription<TranscriptionProgress>? _transcriptionSubscription;

  @override
  void initState() {
    super.initState();
    _initOutputPath();
    _initSelectedModel();
  }

  void _initOutputPath() {
    final dir = p.dirname(widget.media.path);
    final baseName = p.basenameWithoutExtension(widget.media.path);
    _outputPath = p.join(dir, '$baseName.${_format.extension}');
  }

  void _initSelectedModel() {
    // Get downloaded ASR models
    final modelState = ref.read(modelNotifierProvider);
    final downloadedAsrModels = modelState.availableModels
        .where(
          (m) =>
              m.modelType == HuggingFaceModelType.asr &&
              modelState.downloadedModels.contains(m.id),
        )
        .toList();

    if (downloadedAsrModels.isNotEmpty) {
      // Prefer the selected model if downloaded
      final selectedId = modelState.selectedModels[HuggingFaceModelType.asr];
      if (selectedId != null &&
          downloadedAsrModels.any((m) => m.id == selectedId)) {
        _selectedModelId = selectedId;
      } else {
        _selectedModelId = downloadedAsrModels.first.id;
      }
    }
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.subtitles,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Generate Subtitles',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (!_isGenerating)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                      color: colorScheme.onPrimaryContainer,
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media info
                    _buildMediaInfo(theme),
                    const SizedBox(height: 24),

                    if (_isGenerating || _isComplete)
                      _buildProgressSection(theme, colorScheme)
                    else ...[
                      // Model selection
                      _buildModelSelection(theme),
                      const SizedBox(height: 24),

                      // Format selection
                      _buildFormatSelection(theme),
                      const SizedBox(height: 24),

                      // Output path
                      _buildOutputPath(theme),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isGenerating && !_isComplete)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  const SizedBox(width: 8),
                  if (_isComplete)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    )
                  else if (_isGenerating)
                    FilledButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      label: const Text('Generating...'),
                    )
                  else
                    FilledButton.icon(
                      onPressed:
                          _selectedModelId != null ? _startGeneration : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Generate'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaInfo(ThemeData theme) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                widget.media.isVideo ? Icons.videocam : Icons.audiotrack,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basename(widget.media.path),
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${_formatDuration(widget.media.duration)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildModelSelection(ThemeData theme) {
    final modelState = ref.watch(modelNotifierProvider);
    final downloadedAsrModels = modelState.availableModels
        .where(
          (m) =>
              m.modelType == HuggingFaceModelType.asr &&
              modelState.downloadedModels.contains(m.id),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ASR Model', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (downloadedAsrModels.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No ASR models downloaded',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please download a Whisper model from Analysis Settings → ASR Models',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedModelId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: downloadedAsrModels
                .map(
                  (model) => DropdownMenuItem(
                    value: model.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(model.displayName),
                        ),
                        if (model.isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Recommended',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedModelId = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildFormatSelection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subtitle Format', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SubtitleFormat.values.map((format) {
              final isSelected = _format == format;
              return ChoiceChip(
                label: Text(format.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _format = format;
                      _updateOutputPath();
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _getFormatDescription(_format),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );

  Widget _buildOutputPath(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Output Location', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _outputPath,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _browseOutputPath,
                tooltip: 'Browse',
              ),
            ],
          ),
        ],
      );

  Widget _buildProgressSection(ThemeData theme, ColorScheme colorScheme) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _isComplete ? 1.0 : _progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 12),

          // Phase info
          Row(
            children: [
              if (_isComplete)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                )
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isComplete
                      ? 'Subtitles generated successfully!'
                      : _currentPhase,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          if (_isComplete && _transcript != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtitle Statistics',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Segments',
                      '${_transcript!.segments.length}',
                      Icons.segment,
                    ),
                    _buildStatRow(
                      'Total Words',
                      '${_transcript!.totalWordCount}',
                      Icons.text_fields,
                    ),
                    _buildStatRow(
                      'Language',
                      _transcript!.language.toUpperCase(),
                      Icons.language,
                    ),
                    _buildStatRow(
                      'Output File',
                      p.basename(_outputPath),
                      Icons.insert_drive_file,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildStatRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text('$label: '),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  String _getFormatDescription(SubtitleFormat format) => switch (format) {
        SubtitleFormat.srt =>
          'SubRip Text - Most widely supported format. Works with most video players.',
        SubtitleFormat.vtt =>
          'WebVTT - Modern format for web video. Supports styling and positioning.',
        SubtitleFormat.ass =>
          'Advanced SubStation Alpha - Rich styling options for anime/video enthusiasts.',
      };

  void _updateOutputPath() {
    final dir = p.dirname(_outputPath);
    final baseName = p.basenameWithoutExtension(_outputPath);
    setState(() {
      _outputPath = p.join(dir, '$baseName.${_format.extension}');
    });
  }

  Future<void> _browseOutputPath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Subtitles',
      fileName: p.basename(_outputPath),
      type: FileType.custom,
      allowedExtensions: [_format.extension],
    );

    if (result != null) {
      setState(() {
        _outputPath = result;
      });
    }
  }

  Future<void> _startGeneration() async {
    if (_selectedModelId == null) return;

    setState(() {
      _isGenerating = true;
      _progress = 0;
      _currentPhase = 'Initializing...';
      _errorMessage = null;
    });

    try {
      final asrService = ref.read(asrServiceProvider);
      final subtitleService = ref.read(subtitleServiceProvider);

      // Start transcription with progress tracking
      setState(() {
        _currentPhase = 'Loading ASR model...';
      });

      await for (final progress in asrService.transcribe(
        widget.media.path,
        preferredModel: _selectedModelId,
      )) {
        setState(() {
          _progress =
              progress.progress * 0.9; // Reserve 10% for subtitle generation
          _currentPhase = _getPhaseMessage(progress.phase);
        });

        // Check for errors
        if (progress.hasFailed) {
          throw Exception(progress.errorMessage ?? 'Transcription failed');
        }
      }

      // Get the final transcript result
      setState(() {
        _currentPhase = 'Fetching transcript...';
      });

      final transcript = await asrService.transcribeToResult(
        widget.media.path,
        preferredModel: _selectedModelId,
      );

      _transcript = transcript;

      // Generate subtitle file
      setState(() {
        _progress = 0.95;
        _currentPhase = 'Generating ${_format.displayName} file...';
      });

      await subtitleService.generateSubtitles(
        transcript,
        _outputPath,
        _format,
      );

      setState(() {
        _isGenerating = false;
        _isComplete = true;
        _progress = 1.0;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate subtitles: $e';
      });
    }
  }

  String _getPhaseMessage(TranscriptionPhase phase) => switch (phase) {
        TranscriptionPhase.initializing => 'Initializing...',
        TranscriptionPhase.loadingModel => 'Loading ASR model...',
        TranscriptionPhase.extractingAudio => 'Extracting audio...',
        TranscriptionPhase.transcribing => 'Transcribing audio...',
        TranscriptionPhase.postProcessing => 'Post-processing...',
        TranscriptionPhase.complete => 'Transcription complete',
        TranscriptionPhase.failed => 'Transcription failed',
      };

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
