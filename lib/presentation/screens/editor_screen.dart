import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/app.dart';
import 'package:kidslens_video_editor/core/constants/supported_formats.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/analysis_settings_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:kidslens_video_editor/presentation/widgets/dialogs/export_dialog.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/detection_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/media_bin_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/preview_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/timeline_panel.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectState = ref.watch(projectNotifierProvider);
    final project = projectState.currentProject;

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
                              onEditActionUpdated: _onEditActionUpdated,
                              editingBlurActionId: _editingBlurActionId,
                              onEditingBlurActionChanged:
                                  _onEditingBlurActionChanged,
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
              _MenuItem('Stop Analysis', Icons.stop, _stopAnalysis),
              const _MenuDivider(),
              _MenuItem(
                  'Analysis Settings', Icons.settings, _openAnalysisSettings,),
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

    // Show export dialog
    ExportDialog.show(
      context: context,
      media: selectedMedia,
      editActions: editActions,
    );
  }

  void _startAnalysis() {
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

    // Show analysis dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AnalysisDialog(
        mediaPath: selectedMedia.path,
        mediaId: selectedMedia.id,
        mediaDuration: selectedMedia.duration,
      ),
    );
  }

  void _togglePlayback() {
    ref.read(playbackNotifierProvider.notifier).playOrPause();
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
                'Please make a selection on the timeline first (use I and O keys)',),),
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
                'Please make a selection on the timeline first (use I and O keys)',),),
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
                'Please make a selection on the timeline first (use I and O keys)',),),
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

  void _stopAnalysis() {
    final analysisState = ref.read(analysisNotifierProvider);

    if (analysisState.status == AnalysisStatus.running) {
      ref.read(analysisNotifierProvider.notifier).cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No analysis is currently running')),
      );
    }
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

  void _onApplyAction(Detection detection, EditActionType actionType) {
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

/// Dialog for running content analysis
class _AnalysisDialog extends ConsumerStatefulWidget {
  const _AnalysisDialog({
    required this.mediaPath,
    required this.mediaId,
    required this.mediaDuration,
  });

  final String mediaPath;
  final String mediaId;
  final Duration mediaDuration;

  @override
  ConsumerState<_AnalysisDialog> createState() => _AnalysisDialogState();
}

class _AnalysisDialogState extends ConsumerState<_AnalysisDialog> {
  bool _enableProfanity = true;
  bool _enableViolence = true;
  bool _enableNsfw = true;
  bool _enableBlood = true;
  bool _enableWeapons = true;
  bool _hasStarted = false;
  bool _showAdvanced = false;

  // Threshold settings
  double _nsfwThreshold = 0.6;
  double _violenceThreshold = 0.6;
  double _bloodThreshold = 0.6;
  double _weaponsThreshold = 0.6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(analysisNotifierProvider);
    final isRunning = analysisState.status == AnalysisStatus.running;
    final isComplete = analysisState.status == AnalysisStatus.completed;
    final isFailed = analysisState.status == AnalysisStatus.failed;

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
                  'Select content types to detect:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                _buildCheckbox('Profanity', _enableProfanity, (v) {
                  setState(() => _enableProfanity = v ?? false);
                }),
                _buildCheckbox('Violence', _enableViolence, (v) {
                  setState(() => _enableViolence = v ?? false);
                }),
                _buildCheckbox('NSFW', _enableNsfw, (v) {
                  setState(() => _enableNsfw = v ?? false);
                }),
                _buildCheckbox('Blood/Gore', _enableBlood, (v) {
                  setState(() => _enableBlood = v ?? false);
                }),
                _buildCheckbox('Weapons', _enableWeapons, (v) {
                  setState(() => _enableWeapons = v ?? false);
                }),
                const SizedBox(height: 16),
                // Advanced settings toggle
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detection Sensitivity',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 12),
                  _buildThresholdSlider(
                    'NSFW Threshold',
                    _nsfwThreshold,
                    (v) => setState(() => _nsfwThreshold = v),
                    enabled: _enableNsfw,
                  ),
                  _buildThresholdSlider(
                    'Violence Threshold',
                    _violenceThreshold,
                    (v) => setState(() => _violenceThreshold = v),
                    enabled: _enableViolence,
                  ),
                  _buildThresholdSlider(
                    'Blood Threshold',
                    _bloodThreshold,
                    (v) => setState(() => _bloodThreshold = v),
                    enabled: _enableBlood,
                  ),
                  _buildThresholdSlider(
                    'Weapons Threshold',
                    _weaponsThreshold,
                    (v) => setState(() => _weaponsThreshold = v),
                    enabled: _enableWeapons,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lower values = more sensitive (more detections)\nHigher values = less sensitive (fewer false positives)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ] else ...[
                if (isRunning) ...[
                  Text(
                    analysisState.currentStep ?? 'Processing...',
                    style: theme.textTheme.bodyMedium,
                  ),
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
          TextButton(
            onPressed: () {
              ref.read(analysisNotifierProvider.notifier).cancel();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ] else ...[
          FilledButton(
            onPressed: () {
              ref.read(analysisNotifierProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) =>
      CheckboxListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      );

  Widget _buildThresholdSlider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 0.1,
              divisions: 9,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  void _startAnalysis() {
    setState(() => _hasStarted = true);

    // Create settings with defaults, overriding enable flags and thresholds based on user selection
    final settings = AnalysisSettings.defaults().copyWith(
      enableProfanity: _enableProfanity,
      enableViolence: _enableViolence,
      enableNsfw: _enableNsfw,
      enableBlood: _enableBlood,
      enableWeapons: _enableWeapons,
      nsfwThreshold: _nsfwThreshold,
      violenceThreshold: _violenceThreshold,
      bloodThreshold: _bloodThreshold,
      weaponsThreshold: _weaponsThreshold,
    );

    ref.read(analysisNotifierProvider.notifier).startAnalysis(
          mediaPath: widget.mediaPath,
          mediaId: widget.mediaId,
          mediaDuration: widget.mediaDuration,
          settings: settings,
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
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
