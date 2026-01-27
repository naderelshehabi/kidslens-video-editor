import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/constants/supported_formats.dart';
import '../../data/models/detection.dart';
import '../../data/models/edit_action.dart';
import '../../data/models/project.dart';
import '../../state/providers/project_provider.dart';
import '../../state/providers/service_providers.dart';
import '../widgets/editor/media_bin_panel.dart';
import '../widgets/editor/preview_panel.dart';
import '../widgets/editor/timeline_panel.dart';
import '../widgets/editor/detection_panel.dart';

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
                                      project.selectedMediaId!)
                                  : [],
                              editActions: project.selectedMediaId != null
                                  ? project.editActionsForMedia(
                                      project.selectedMediaId!)
                                  : [],
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
                            ? project.detectionsForMedia(project.selectedMediaId!)
                            : [],
                        editActions: project.selectedMediaId != null
                            ? project.editActionsForMedia(project.selectedMediaId!)
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
          Icon(Icons.movie_filter_rounded, 
               color: colorScheme.primary, size: 20),
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
              _MenuItem('Undo', Icons.undo, null),
              _MenuItem('Redo', Icons.redo, null),
              const _MenuDivider(),
              _MenuItem('Cut Selection', Icons.content_cut, null),
              _MenuItem('Mute Selection', Icons.volume_off, null),
              _MenuItem('Blur Selection', Icons.blur_on, null),
            ],
          ),
          
          // Analysis menu
          _MenuButton(
            label: 'Analysis',
            items: [
              _MenuItem('Start Analysis', Icons.play_arrow, _startAnalysis),
              _MenuItem('Stop Analysis', Icons.stop, null),
              const _MenuDivider(),
              _MenuItem('Analysis Settings', Icons.settings, null),
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
        ],
      ),
    );
  }

  Widget _buildVerticalResizer({required void Function(double) onDrag}) {
    return MouseRegion(
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalResizer({required void Function(double) onDrag}) {
    return MouseRegion(
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): 
          _saveProject,
      const SingleActivator(LogicalKeyboardKey.keyI, control: true): 
          _importMedia,
      const SingleActivator(LogicalKeyboardKey.space): 
          _togglePlayback,
    };
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
            await ref.read(projectNotifierProvider.notifier)
                .importMedia(mediaFile);
          }
        }
        
        // Select the first imported file if nothing is selected
        final project = ref.read(projectNotifierProvider).currentProject;
        if (project?.selectedMediaId == null && 
            project?.mediaFiles.isNotEmpty == true) {
          ref.read(projectNotifierProvider.notifier)
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

  void _saveProject() {
    ref.read(projectNotifierProvider.notifier).saveProject();
  }

  Future<void> _closeProject() async {
    await ref.read(projectNotifierProvider.notifier).closeProject();
    // Project state will trigger navigation back to welcome screen
    // via the watch in _WelcomeScreenState
  }

  void _exportProject() {
    // TODO: Implement export dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _startAnalysis() {
    // TODO: Implement analysis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis functionality coming soon')),
    );
  }

  void _togglePlayback() {
    // TODO: Implement playback toggle
  }

  void _onSeek(Duration position) {
    // TODO: Implement seeking
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

  void _onAddEditAction(EditAction action) {
    ref.read(projectNotifierProvider.notifier).addEditActionDirect(action);
  }
}

// Menu components
class _MenuButton extends StatelessWidget {
  final String label;
  final List<_MenuItemBase> items;

  const _MenuButton({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback?>(
      tooltip: '',
      offset: const Offset(0, 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label),
      ),
      itemBuilder: (context) => items.map<PopupMenuEntry<VoidCallback?>>((item) {
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
}

abstract class _MenuItemBase {}

class _MenuItem implements _MenuItemBase {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _MenuItem(this.label, this.icon, this.onTap);
}

class _MenuDivider implements _MenuItemBase {
  const _MenuDivider();
}
