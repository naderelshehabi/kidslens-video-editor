import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/app.dart';
import 'package:kidslens_video_editor/core/constants/supported_formats.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/gpu_info.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/analysis_settings_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:kidslens_video_editor/presentation/widgets/dialogs/export_dialog.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/detection_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/media_bin_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/preview_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/timeline_panel.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/playback_provider.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Main video editor screen with industry-standard layout
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  // Panel sizes for resizing
  double _leftPanelWidth = 280;
  double _rightPanelWidth = 280;
  double _timelineHeight = 200;

  // Minimum sizes
  static const double _minPanelWidth = 200;
  static const double _maxPanelWidth = 400;
  static const double _minTimelineHeight = 150;
  static const double _maxTimelineHeight = 400;

  // Blur editing state
  String? _editingBlurActionId;

  // Subtitle generation state
  bool _isGeneratingSubtitles = false;

  // Debug mode state
  bool _nsfwDebugModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectState = ref.watch(projectNotifierProvider);
    final project = projectState.currentProject;

    final selectedMedia = project?.selectedMedia;
    final analysisResult = _nsfwDebugModeEnabled
        ? ref.watch(analysisNotifierProvider.select((state) => state.result))
        : null;

    final nsfwFrameResults = analysisResult != null &&
            selectedMedia != null &&
            analysisResult.mediaFileId == selectedMedia.id
        ? analysisResult.frameResults
        : const <FrameAnalysisResult>[];

    final nsfwThreshold = _nsfwDebugModeEnabled
        ? ref.watch(
            settingsNotifierProvider.select(
                (state) => _resolveNsfwThreshold(state.analysisSettings)),
          )
        : 0.5;

    if (project == null) {
      // Navigate back to welcome screen when project is closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const KidsLensApp(),
            ),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CallbackShortcuts(
        bindings: _buildKeyboardShortcuts(),
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // Menu bar
              _buildMenuBar(context, project),

              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Left panel: Media Bin
                    SizedBox(
                      width: _leftPanelWidth,
                      child: MediaBinPanel(
                        mediaFiles: project.mediaFiles,
                        selectedMediaId: project.selectedMediaId,
                        onMediaSelected: (id) => ref
                            .read(projectNotifierProvider.notifier)
                            .selectMedia(id),
                        onImportMedia: _importMedia,
                        onRemoveMedia: (id) => ref
                            .read(projectNotifierProvider.notifier)
                            .removeMedia(id),
                      ),
                    ),

                    // Left panel resizer
                    _buildVerticalResizer(
                      onDrag: (dx) {
                        setState(() {
                          _leftPanelWidth = (_leftPanelWidth + dx)
                              .clamp(_minPanelWidth, _maxPanelWidth);
                        });
                      },
                    ),

                    // Center: Preview area
                    Expanded(
                      child: Column(
                        children: [
                          // Preview panel
                          Expanded(
                            child: PreviewPanel(
                              media: project.selectedMedia,
                              detections: project.selectedMediaId != null
                                  ? project.detectionsForMedia(
                                      project.selectedMediaId!,
                                    )
                                  : [],
                              editActions: project.selectedMediaId != null
                                  ? project.editActionsForMedia(
                                      project.selectedMediaId!,
                                    )
                                  : [],
                              subtitleTrack: project.selectedMediaId != null
                                  ? project.subtitleTrackForMedia(
                                      project.selectedMediaId!,
                                    )
                                  : null,
                              onEditActionUpdated: _onEditActionUpdated,
                              editingBlurActionId: _editingBlurActionId,
                              onEditingBlurActionChanged:
                                  _onEditingBlurActionChanged,
                              debugModeEnabled: _nsfwDebugModeEnabled,
                              nsfwFrameResults: nsfwFrameResults,
                              nsfwThreshold: nsfwThreshold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right panel resizer
                    _buildVerticalResizer(
                      onDrag: (dx) {
                        setState(() {
                          _rightPanelWidth = (_rightPanelWidth - dx)
                              .clamp(_minPanelWidth, _maxPanelWidth);
                        });
                      },
                    ),

                    // Right panel: Detection panel
                    SizedBox(
                      width: _rightPanelWidth,
                      child: DetectionPanel(
                        detections: project.selectedMediaId != null
                            ? project
                                .detectionsForMedia(project.selectedMediaId!)
                            : [],
                        editActions: project.selectedMediaId != null
                            ? project
                                .editActionsForMedia(project.selectedMediaId!)
                            : [],
                        onSeekToDetection: _onSeekToDetection,
                        onApplyAction: _onApplyAction,
                        onRejectDetection: _onRejectDetection,
                        onAcceptDetection: _onAcceptDetection,
                        onToggleEditAction: _onToggleEditAction,
                        onRemoveEditAction: _onRemoveEditAction,
                        onDeleteMultiple: _onDeleteMultiple,
                        onDeleteAll: _onDeleteAll,
                      ),
                    ),
                  ],
                ),
              ),

              // Timeline resizer
              _buildHorizontalResizer(
                onDrag: (dy) {
                  setState(() {
                    _timelineHeight = (_timelineHeight - dy)
                        .clamp(_minTimelineHeight, _maxTimelineHeight);
                  });
                },
              ),

              // Timeline panel
              SizedBox(
                height: _timelineHeight,
                child: TimelinePanel(
                  media: project.selectedMedia,
                  detections: project.selectedMediaId != null
                      ? project.detectionsForMedia(project.selectedMediaId!)
                      : [],
                  editActions: project.selectedMediaId != null
                      ? project.editActionsForMedia(project.selectedMediaId!)
                      : [],
                  onSeek: _onSeek,
                  onAddEditAction: _onAddEditAction,
                  onEditActionUpdated: _onEditActionUpdated,
                  onRemoveEditAction: _onRemoveEditActionById,
                  onEditBlurAction: _onEditingBlurActionChanged,
                  subtitleTrack: project.selectedMediaId != null
                      ? project.subtitleTrackForMedia(project.selectedMediaId!)
                      : null,
                  onGenerateSubtitles: _generateSubtitles,
                  onDeleteSubtitleTrack: _deleteSubtitleTrack,
                  isGeneratingSubtitles: _isGeneratingSubtitles,
                  showNsfwGraph: _nsfwDebugModeEnabled,
                  nsfwFrameResults: nsfwFrameResults,
                  nsfwThreshold: nsfwThreshold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBar(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      color: colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // App logo/title
          Icon(
            Icons.movie_filter_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            project.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),

          // File menu
          _MenuButton(
            label: 'File',
            items: [
              _MenuItem('Save Project', Icons.save, _saveProject),
              _MenuItem('Close Project', Icons.close, _closeProject),
              const _MenuDivider(),
              _MenuItem('Import Media', Icons.add, _importMedia),
              const _MenuDivider(),
              _MenuItem('Export', Icons.movie, _exportProject),
            ],
          ),

          // Edit menu
          _MenuButton(
            label: 'Edit',
            items: [
              _MenuItem('Undo', Icons.undo, _undo),
              _MenuItem('Redo', Icons.redo, _redo),
              const _MenuDivider(),
              _MenuItem('Cut Selection', Icons.content_cut, _cutSelection),
              _MenuItem('Mute Selection', Icons.volume_off, _muteSelection),
              _MenuItem('Blur Selection', Icons.blur_on, _blurSelection),
              const _MenuDivider(),
              _MenuItem('Preferences', Icons.settings, _openSettings),
            ],
          ),

          // Analysis menu
          _MenuButton(
            label: 'Analysis',
            items: [
              _MenuItem('Start Analysis', Icons.play_arrow, _startAnalysis),
              _MenuItem(
                _nsfwDebugModeEnabled
                    ? 'Disable NSFW Debug'
                    : 'Enable NSFW Debug',
                _nsfwDebugModeEnabled
                    ? Icons.bug_report
                    : Icons.bug_report_outlined,
                _toggleNsfwDebugMode,
              ),
              const _MenuDivider(),
              _MenuItem(
                'Analysis Settings',
                Icons.settings,
                _openAnalysisSettings,
              ),
            ],
          ),

          // Help menu
          _MenuButton(
            label: 'Help',
            items: [
              _MenuItem(
                'About KidsLens',
                Icons.info_outline,
                () => _showAboutDialog(context),
              ),
              _MenuItem(
                'Keyboard Shortcuts',
                Icons.keyboard,
                () => _showShortcutsDialog(context),
              ),
              const _MenuDivider(),
              _MenuItem(
                'Privacy Policy',
                Icons.privacy_tip,
                () => _showPrivacyDialog(context),
              ),
              _MenuItem(
                'Open Source Licenses',
                Icons.description,
                () => showLicensePage(
                  context: context,
                  applicationName: 'KidsLens Video Editor',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 KidsLens. All rights reserved.',
                ),
              ),
            ],
          ),

          const Spacer(),

          // Save indicator
          if (ref.watch(projectNotifierProvider).isSaving)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Saving...'),
              ],
            ),

          const SizedBox(width: 16),

          // Quick action buttons
          IconButton(
            icon: const Icon(Icons.save),
            iconSize: 18,
            tooltip: 'Save Project (Ctrl+S)',
            onPressed: _saveProject,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 18,
            tooltip: 'Import Media (Ctrl+I)',
            onPressed: _importMedia,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            iconSize: 18,
            tooltip: 'Start Analysis',
            onPressed: _startAnalysis,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 18,
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              ref.watch(settingsNotifierProvider).useDarkTheme
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            iconSize: 18,
            tooltip: ref.watch(settingsNotifierProvider).useDarkTheme
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              final isDark = ref.read(settingsNotifierProvider).useDarkTheme;
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setDarkTheme(useDark: !isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalResizer({required void Function(double) onDrag}) =>
      MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          child: Container(
            width: 6,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildHorizontalResizer({required void Function(double) onDrag}) =>
      MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: GestureDetector(
          onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
          child: Container(
            height: 6,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      );

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() => {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _saveProject,
        const SingleActivator(LogicalKeyboardKey.keyI, control: true):
            _importMedia,
        const SingleActivator(LogicalKeyboardKey.space): _togglePlayback,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
      };

  void _undo() {
    ref.read(projectNotifierProvider.notifier).undo();
  }

  void _redo() {
    ref.read(projectNotifierProvider.notifier).redo();
  }

  Future<void> _importMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...SupportedFormats.videoContainers,
          ...SupportedFormats.audioFormats,
        ],
        allowMultiple: true,
        dialogTitle: 'Import Media Files',
      );

      if (result != null) {
        final mediaService = ref.read(mediaServiceProvider);

        for (final file in result.files) {
          if (file.path != null) {
            final mediaFile = await mediaService.importMedia(file.path!);
            await ref
                .read(projectNotifierProvider.notifier)
                .importMedia(mediaFile);
          }
        }

        // Select the first imported file if nothing is selected
        final project = ref.read(projectNotifierProvider).currentProject;
        if (project?.selectedMediaId == null &&
            (project?.mediaFiles.isNotEmpty ?? false)) {
          ref
              .read(projectNotifierProvider.notifier)
              .selectMedia(project!.mediaFiles.first.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import media: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _saveProject() {
    ref.read(projectNotifierProvider.notifier).saveProject();
  }

  Future<void> _closeProject() async {
    final projectState = ref.read(projectNotifierProvider);

    // Check for unsaved changes
    if (projectState.currentProject?.hasUnsavedChanges ?? false) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to close the project? Your changes will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save first, then close
                await ref.read(projectNotifierProvider.notifier).saveProject();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save & Close'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard & Close'),
            ),
          ],
        ),
      );

      if (shouldClose != true) return;
    }

    // Stop any active playback before closing
    await ref.read(playbackNotifierProvider.notifier).stop();

    await ref.read(projectNotifierProvider.notifier).closeProject();
    // Navigation handled by the watch in build()
  }

  void _exportProject() {
    final project = ref.read(projectNotifierProvider).currentProject;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project loaded')),
      );
      return;
    }

    final selectedMedia = project.selectedMedia;
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    // Get edit actions for the selected media
    final editActions = project.editActionsForMedia(selectedMedia.id);

    // Get subtitle track for the selected media
    final subtitleTrack = project.subtitleTrackForMedia(selectedMedia.id);

    // Show export dialog
    ExportDialog.show(
      context: context,
      media: selectedMedia,
      editActions: editActions,
      subtitleTrack: subtitleTrack,
    );
  }

  Future<void> _generateSubtitles() async {
    final project = ref.read(projectNotifierProvider).currentProject;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project loaded')),
      );
      return;
    }

    final selectedMedia = project.selectedMedia;
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    // Check if subtitles already exist
    if (project.subtitleTrackForMedia(selectedMedia.id) != null) {
      final shouldRegenerate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Subtitles Exist'),
          content: const Text(
            'Subtitles already exist for this media. Do you want to regenerate them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Regenerate'),
            ),
          ],
        ),
      );
      if (shouldRegenerate != true) return;
    }

    // Ensure model state is up-to-date before checking download status
    await ref.read(modelNotifierProvider.notifier).loadAvailableModels();

    // Check if ASR model is available
    final settings = ref.read(settingsNotifierProvider);
    final asrModelId = settings.analysisSettings.modelConfig.asrModelId;
    final modelState = ref.read(modelNotifierProvider);

    if (!modelState.downloadedModels.contains(asrModelId)) {
      if (mounted) {
        final shouldDownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ASR Model Not Downloaded'),
            content: Text(
              'The selected ASR model "$asrModelId" is not downloaded. '
              'Would you like to download it now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Download'),
              ),
            ],
          ),
        );

        if (shouldDownload ?? false) {
          if (!mounted) return;
          // Navigate to model settings - ASR models tab is at index 0
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AnalysisSettingsScreen(initialTab: 0),
              ),
            ),
          );
        }
      }
      return;
    }

    // Initialize whisper bindings (fast, just loads the DLL reference)
    final whisper = ref.read(whisperBindingsProvider);
    await whisper.initialize();

    if (!mounted) return;

    // Show the progress dialog and run transcription in background
    setState(() => _isGeneratingSubtitles = true);

    // Read GPU / threading settings
    final modelConfig =
        ref.read(settingsNotifierProvider).analysisSettings.modelConfig;
    // Use runtime GPU detection (nvidia-smi, etc.) rather than the whisper
    // DLL's compile-time flag, which only reflects build-time CUDA linkage.
    final gpuManager = ref.read(gpuAccelerationManagerProvider);
    final accelerator = await gpuManager.detectAccelerator();
    final gpuAvailable = accelerator.type != AcceleratorType.cpu;
    final useGpu = gpuAvailable && modelConfig.useGpu;

    if (!mounted) return;
    final subtitleTrack = await showDialog<SubtitleTrack>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SubtitleGenerationDialog(
        mediaPath: selectedMedia.path,
        mediaId: selectedMedia.id,
        mediaDuration: selectedMedia.duration,
        asrModelId: asrModelId,
        hasNativeSupport: whisper.hasNativeSupport,
        useGpu: useGpu,
        gpuDeviceIndex: modelConfig.gpuDeviceIndex,
        nThreads: modelConfig.cpuThreads,
      ),
    );

    if (mounted) {
      setState(() => _isGeneratingSubtitles = false);
    }

    if (subtitleTrack != null) {
      // Update project with new subtitle track
      ref
          .read(projectNotifierProvider.notifier)
          .addSubtitleTrack(subtitleTrack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${subtitleTrack.segments.length} subtitle segments',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteSubtitleTrack() async {
    final project = ref.read(projectNotifierProvider).currentProject;
    if (project == null) return;
    final mediaId = project.selectedMediaId;
    if (mediaId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtitles'),
        content: const Text(
          'Are you sure you want to delete the subtitle track for this media? '
          'This action can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      ref.read(projectNotifierProvider.notifier).removeSubtitleTrack(mediaId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtitles deleted')),
      );
    }
  }

  void _startAnalysis() async {
    final project = ref.read(projectNotifierProvider).currentProject;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project loaded')),
      );
      return;
    }

    final selectedMedia = project.selectedMedia;
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    // Check for existing detections
    bool shouldClearDetections = true;
    final existingDetections = project.detectionsForMedia(selectedMedia.id);
    if (existingDetections.isNotEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Existing Detections Found'),
          content: Text(
            'This media file has ${existingDetections.length} existing detection(s). '
            'What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('clear'),
              child: const Text('Clear & Analyze'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: const Text('Keep & Analyze'),
            ),
          ],
        ),
      );

      if (result == null || result == 'cancel') {
        return;
      }

      shouldClearDetections = result == 'clear';
    }

    // Show analysis dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AnalysisDialog(
        mediaPath: selectedMedia.path,
        mediaId: selectedMedia.id,
        mediaDuration: selectedMedia.duration,
        clearExistingDetections: shouldClearDetections,
      ),
    );
  }

  void _togglePlayback() {
    ref.read(playbackNotifierProvider.notifier).playOrPause();
  }

  double _resolveNsfwThreshold(AnalysisSettings settings) {
    for (final category
        in settings.contentDetectionConfig.enabledVisualCategories) {
      if (category.id == 'nsfw') {
        return category.threshold;
      }
    }
    return 0.5;
  }

  void _toggleNsfwDebugMode() {
    setState(() => _nsfwDebugModeEnabled = !_nsfwDebugModeEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _nsfwDebugModeEnabled
              ? 'NSFW debug mode enabled'
              : 'NSFW debug mode disabled',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _cutSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    final project = ref.read(projectNotifierProvider).currentProject;

    if (project == null || project.selectedMediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    if (!playbackState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please make a selection on the timeline first (use I and O keys)',
          ),
        ),
      );
      return;
    }

    ref.read(projectNotifierProvider.notifier).addEditAction(
          project.selectedMediaId!,
          playbackState.selectionStart!,
          playbackState.selectionEnd!,
          EditActionType.cut,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cut action added to selection')),
    );
  }

  void _muteSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    final project = ref.read(projectNotifierProvider).currentProject;

    if (project == null || project.selectedMediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    if (!playbackState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please make a selection on the timeline first (use I and O keys)',
          ),
        ),
      );
      return;
    }

    ref.read(projectNotifierProvider.notifier).addEditAction(
          project.selectedMediaId!,
          playbackState.selectionStart!,
          playbackState.selectionEnd!,
          EditActionType.mute,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mute action added to selection')),
    );
  }

  void _blurSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    final project = ref.read(projectNotifierProvider).currentProject;

    if (project == null || project.selectedMediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a media file first')),
      );
      return;
    }

    if (!playbackState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please make a selection on the timeline first (use I and O keys)',
          ),
        ),
      );
      return;
    }

    ref.read(projectNotifierProvider.notifier).addEditAction(
          project.selectedMediaId!,
          playbackState.selectionStart!,
          playbackState.selectionEnd!,
          EditActionType.blur,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blur action added to selection')),
    );
  }

  void _openAnalysisSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AnalysisSettingsScreen(),
      ),
    );
  }

  void _onSeek(Duration position) {
    ref.read(playbackNotifierProvider.notifier).seek(position);
  }

  void _onSeekToDetection(Detection detection) {
    // Navigate to detection in timeline
    _onSeek(detection.startTime);
  }

  void _onApplyAction(Detection detection, RemediationAction action) {
    // Convert RemediationAction to EditActionType
    final EditActionType actionType;
    switch (action) {
      case RemediationAction.mute:
        actionType = EditActionType.mute;
      case RemediationAction.beep:
        actionType = EditActionType.beep;
      case RemediationAction.blurRegion:
      case RemediationAction.pixelateRegion:
      case RemediationAction.blackBoxRegion:
      case RemediationAction.blurFullFrame:
        actionType = EditActionType.blur;
      case RemediationAction.cutScene:
        actionType = EditActionType.cut;
    }

    ref.read(projectNotifierProvider.notifier).addEditAction(
          ref.read(projectNotifierProvider).currentProject!.selectedMediaId!,
          detection.startTime,
          detection.endTime,
          actionType,
          detectionId: detection.id,
        );
  }

  void _onRejectDetection(Detection detection) {
    ref.read(projectNotifierProvider.notifier).updateDetection(
          detection.reject(),
        );
  }

  void _onAcceptDetection(Detection detection) {
    ref.read(projectNotifierProvider.notifier).updateDetection(
          detection.copyWith(userStatus: DetectionUserStatus.pending),
        );
  }

  void _onToggleEditAction(EditAction action) {
    ref.read(projectNotifierProvider.notifier).updateEditAction(
          action.copyWith(enabled: !action.enabled),
        );
  }

  void _onRemoveEditAction(EditAction action) {
    ref.read(projectNotifierProvider.notifier).removeEditAction(action.id);
  }

  void _onRemoveEditActionById(String actionId) {
    ref.read(projectNotifierProvider.notifier).removeEditAction(actionId);
  }

  void _onDeleteMultiple(List<String> ids) {
    ref.read(projectNotifierProvider.notifier).removeDetections(ids);
  }

  void _onDeleteAll() {
    final project = ref.read(projectNotifierProvider).currentProject;
    if (project?.selectedMediaId != null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear All Detections?'),
          content: const Text(
            'This will permanently delete all detections for this media file. '
            'This action cannot be undone (except by Undo).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(projectNotifierProvider.notifier)
                    .removeAllDetections(project!.selectedMediaId!);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _onAddEditAction(EditAction action) {
    ref.read(projectNotifierProvider.notifier).addEditActionDirect(action);
  }

  void _onEditActionUpdated(EditAction action) {
    ref.read(projectNotifierProvider.notifier).updateEditAction(action);
  }

  void _onEditingBlurActionChanged(String? actionId) {
    setState(() {
      _editingBlurActionId = actionId;
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.movie_filter_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('About KidsLens'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.movie_filter_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'KidsLens Video Editor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Features',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildFeatureRow(context, Icons.mic_off, 'Profanity Detection'),
              _buildFeatureRow(
                context,
                Icons.visibility_off,
                'Visual Content Analysis',
              ),
              _buildFeatureRow(
                context,
                Icons.edit,
                'Smart Editing (Mute, Blur, Cut)',
              ),
              _buildFeatureRow(
                context,
                Icons.computer,
                '100% Offline Processing',
              ),
              const SizedBox(height: 24),
              Text(
                'Open Source Credits',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• whisper.cpp - Speech recognition (MIT)\n'
                '• FFmpeg - Media processing (LGPL/GPL)\n'
                '• ONNX Runtime - AI inference (MIT)\n'
                '• media_kit - Video playback (MIT)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(text, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  void _showShortcutsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard),
            SizedBox(width: 12),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShortcutRow(context, 'Ctrl+S', 'Save Project'),
              _buildShortcutRow(context, 'Ctrl+I', 'Import Media'),
              _buildShortcutRow(context, 'Space', 'Play/Pause'),
              _buildShortcutRow(context, 'Ctrl+Z', 'Undo'),
              _buildShortcutRow(context, 'Ctrl+Y', 'Redo'),
              _buildShortcutRow(context, 'I', 'Set Selection Start'),
              _buildShortcutRow(context, 'O', 'Set Selection End'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(
    BuildContext context,
    String shortcut,
    String action,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                shortcut,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                action,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip),
            SizedBox(width: 12),
            Text('Privacy Policy'),
          ],
        ),
        content: const SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Text(
              'KidsLens Video Editor processes all media files locally on your device. '
              'No data is sent to external servers.\n\n'
              'We do not collect, store, or transmit any personal information '
              'or media content.\n\n'
              'AI models are bundled with the application or downloaded from official sources '
              'and stored locally. All processing is performed entirely offline.\n\n'
              '© 2024 KidsLens. All rights reserved.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Menu components
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.items});

  final String label;
  final List<_MenuItemBase> items;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback?>(
        tooltip: '',
        offset: const Offset(0, 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label),
        ),
        itemBuilder: (context) =>
            items.map<PopupMenuEntry<VoidCallback?>>((item) {
          if (item is _MenuDivider) {
            return const PopupMenuDivider();
          }
          final menuItem = item as _MenuItem;
          return PopupMenuItem<VoidCallback?>(
            value: menuItem.onTap,
            enabled: menuItem.onTap != null,
            child: Row(
              children: [
                Icon(menuItem.icon, size: 18),
                const SizedBox(width: 12),
                Text(menuItem.label),
              ],
            ),
          );
        }).toList(),
        onSelected: (callback) => callback?.call(),
      );
}

abstract class _MenuItemBase {}

class _MenuItem implements _MenuItemBase {
  const _MenuItem(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _MenuDivider implements _MenuItemBase {
  const _MenuDivider();
}

// ============================================================================
// Subtitle Generation Dialog
// ============================================================================

/// Dialog that shows transcription progress and runs it in a background isolate.
class _SubtitleGenerationDialog extends ConsumerStatefulWidget {
  const _SubtitleGenerationDialog({
    required this.mediaPath,
    required this.mediaId,
    required this.mediaDuration,
    required this.asrModelId,
    required this.hasNativeSupport,
    required this.useGpu,
    required this.gpuDeviceIndex,
    required this.nThreads,
  });

  final String mediaPath;
  final String mediaId;
  final Duration mediaDuration;
  final String asrModelId;
  final bool hasNativeSupport;
  final bool useGpu;
  final int gpuDeviceIndex;
  final int nThreads;

  @override
  ConsumerState<_SubtitleGenerationDialog> createState() =>
      _SubtitleGenerationDialogState();
}

class _SubtitleGenerationDialogState
    extends ConsumerState<_SubtitleGenerationDialog> {
  TranscriptionPhase _phase = TranscriptionPhase.initializing;
  String _statusMessage = 'Initializing...';
  String? _error;
  double _progress = 0;
  Duration? _currentTimestamp;
  bool _cancelled = false;
  DateTime? _startTime;
  Timer? _elapsedTimer;
  final Completer<void> _cancelToken = Completer<void>();

  // Ordered phases for the stepper UI
  static const _orderedPhases = [
    (TranscriptionPhase.extractingAudio, 'Extract audio'),
    (TranscriptionPhase.loadingModel, 'Load model'),
    (TranscriptionPhase.transcribing, 'Transcribe speech'),
    (TranscriptionPhase.complete, 'Finalize'),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // Tick every second to keep the elapsed / ETA display live
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
    _runTranscription();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _runTranscription() async {
    try {
      // Show a note about placeholder mode if no native support
      if (!widget.hasNativeSupport) {
        _updatePhase(
          TranscriptionPhase.transcribing,
          0.10,
          'Generating placeholder subtitles (native library not loaded)...',
          null,
        );
      }

      final asrService = ref.read(asrServiceProvider);

      final transcript = await asrService.transcribeInBackground(
        widget.mediaPath,
        preferredModel: widget.asrModelId,
        mediaDuration: widget.mediaDuration,
        useGpu: widget.useGpu,
        gpuDeviceIndex: widget.gpuDeviceIndex,
        nThreads: widget.nThreads,
        onProgress: _updatePhase,
        cancelToken: _cancelToken,
      );

      final subtitleTrack = SubtitleTrack.fromTranscript(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        transcript: transcript,
        mediaId: widget.mediaId,
      );

      if (mounted && !_cancelled) {
        Navigator.of(context).pop(subtitleTrack);
      }
    } catch (e) {
      if (_cancelled) {
        // User already dismissed the dialog; nothing to do.
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = TranscriptionPhase.failed;
          _statusMessage = 'Subtitle generation failed';
        });
      }
    }
  }

  void _updatePhase(
    TranscriptionPhase phase,
    double progress,
    String message,
    Duration? currentTimestamp,
  ) {
    if (mounted && !_cancelled) {
      setState(() {
        _phase = phase;
        _progress = progress.clamp(0.0, 1.0);
        _statusMessage = message;
        if (currentTimestamp != null) {
          _currentTimestamp = currentTimestamp;
        }
      });
    }
  }

  void _onCancel() {
    if (!_cancelToken.isCompleted) {
      _cancelToken.complete();
    }
    setState(() => _cancelled = true);
    Navigator.of(context).pop(); // returns null → no subtitle track
  }

  int get _currentPhaseIndex =>
      _orderedPhases.indexWhere((p) => p.$1 == _phase);

  String get _elapsedFormatted {
    if (_startTime == null) return '';
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  String? get _etaFormatted {
    if (_startTime == null || _progress <= 0.0 || _progress >= 1.0) {
      return null;
    }
    final elapsed = DateTime.now().difference(_startTime!);
    final estimatedTotal = elapsed * (1.0 / _progress);
    final remaining = estimatedTotal - elapsed;
    if (remaining.isNegative) return null;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '~${minutes}m ${seconds.toString().padLeft(2, '0')}s remaining';
  }

  int get _progressPercent => (_progress * 100).round().clamp(0, 100);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String? get _timestampProgress {
    if (_currentTimestamp == null || widget.mediaDuration == Duration.zero) {
      return null;
    }
    return 'Processing ${_formatDuration(_currentTimestamp!)} '
        '/ ${_formatDuration(widget.mediaDuration)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFailed = _error != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            hasFailed ? Icons.error_outline : Icons.subtitles,
            color: hasFailed ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasFailed ? 'Subtitle Generation Failed' : 'Generating Subtitles',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPU acceleration status
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    widget.useGpu ? Icons.bolt : Icons.memory,
                    size: 16,
                    color: widget.useGpu ? Colors.amber : colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.useGpu ? 'GPU Accelerated' : 'CPU Only',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.useGpu ? Colors.amber : colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator with percentage
            if (!hasFailed) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_progressPercent%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Phase status message
            Text(
              _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasFailed
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Phase stepper
            ..._buildPhaseSteps(theme, colorScheme),

            // Current audio timestamp
            if (_timestampProgress != null && !hasFailed) ...[
              const SizedBox(height: 12),
              Text(
                _timestampProgress!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Elapsed time & ETA
            if (_startTime != null && !hasFailed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Elapsed: $_elapsedFormatted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  if (_etaFormatted != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      _etaFormatted!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Model info
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Model: ${widget.asrModelId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ),

            // Error details
            if (hasFailed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (hasFailed)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          )
        else
          TextButton(
            onPressed: _onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  List<Widget> _buildPhaseSteps(ThemeData theme, ColorScheme colorScheme) {
    final currentIdx = _currentPhaseIndex;
    final hasFailed = _error != null;

    return [
      for (int i = 0; i < _orderedPhases.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Step indicator icon
              SizedBox(
                width: 24,
                height: 24,
                child: _buildStepIcon(
                  i,
                  currentIdx,
                  hasFailed,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              // Step label
              Text(
                _orderedPhases[i].$2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: i <= currentIdx && !hasFailed
                      ? colorScheme.onSurface
                      : colorScheme.outline,
                  fontWeight:
                      i == currentIdx ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              // Active spinner
              if (i == currentIdx && !hasFailed) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  Widget _buildStepIcon(
    int stepIndex,
    int currentIndex,
    bool hasFailed,
    ColorScheme colorScheme,
  ) {
    if (hasFailed && stepIndex == currentIndex) {
      return Icon(Icons.close, size: 18, color: colorScheme.error);
    }
    if (stepIndex < currentIndex) {
      return Icon(Icons.check_circle, size: 18, color: colorScheme.primary);
    }
    if (stepIndex == currentIndex) {
      return Icon(
        Icons.radio_button_checked,
        size: 18,
        color: colorScheme.primary,
      );
    }
    return Icon(
      Icons.radio_button_unchecked,
      size: 18,
      color: colorScheme.outlineVariant,
    );
  }
}

/// Dialog for running content analysis
class _AnalysisDialog extends ConsumerStatefulWidget {
  const _AnalysisDialog({
    required this.mediaPath,
    required this.mediaId,
    required this.mediaDuration,
    this.clearExistingDetections = true,
  });

  final String mediaPath;
  final String mediaId;
  final Duration mediaDuration;
  final bool clearExistingDetections;

  @override
  ConsumerState<_AnalysisDialog> createState() => _AnalysisDialogState();
}

class _AnalysisDialogState extends ConsumerState<_AnalysisDialog> {
  bool _hasStarted = false;

  /// Local copy of category enable states, keyed by category ID.
  /// Initialised from the persisted [ContentDetectionConfig] in [initState].
  late Map<String, bool> _categoryEnabled;

  @override
  void initState() {
    super.initState();
    // Ensure defaults are populated, then seed local toggles.
    ref
        .read(settingsNotifierProvider.notifier)
        .ensureContentDetectionDefaults();
    final categories = ref
        .read(settingsNotifierProvider)
        .analysisSettings
        .contentDetectionConfig
        .categories;
    _categoryEnabled = {
      for (final c in categories) c.id: c.enabled,
    };
  }

  /// Resolve a [ContentCategory.iconName] string to a Material [IconData].
  IconData _iconForCategory(ContentCategory category) {
    switch (category.iconName) {
      case 'no_adult_content':
        return Icons.no_adult_content;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'water_drop':
        return Icons.water_drop;
      case 'gpp_bad':
        return Icons.gpp_bad;
      case 'visibility_off':
        return Icons.visibility_off;
      case 'block':
        return Icons.block;
      case 'favorite':
        return Icons.favorite;
      case 'checkroom':
        return Icons.checkroom;
      case 'volume_off':
        return Icons.volume_off;
      default:
        return category.isVisual ? Icons.image_search : Icons.mic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(analysisNotifierProvider);
    final isRunning = analysisState.status == AnalysisStatus.running;
    final isCancelling = analysisState.isCancelling;
    final isComplete = analysisState.status == AnalysisStatus.completed;
    final isFailed = analysisState.status == AnalysisStatus.failed;

    // Read categories from content detection config
    final categories = ref
        .watch(settingsNotifierProvider)
        .analysisSettings
        .contentDetectionConfig
        .categories;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.analytics,
            color: isComplete ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isComplete ? 'Analysis Complete' : 'Content Analysis'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasStarted) ...[
                Text(
                  'Select content categories to detect:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                // Visual categories section
                if (categories.any((c) => c.isVisual)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      'Visual',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...categories.where((c) => c.isVisual).map(
                        (category) => SwitchListTile(
                          secondary: Icon(
                            _iconForCategory(category),
                            size: 22,
                            color: (_categoryEnabled[category.id] ?? false)
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          title: Text(
                            category.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            category.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          value: _categoryEnabled[category.id] ?? false,
                          dense: true,
                          onChanged: (value) {
                            setState(() {
                              _categoryEnabled[category.id] = value;
                            });
                          },
                        ),
                      ),
                ],
                // Audio categories section
                if (categories.any((c) => c.isAudio)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      'Audio',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...categories.where((c) => c.isAudio).map(
                        (category) => SwitchListTile(
                          secondary: Icon(
                            _iconForCategory(category),
                            size: 22,
                            color: (_categoryEnabled[category.id] ?? false)
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          title: Text(
                            category.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            category.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          value: _categoryEnabled[category.id] ?? false,
                          dense: true,
                          onChanged: (value) {
                            setState(() {
                              _categoryEnabled[category.id] = value;
                            });
                          },
                        ),
                      ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Adjust per-category thresholds and models in '
                  'Analysis Settings > Content Detection.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                if (isRunning) ...[
                  Text(
                    analysisState.currentStep ?? 'Processing...',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (isCancelling) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cancellation requested. Stopping can take a few minutes while the current model operation finishes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: analysisState.progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(analysisState.progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (isComplete) ...[
                  Text(
                    'Found ${analysisState.detections.length} detection(s)',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (analysisState.detections.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: analysisState.detections.length,
                        itemBuilder: (context, index) {
                          final detection = analysisState.detections[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              _getIconForType(detection.type),
                              color: _getColorForType(detection.type),
                              size: 20,
                            ),
                            title: Text(
                              detection.description,
                              style: theme.textTheme.bodySmall,
                            ),
                            subtitle: Text(
                              '${_formatDuration(detection.startTime)} - ${_formatDuration(detection.endTime)}',
                              style: theme.textTheme.labelSmall,
                            ),
                            trailing: Text(
                              '${(detection.confidence * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No concerning content detected!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (isFailed) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            analysisState.errorMessage ?? 'Analysis failed',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!_hasStarted) ...[
          TextButton(
            onPressed: () {
              ref.read(analysisNotifierProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _startAnalysis,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Analysis'),
          ),
        ] else if (isRunning) ...[
          if (isCancelling)
            FilledButton.icon(
              onPressed: null,
              icon: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Cancelling...'),
            )
          else
            TextButton(
              onPressed: () {
                ref.read(analysisNotifierProvider.notifier).cancel();
              },
              child: const Text('Cancel'),
            ),
        ] else ...[
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }

  void _startAnalysis() {
    setState(() => _hasStarted = true);

    // Build settings from the persisted analysis settings, applying the
    // user's category enable/disable toggles from this dialog.
    final baseSettings = ref.read(settingsNotifierProvider).analysisSettings;
    final updatedCategories =
        baseSettings.contentDetectionConfig.categories.map((c) {
      final enabled = _categoryEnabled[c.id] ?? c.enabled;
      return c.copyWith(enabled: enabled);
    }).toList();

    final settings = baseSettings.copyWith(
      contentDetectionConfig: baseSettings.contentDetectionConfig.copyWith(
        categories: updatedCategories,
      ),
    );

    final project = ref.read(projectNotifierProvider).currentProject;
    final existingSubtitleTrack =
        project?.subtitleTrackForMedia(widget.mediaId);
    final existingTranscript = existingSubtitleTrack?.toTranscript();

    ref.read(analysisNotifierProvider.notifier).startAnalysis(
          mediaPath: widget.mediaPath,
          mediaId: widget.mediaId,
          settings: settings,
          mediaDuration: widget.mediaDuration,
          existingTranscript: existingTranscript,
          clearExistingDetections: widget.clearExistingDetections,
        );
  }

  IconData _getIconForType(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Icons.volume_off;
      case ContentType.violence:
        return Icons.warning;
      case ContentType.nsfw:
        return Icons.visibility_off;
      case ContentType.blood:
        return Icons.local_hospital;
      case ContentType.weapons:
        return Icons.gpp_maybe;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForType(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.violence:
        return Colors.red;
      case ContentType.nsfw:
        return Colors.pink;
      case ContentType.blood:
        return Colors.deepOrange;
      case ContentType.weapons:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
