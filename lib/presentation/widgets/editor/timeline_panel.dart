import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/subtitle_track.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/state/providers/playback_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

String? _modestyTrackCategoryIdForLabel(String label) {
  switch (label) {
    case 'FEMALE_BREAST_EXPOSED':
      return 'female_chest_exposure';
    case 'BELLY_EXPOSED':
      return 'female_abdomen_exposure';
    case 'MODESTY_FEMALE_ARMS_EXPOSED':
      return 'female_arms_exposure';
    case 'MODESTY_FEMALE_LEGS_EXPOSED':
      return 'female_legs_exposure';
    case 'BUTTOCKS_EXPOSED':
    case 'ANUS_EXPOSED':
      return 'male_buttocks_exposure';
    case 'MALE_GENITALIA_EXPOSED':
      return 'male_genitals_exposure';
    default:
      return null;
  }
}

/// Timeline panel with tracks and detection indicators
class TimelinePanel extends ConsumerStatefulWidget {
  const TimelinePanel({
    required this.media,
    required this.detections,
    required this.editActions,
    required this.onSeek,
    required this.onAddEditAction,
    super.key,
    this.onEditActionUpdated,
    this.onRemoveEditAction,
    this.onEditBlurAction,
    this.thumbnails,
    this.subtitleTrack,
    this.onGenerateSubtitles,
    this.onDeleteSubtitleTrack,
    this.isGeneratingSubtitles = false,
    this.showNsfwGraph = false,
    this.nsfwFrameResults = const <FrameAnalysisResult>[],
    this.nsfwThreshold = 0.5,
    this.showNudenetTrack = false,
    this.showModestyTrack = false,
  });

  final MediaFile? media;
  final List<Detection> detections;
  final List<EditAction> editActions;
  final void Function(Duration) onSeek;
  final void Function(EditAction) onAddEditAction;
  final void Function(EditAction)? onEditActionUpdated;
  final void Function(String)? onRemoveEditAction;
  final void Function(String)? onEditBlurAction;
  final List<Uint8List>? thumbnails;
  final SubtitleTrack? subtitleTrack;
  final VoidCallback? onGenerateSubtitles;
  final VoidCallback? onDeleteSubtitleTrack;
  final bool isGeneratingSubtitles;
  final bool showNsfwGraph;
  final List<FrameAnalysisResult> nsfwFrameResults;
  final double nsfwThreshold;
  final bool showNudenetTrack;
  final bool showModestyTrack;

  @override
  ConsumerState<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends ConsumerState<TimelinePanel>
    with SingleTickerProviderStateMixin {
  double _zoom = 1;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _labelsVerticalController = ScrollController();
  final ScrollController _tracksVerticalController = ScrollController();
  static const _uuid = Uuid();

  // Selection by drag state
  bool _isDraggingSelection = false;
  Duration? _dragSelectionStart;
  Duration? _dragSelectionEnd;

  // Thumbnail loading state
  List<ui.Image>? _thumbnailImages;
  String? _loadedMediaPath;
  bool _isLoadingThumbnails = false;

  // Shimmer animation controller
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadThumbnailsIfNeeded();
  }

  @override
  void didUpdateWidget(TimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media?.path != widget.media?.path) {
      _loadThumbnailsIfNeeded();
    }
  }

  void _loadThumbnailsIfNeeded() {
    final media = widget.media;
    if (media == null || !media.isVideo) return;
    if (media.path == _loadedMediaPath && _thumbnailImages != null) return;
    if (_isLoadingThumbnails) return;

    _loadThumbnails(media);
  }

  Future<void> _loadThumbnails(MediaFile media) async {
    setState(() => _isLoadingThumbnails = true);

    try {
      final thumbnailService = ref.read(thumbnailServiceProvider);
      final settings = ref.read(settingsNotifierProvider);
      final duration = media.duration;
      final interval = settings.thumbnailInterval;

      // Calculate count based on interval
      // Ensure at least one thumbnail, and cap at 300
      final rawCount = (duration.inSeconds / interval.inSeconds).ceil();
      final count = rawCount.clamp(1, 300);

      final thumbnailBytes = await thumbnailService.extractThumbnails(
        videoPath: media.path,
        duration: duration,
        count: count,
      );

      // Decode bytes to ui.Image
      final images = <ui.Image>[];
      for (final bytes in thumbnailBytes) {
        try {
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          images.add(frame.image);
        } catch (e) {
          // Skip failed decodes
          debugPrint('Failed to decode thumbnail: $e');
        }
      }

      if (mounted) {
        setState(() {
          _thumbnailImages = images;
          _loadedMediaPath = media.path;
          _isLoadingThumbnails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading thumbnails: $e');
      if (mounted) {
        setState(() => _isLoadingThumbnails = false);
      }
    }
  }

  void _onScroll() {
    setState(() {}); // Trigger repaint for scroll-dependent elements
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _labelsVerticalController.dispose();
    _tracksVerticalController.dispose();
    _shimmerController.dispose();
    // Dispose thumbnail images
    if (_thumbnailImages != null) {
      for (final image in _thumbnailImages!) {
        image.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for setting changes
    ref.listen(settingsNotifierProvider, (previous, next) {
      if (previous?.thumbnailInterval != next.thumbnailInterval) {
        // Dispose existing thumbnails to free memory
        if (_thumbnailImages != null) {
          for (final image in _thumbnailImages!) {
            image.dispose();
          }
        }

        if (mounted) {
          setState(() {
            _thumbnailImages = null;
          });
          _loadThumbnailsIfNeeded();
        }
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playbackState = ref.watch(playbackNotifierProvider);

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Timeline toolbar
          _buildToolbar(context, playbackState),

          // Timeline content
          Expanded(
            child: widget.media == null
                ? _buildEmptyState(context)
                : Row(
                    children: [
                      // Track labels
                      _buildTrackLabels(context),

                      // Timeline area
                      Expanded(
                        child: _buildTimelineArea(context, playbackState),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, PlaybackState playbackState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Timeline',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 24),

          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 16),
            onPressed: () =>
                setState(() => _zoom = math.max(0.25, _zoom - 0.25)),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom Out',
          ),
          SizedBox(
            width: 100,
            child: Slider(
              value: _zoom,
              min: 0.25,
              max: 8,
              onChanged: (value) => setState(() => _zoom = value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 16),
            onPressed: () => setState(() => _zoom = math.min(8, _zoom + 0.25)),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom In',
          ),

          Text(
            '${(_zoom * 100).round()}%',
            style: theme.textTheme.bodySmall,
          ),

          const Spacer(),

          // Selection indicator
          if (playbackState.hasSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_formatDuration(playbackState.selectionStart!)} - ${_formatDuration(playbackState.selectionEnd!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .clearSelection(),
                    child:
                        const Icon(Icons.close, size: 14, color: Colors.blue),
                  ),
                ],
              ),
            ),

          // Edit action buttons - enabled only when selection exists
          _ToolButton(
            icon: Icons.content_cut,
            label: 'Cut',
            onPressed: playbackState.hasSelection ? _cutSelection : null,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.volume_off,
            label: 'Mute',
            onPressed: playbackState.hasSelection ? _muteSelection : null,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.blur_on,
            label: 'Blur',
            onPressed: playbackState.hasSelection ? _blurSelection : null,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.notifications,
            label: 'Beep',
            onPressed: playbackState.hasSelection ? _beepSelection : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Text(
        'Select a media file to view timeline',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTrackLabels(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Time ruler placeholder
          Container(
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
          // Track labels - synced with timeline vertical scroll
          Expanded(
            child: SingleChildScrollView(
              controller: _labelsVerticalController,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video track label
                  _TrackLabel(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: colorScheme.primary,
                    height: 64, // Taller for thumbnails
                  ),
                  // Audio track label
                  _TrackLabel(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    color: colorScheme.secondary,
                    height: 40,
                  ),
                  if (widget.showNsfwGraph)
                    const _TrackLabel(
                      icon: Icons.show_chart,
                      label: 'NSFW Score',
                      color: Colors.pink,
                    ),
                  if (widget.showNudenetTrack)
                    const _TrackLabel(
                      icon: Icons.grid_view_outlined,
                      label: 'NudeNet',
                      color: Colors.deepPurple,
                    ),
                  if (widget.showModestyTrack)
                    const _TrackLabel(
                      icon: Icons.shield_outlined,
                      label: 'Modesty',
                      color: AppTheme.femaleExposureColor,
                    ),
                  // Detections track label
                  const _TrackLabel(
                    icon: Icons.warning_amber,
                    label: 'Detections',
                    color: Colors.orange,
                  ),
                  // Edits track label
                  const _TrackLabel(
                    icon: Icons.edit,
                    label: 'Edits',
                    color: Colors.purple,
                  ),
                  // Subtitles track label
                  _SubtitleTrackLabel(
                    hasSubtitles: widget.subtitleTrack != null,
                    isGenerating: widget.isGeneratingSubtitles,
                    onGenerate: widget.onGenerateSubtitles,
                    onDelete: widget.onDeleteSubtitleTrack,
                    language: widget.subtitleTrack?.language,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineArea(BuildContext context, PlaybackState playbackState) {
    final duration = widget.media?.duration ?? Duration.zero;
    final double timelineWidth =
        math.max(duration.inSeconds * 20.0 * _zoom, 500);

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // Check for horizontal scroll (shift+scroll or trackpad horizontal)
          if (event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
            // Horizontal scroll - let it pass through for scrolling
            return;
          }

          // Ctrl + scroll OR pinch gesture = zoom
          // On trackpad, pinch sends scroll events with Ctrl modifier
          if (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) {
            final delta = event.scrollDelta.dy > 0 ? -0.15 : 0.15;
            setState(() => _zoom = (_zoom + delta).clamp(0.1, 10.0));
          } else {
            // Regular scroll without modifiers = zoom (for easier UX)
            // Use smaller delta for smoother zoom
            final delta = event.scrollDelta.dy > 0 ? -0.08 : 0.08;
            setState(() => _zoom = (_zoom + delta).clamp(0.1, 10.0));
          }
        }
      },
      child: GestureDetector(
        onScaleStart: (details) {
          // For single finger: start selection drag
          // For two fingers: prepare for pinch zoom
          if (details.pointerCount == 1 && duration.inMilliseconds > 0) {
            final scrollOffset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
            final position = Duration(
              milliseconds: ((details.localFocalPoint.dx + scrollOffset) /
                      timelineWidth *
                      duration.inMilliseconds)
                  .round()
                  .clamp(0, duration.inMilliseconds),
            );
            setState(() {
              _isDraggingSelection = true;
              _dragSelectionStart = position;
              _dragSelectionEnd = position;
            });
          }
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2 && details.scale != 1.0) {
            // Handle pinch-to-zoom with two fingers
            final newZoom = (_zoom * details.scale).clamp(0.1, 10.0);
            setState(() => _zoom = newZoom);
          } else if (_isDraggingSelection && duration.inMilliseconds > 0) {
            // Handle single finger drag for selection
            final scrollOffset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
            final position = Duration(
              milliseconds: ((details.localFocalPoint.dx + scrollOffset) /
                      timelineWidth *
                      duration.inMilliseconds)
                  .round()
                  .clamp(0, duration.inMilliseconds),
            );
            setState(() {
              _dragSelectionEnd = position;
            });
          }
        },
        onScaleEnd: (details) {
          if (_isDraggingSelection &&
              _dragSelectionStart != null &&
              _dragSelectionEnd != null) {
            // Finalize selection
            final start = _dragSelectionStart!.inMilliseconds <
                    _dragSelectionEnd!.inMilliseconds
                ? _dragSelectionStart!
                : _dragSelectionEnd!;
            final end = _dragSelectionStart!.inMilliseconds <
                    _dragSelectionEnd!.inMilliseconds
                ? _dragSelectionEnd!
                : _dragSelectionStart!;

            if ((end - start).inMilliseconds > 50) {
              // Only set selection if it's meaningful (> 50ms)
              ref
                  .read(playbackNotifierProvider.notifier)
                  .setSelection(start, end);
            }
          }
          setState(() {
            _isDraggingSelection = false;
            _dragSelectionStart = null;
            _dragSelectionEnd = null;
          });
        },
        onTapDown: (details) {
          if (duration.inMilliseconds == 0) return;
          final scrollOffset =
              _scrollController.hasClients ? _scrollController.offset : 0.0;
          final position = Duration(
            milliseconds: ((details.localPosition.dx + scrollOffset) /
                    timelineWidth *
                    duration.inMilliseconds)
                .round(),
          );
          ref.read(playbackNotifierProvider.notifier).seek(position);
          widget.onSeek(position);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: timelineWidth,
            child: Column(
              children: [
                // Time ruler - OUTSIDE vertical scroll to match labels structure
                _buildTimeRuler(context, timelineWidth),

                // Scrollable tracks area
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Sync vertical scroll with labels when tracks scroll
                      if (notification.metrics.axis == Axis.vertical &&
                          _labelsVerticalController.hasClients &&
                          _labelsVerticalController.offset !=
                              notification.metrics.pixels) {
                        _labelsVerticalController
                            .jumpTo(notification.metrics.pixels);
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _tracksVerticalController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Video track with thumbnails
                          _buildVideoTrack(
                            context,
                            timelineWidth,
                            playbackState,
                          ),

                          // Audio track with waveform
                          _buildAudioTrack(
                            context,
                            timelineWidth,
                            playbackState,
                          ),

                          if (widget.showNsfwGraph)
                            _buildNsfwScoreTrack(
                              context,
                              timelineWidth,
                              playbackState,
                            ),

                          if (widget.showNudenetTrack)
                            _buildNudenetTrack(
                              context,
                              timelineWidth,
                              playbackState,
                            ),

                          if (widget.showModestyTrack)
                            _buildModestyTrack(
                              context,
                              timelineWidth,
                              playbackState,
                            ),

                          // Detections track
                          _buildTrack(
                            context,
                            height: 30,
                            color: Colors.orange.withValues(alpha: 0.1),
                            child:
                                _buildDetectionMarkers(context, timelineWidth),
                            playbackState: playbackState,
                            timelineWidth: timelineWidth,
                          ),

                          // Edits track
                          _buildTrack(
                            context,
                            height: 30,
                            color: Colors.purple.withValues(alpha: 0.1),
                            child: _buildEditMarkers(context, timelineWidth),
                            playbackState: playbackState,
                            timelineWidth: timelineWidth,
                          ),

                          // Subtitles track
                          _buildSubtitlesTrack(
                            context,
                            timelineWidth,
                            playbackState,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;
    // Match the loading logic with settings
    final interval =
        ref.watch(settingsNotifierProvider).thumbnailInterval.inSeconds;
    // Use actual loaded count if available, otherwise estimate based on settings
    final thumbnailCount = _thumbnailImages?.length ??
        (duration.inSeconds / interval).ceil().clamp(1, 300);
    const trackHeight = 64.0;

    return Container(
      height: trackHeight,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          // Thumbnail strip with shimmer animation when loading
          if (widget.media != null && widget.media!.isVideo)
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) => CustomPaint(
                painter: _ThumbnailStripPainter(
                  duration: duration,
                  zoom: _zoom,
                  primaryColor: colorScheme.primary,
                  thumbnailCount: thumbnailCount,
                  thumbnailImages: _thumbnailImages,
                  isLoading: _isLoadingThumbnails,
                  animationValue: _shimmerController.value,
                ),
                size: Size(timelineWidth, trackHeight),
              ),
            ),
          // Loading indicator badge for thumbnails
          if (_isLoadingThumbnails &&
              widget.media != null &&
              widget.media!.isVideo)
            Positioned(
              right: 8,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Loading thumbnails...',
                      style: TextStyle(
                        fontSize: 9,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Media clip overlay
          _buildMediaClipOverlay(context, timelineWidth),
          // Selection overlay
          if (_isDraggingSelection)
            _buildDragSelectionOverlay(trackHeight, timelineWidth, duration),
          if (playbackState.hasSelection && duration.inMilliseconds > 0)
            _buildSelectionRegion(
              trackHeight,
              playbackState,
              timelineWidth,
              duration,
            ),
          // Playhead
          _buildPlayhead(trackHeight, playbackState, timelineWidth),
        ],
      ),
    );
  }

  Widget _buildAudioTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          // Waveform with zoom
          CustomPaint(
            painter: _MiniWaveformPainter(
              color: colorScheme.secondary,
              duration: duration,
              zoom: _zoom,
              detections:
                  widget.detections.where((d) => d.isAudioDetection).toList(),
            ),
            size: Size(timelineWidth, 40),
          ),
          // Selection overlay
          if (_isDraggingSelection)
            _buildDragSelectionOverlay(40, timelineWidth, duration),
          if (playbackState.hasSelection && duration.inMilliseconds > 0)
            _buildSelectionRegion(40, playbackState, timelineWidth, duration),
          // Playhead
          _buildPlayhead(40, playbackState, timelineWidth),
        ],
      ),
    );
  }

  Widget _buildSubtitlesTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;
    const trackHeight = 30.0;
    const trackColor = Colors.teal;

    return Container(
      height: trackHeight,
      decoration: BoxDecoration(
        color: trackColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          // Subtitle segments
          if (widget.subtitleTrack != null && duration.inMilliseconds > 0)
            ...widget.subtitleTrack!.segments.map((segment) {
              final startX =
                  (segment.startTime.inMilliseconds / duration.inMilliseconds) *
                      timelineWidth;
              final endX =
                  (segment.endTime.inMilliseconds / duration.inMilliseconds) *
                      timelineWidth;
              final width = endX - startX;

              return Positioned(
                left: startX,
                top: 2,
                bottom: 2,
                child: Tooltip(
                  message: segment.text,
                  child: Container(
                    width: math.max(width, 4),
                    decoration: BoxDecoration(
                      color: trackColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: trackColor.withValues(alpha: 0.8),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: width > 40
                        ? Text(
                            segment.text,
                            style: TextStyle(
                              fontSize: 8,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        : null,
                  ),
                ),
              );
            }),
          // Empty state
          if (widget.subtitleTrack == null && !widget.isGeneratingSubtitles)
            Center(
              child: Text(
                'Click + to generate subtitles',
                style: TextStyle(
                  fontSize: 9,
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Loading state
          if (widget.isGeneratingSubtitles)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(trackColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Generating subtitles...',
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          // Selection overlay
          if (_isDraggingSelection)
            _buildDragSelectionOverlay(trackHeight, timelineWidth, duration),
          if (playbackState.hasSelection && duration.inMilliseconds > 0)
            _buildSelectionRegion(
              trackHeight,
              playbackState,
              timelineWidth,
              duration,
            ),
          // Playhead
          _buildPlayhead(trackHeight, playbackState, timelineWidth),
        ],
      ),
    );
  }

  Widget _buildNsfwScoreTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final duration = widget.media?.duration ?? Duration.zero;

    return _buildTrack(
      context,
      height: 30,
      color: Colors.pink.withValues(alpha: 0.08),
      playbackState: playbackState,
      timelineWidth: timelineWidth,
      child: widget.nsfwFrameResults.isEmpty || duration.inMilliseconds == 0
          ? Center(
              child: Text(
                'No NSFW frame scores available',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : CustomPaint(
              painter: _NsfwScorePainter(
                duration: duration,
                frameResults: widget.nsfwFrameResults,
                threshold: widget.nsfwThreshold,
                lineColor: Colors.pink,
              ),
              size: Size(timelineWidth, 30),
            ),
    );
  }

  Widget _buildNudenetTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final duration = widget.media?.duration ?? Duration.zero;

    return _buildTrack(
      context,
      height: 30,
      color: Colors.deepPurple.withValues(alpha: 0.08),
      playbackState: playbackState,
      timelineWidth: timelineWidth,
      child: widget.nsfwFrameResults.isEmpty || duration.inMilliseconds == 0
          ? Center(
              child: Text(
                'No NudeNet frame data available',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : CustomPaint(
              painter: _NudenetConfidencePainter(
                duration: duration,
                frameResults: widget.nsfwFrameResults,
                lineColor: Colors.deepPurple,
              ),
              size: Size(timelineWidth, 30),
            ),
    );
  }

  Widget _buildModestyTrack(
    BuildContext context,
    double timelineWidth,
    PlaybackState playbackState,
  ) {
    final duration = widget.media?.duration ?? Duration.zero;

    return _buildTrack(
      context,
      height: 30,
      color: AppTheme.femaleExposureColor.withValues(alpha: 0.08),
      playbackState: playbackState,
      timelineWidth: timelineWidth,
      child: widget.nsfwFrameResults.isEmpty || duration.inMilliseconds == 0
          ? Center(
              child: Text(
                'No modesty frame data available',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : CustomPaint(
              painter: _ModestyConfidencePainter(
                duration: duration,
                frameResults: widget.nsfwFrameResults,
                lineColor: AppTheme.femaleExposureColor,
              ),
              size: Size(timelineWidth, 30),
            ),
    );
  }

  Widget _buildDragSelectionOverlay(
    double height,
    double timelineWidth,
    Duration duration,
  ) {
    if (_dragSelectionStart == null || _dragSelectionEnd == null) {
      return const SizedBox.shrink();
    }

    final startX =
        (_dragSelectionStart!.inMilliseconds / duration.inMilliseconds) *
            timelineWidth;
    final endX = (_dragSelectionEnd!.inMilliseconds / duration.inMilliseconds) *
        timelineWidth;

    final left = math.min(startX, endX);
    final width = (startX - endX).abs();

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: Container(
        width: width,
        color: Colors.blue.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              _formatDuration(
                Duration(
                  milliseconds:
                      (width / timelineWidth * duration.inMilliseconds)
                          .round()
                          .abs(),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaClipOverlay(BuildContext context, double timelineWidth) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                widget.media?.name ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRuler(BuildContext context, double timelineWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: CustomPaint(
        painter: _TimeRulerPainter(
          duration: duration,
          zoom: _zoom,
          textColor: colorScheme.onSurface,
          tickColor: colorScheme.outline,
        ),
        size: Size(timelineWidth, 24),
      ),
    );
  }

  Widget _buildTrack(
    BuildContext context, {
    required double height,
    required Color color,
    required Widget child,
    required PlaybackState playbackState,
    required double timelineWidth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          child,
          // Selection region
          if (_isDraggingSelection)
            _buildDragSelectionOverlay(height, timelineWidth, duration),
          if (playbackState.hasSelection && duration.inMilliseconds > 0)
            _buildSelectionRegion(
              height,
              playbackState,
              timelineWidth,
              duration,
            ),
          // Playhead
          _buildPlayhead(height, playbackState, timelineWidth),
        ],
      ),
    );
  }

  Widget _buildSelectionRegion(
    double height,
    PlaybackState playbackState,
    double timelineWidth,
    Duration duration,
  ) {
    final startX = (playbackState.selectionStart!.inMilliseconds /
            duration.inMilliseconds) *
        timelineWidth;
    final endX =
        (playbackState.selectionEnd!.inMilliseconds / duration.inMilliseconds) *
            timelineWidth;

    return Positioned(
      left: startX,
      top: 0,
      bottom: 0,
      child: Container(
        width: endX - startX,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          border: const Border(
            left: BorderSide(color: Colors.blue, width: 2),
            right: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayhead(
    double height,
    PlaybackState playbackState,
    double timelineWidth,
  ) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    final playheadX =
        (playbackState.position.inMilliseconds / duration.inMilliseconds) *
            timelineWidth;

    return Positioned(
      left: playheadX - 1,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionMarkers(BuildContext context, double timelineWidth) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    return Stack(
      children: widget.detections.where((d) => !d.isRejected).map((detection) {
        final startX =
            (detection.startTime.inMilliseconds / duration.inMilliseconds) *
                timelineWidth;
        final width = ((detection.endTime.inMilliseconds -
                    detection.startTime.inMilliseconds) /
                duration.inMilliseconds) *
            timelineWidth;

        return Positioned(
          left: startX,
          top: 2,
          bottom: 2,
          child: Container(
            width: math.max(width, 8),
            decoration: BoxDecoration(
              color: _getDetectionColor(detection).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: _getDetectionColor(detection),
              ),
            ),
            child: Tooltip(
              message:
                  '${detection.typeDisplayName}\n${_formatDuration(detection.startTime)} - ${_formatDuration(detection.endTime)}',
              child: Icon(
                _getDetectionIcon(detection),
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditMarkers(BuildContext context, double timelineWidth) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    return Stack(
      children: widget.editActions
          .where((e) => e.enabled)
          .map(
            (action) => _EditActionMarker(
              key: ValueKey(action.id),
              action: action,
              duration: duration,
              timelineWidth: timelineWidth,
              editColor: _getEditColor(action.type),
              editIcon: _getEditIcon(action.type),
              onTap: () {
                if (action.type == EditActionType.blur) {
                  widget.onEditBlurAction?.call(action.id);
                }
              },
              onUpdated: widget.onEditActionUpdated,
              onRemoved: widget.onRemoveEditAction,
              formatDuration: _formatDuration,
            ),
          )
          .toList(),
    );
  }

  void _cutSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    if (!playbackState.hasSelection || widget.media == null) return;

    final action = EditAction.cut(
      id: _uuid.v4(),
      mediaId: widget.media!.id,
      startTime: playbackState.selectionStart!,
      endTime: playbackState.selectionEnd!,
    );

    widget.onAddEditAction(action);
    ref.read(playbackNotifierProvider.notifier).clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cut added to timeline'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _muteSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    if (!playbackState.hasSelection || widget.media == null) return;

    final action = EditAction.mute(
      id: _uuid.v4(),
      mediaId: widget.media!.id,
      startTime: playbackState.selectionStart!,
      endTime: playbackState.selectionEnd!,
    );

    widget.onAddEditAction(action);
    ref.read(playbackNotifierProvider.notifier).clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mute added to timeline'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _blurSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    if (!playbackState.hasSelection || widget.media == null) return;

    final action = EditAction.blur(
      id: _uuid.v4(),
      mediaId: widget.media!.id,
      startTime: playbackState.selectionStart!,
      endTime: playbackState.selectionEnd!,
      boundingBox: const BoundingBox(
        left: 0.25,
        top: 0.25,
        width: 0.5,
        height: 0.5,
      ),
      intensity: 0.75, // 0.0 to 1.0 range, moderate blur
    );

    widget.onAddEditAction(action);
    ref.read(playbackNotifierProvider.notifier).clearSelection();

    widget.onEditBlurAction?.call(action.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Blur added - drag handles to adjust region'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _beepSelection() {
    final playbackState = ref.read(playbackNotifierProvider);
    if (!playbackState.hasSelection || widget.media == null) return;

    final action = EditAction.beep(
      id: _uuid.v4(),
      mediaId: widget.media!.id,
      startTime: playbackState.selectionStart!,
      endTime: playbackState.selectionEnd!,
    );

    widget.onAddEditAction(action);
    ref.read(playbackNotifierProvider.notifier).clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beep added to timeline'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Color _getDetectionColor(Detection detection) => AppTheme.getDetectionColor(
    detection.visualContentCategoryId ?? detection.type.name,
  );

  IconData _getDetectionIcon(Detection detection) {
    if (detection.visualContentCategoryId == 'nudity') {
      return Icons.no_adult_content;
    }
    switch (detection.type) {
      case ContentType.profanity:
        return Icons.volume_off;
      case ContentType.nsfw:
        return Icons.visibility_off;
    }
  }

  Color _getEditColor(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Colors.purple;
      case EditActionType.beep:
        return Colors.indigo;
      case EditActionType.blur:
        return Colors.blue;
      case EditActionType.cut:
        return Colors.red;
      case EditActionType.skip:
        return Colors.grey;
    }
  }

  IconData _getEditIcon(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Icons.volume_off;
      case EditActionType.beep:
        return Icons.notifications;
      case EditActionType.blur:
        return Icons.blur_on;
      case EditActionType.cut:
        return Icons.content_cut;
      case EditActionType.skip:
        return Icons.skip_next;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }
}

/// Draggable and scalable edit action marker
class _EditActionMarker extends StatefulWidget {
  const _EditActionMarker({
    required this.action,
    required this.duration,
    required this.timelineWidth,
    required this.editColor,
    required this.editIcon,
    required this.formatDuration,
    super.key,
    this.onTap,
    this.onUpdated,
    this.onRemoved,
  });

  final EditAction action;
  final Duration duration;
  final double timelineWidth;
  final Color editColor;
  final IconData editIcon;
  final VoidCallback? onTap;
  final void Function(EditAction)? onUpdated;
  final void Function(String)? onRemoved;
  final String Function(Duration) formatDuration;

  @override
  State<_EditActionMarker> createState() => _EditActionMarkerState();
}

class _EditActionMarkerState extends State<_EditActionMarker> {
  bool _isDragging = false;
  bool _isDraggingLeftEdge = false;
  bool _isDraggingRightEdge = false;
  Duration _tempStartTime = Duration.zero;
  Duration _tempEndTime = Duration.zero;

  double get startX =>
      (_isDragging || _isDraggingLeftEdge || _isDraggingRightEdge
          ? _tempStartTime.inMilliseconds
          : widget.action.startTime.inMilliseconds) /
      widget.duration.inMilliseconds *
      widget.timelineWidth;

  double get endX =>
      (_isDragging || _isDraggingLeftEdge || _isDraggingRightEdge
          ? _tempEndTime.inMilliseconds
          : widget.action.endTime.inMilliseconds) /
      widget.duration.inMilliseconds *
      widget.timelineWidth;

  double get markerWidth => math.max(endX - startX, 8);

  Duration _positionToDuration(double x) => Duration(
        milliseconds:
            (x / widget.timelineWidth * widget.duration.inMilliseconds)
                .round()
                .clamp(0, widget.duration.inMilliseconds),
      );

  @override
  Widget build(BuildContext context) {
    const handleWidth = 8.0;

    return Positioned(
      left: startX,
      top: 2,
      bottom: 2,
      child: SizedBox(
        width: markerWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main draggable body
            Positioned.fill(
              left: handleWidth,
              right: handleWidth,
              child: GestureDetector(
                onTap: widget.onTap,
                onSecondaryTap: () => _showContextMenu(context),
                onPanStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _tempStartTime = widget.action.startTime;
                    _tempEndTime = widget.action.endTime;
                  });
                },
                onPanUpdate: (details) {
                  if (!_isDragging) return;
                  final delta = _positionToDuration(details.delta.dx + startX) -
                      _positionToDuration(startX);
                  final newStart = _tempStartTime + delta;
                  final newEnd = _tempEndTime + delta;

                  // Keep within bounds
                  if (newStart >= Duration.zero && newEnd <= widget.duration) {
                    setState(() {
                      _tempStartTime = newStart;
                      _tempEndTime = newEnd;
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_isDragging) {
                    widget.onUpdated?.call(
                      widget.action.copyWith(
                        startTime: _tempStartTime,
                        endTime: _tempEndTime,
                      ),
                    );
                    setState(() => _isDragging = false);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.editColor
                          .withValues(alpha: _isDragging ? 0.9 : 0.7),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: widget.editColor,
                        width: _isDragging ? 2 : 1,
                      ),
                    ),
                    child: Tooltip(
                      message:
                          '${widget.action.typeLabel}\n${widget.formatDuration(widget.action.startTime)} - ${widget.formatDuration(widget.action.endTime)}',
                      child: Center(
                        child: Icon(
                          widget.editIcon,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Left resize handle
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: handleWidth,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _isDraggingLeftEdge = true;
                    _tempStartTime = widget.action.startTime;
                    _tempEndTime = widget.action.endTime;
                  });
                },
                onPanUpdate: (details) {
                  if (!_isDraggingLeftEdge) return;
                  final newStart =
                      _positionToDuration(startX + details.delta.dx);
                  if (newStart <
                      _tempEndTime - const Duration(milliseconds: 100)) {
                    setState(() => _tempStartTime = newStart);
                  }
                },
                onPanEnd: (details) {
                  if (_isDraggingLeftEdge) {
                    widget.onUpdated?.call(
                      widget.action.copyWith(startTime: _tempStartTime),
                    );
                    setState(() => _isDraggingLeftEdge = false);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.editColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right resize handle
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: handleWidth,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _isDraggingRightEdge = true;
                    _tempStartTime = widget.action.startTime;
                    _tempEndTime = widget.action.endTime;
                  });
                },
                onPanUpdate: (details) {
                  if (!_isDraggingRightEdge) return;
                  final newEnd = _positionToDuration(endX + details.delta.dx);
                  if (newEnd >
                      _tempStartTime + const Duration(milliseconds: 100)) {
                    setState(() => _tempEndTime = newEnd);
                  }
                },
                onPanEnd: (details) {
                  if (_isDraggingRightEdge) {
                    widget.onUpdated?.call(
                      widget.action.copyWith(endTime: _tempEndTime),
                    );
                    setState(() => _isDraggingRightEdge = false);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.editColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        startX + 50,
        100,
        startX + 150,
        200,
      ),
      items: [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        widget.onRemoved?.call(widget.action.id);
      }
    });
  }
}

class _TrackLabel extends StatelessWidget {
  const _TrackLabel({
    required this.icon,
    required this.label,
    required this.color,
    this.height = 30,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      );
}

/// Special track label for subtitles with generate button
class _SubtitleTrackLabel extends StatelessWidget {
  const _SubtitleTrackLabel({
    required this.hasSubtitles,
    required this.isGenerating,
    this.onGenerate,
    this.onDelete,
    this.language,
  });

  final bool hasSubtitles;
  final bool isGenerating;
  final VoidCallback? onGenerate;
  final VoidCallback? onDelete;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const trackColor = Colors.teal;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.subtitles, size: 14, color: trackColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              hasSubtitles && language != null
                  ? 'Subtitles ($language)'
                  : 'Subtitles',
              style: const TextStyle(fontSize: 11, color: trackColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!hasSubtitles && !isGenerating)
            Tooltip(
              message: 'Generate subtitles using ASR',
              child: InkWell(
                onTap: onGenerate,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: trackColor,
                  ),
                ),
              ),
            )
          else if (isGenerating)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(trackColor),
              ),
            ),
          if (hasSubtitles && !isGenerating)
            Tooltip(
              message: 'Delete subtitles',
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: trackColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
      );
}

class _TimeRulerPainter extends CustomPainter {
  _TimeRulerPainter({
    required this.duration,
    required this.zoom,
    required this.textColor,
    required this.tickColor,
  });

  final Duration duration;
  final double zoom;
  final Color textColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
    );

    final pixelsPerSecond = 20.0 * zoom;
    final totalSeconds = duration.inSeconds;

    // Adjust major interval based on zoom level
    int majorInterval;
    if (zoom < 0.5) {
      majorInterval = 30;
    } else if (zoom < 1) {
      majorInterval = 10;
    } else if (zoom < 2) {
      majorInterval = 5;
    } else if (zoom < 4) {
      majorInterval = 2;
    } else {
      majorInterval = 1;
    }

    for (var s = 0; s <= totalSeconds; s++) {
      final x = s * pixelsPerSecond;

      if (s % majorInterval == 0) {
        // Major tick
        canvas.drawLine(
          Offset(x, size.height - 12),
          Offset(x, size.height),
          tickPaint,
        );

        // Label
        final span = TextSpan(
          text: _formatSeconds(s),
          style: textStyle,
        );
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 2));
      } else if (zoom >= 2 && s % (majorInterval ~/ 2 + 1) == 0) {
        // Minor tick (only at higher zoom)
        canvas.drawLine(
          Offset(x, size.height - 6),
          Offset(x, size.height),
          tickPaint,
        );
      }
    }
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) =>
      oldDelegate.duration != duration || oldDelegate.zoom != zoom;
}

class _ThumbnailStripPainter extends CustomPainter {
  _ThumbnailStripPainter({
    required this.duration,
    required this.zoom,
    required this.primaryColor,
    required this.thumbnailCount,
    this.thumbnailImages,
    this.isLoading = false,
    this.animationValue = 0.0,
  });

  final Duration duration;
  final double zoom;
  final Color primaryColor;
  final int thumbnailCount;
  final List<ui.Image>? thumbnailImages;
  final bool isLoading;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0) return;

    final thumbnailWidth = size.width / thumbnailCount;
    final random =
        math.Random(42); // Consistent random for placeholder thumbnails
    final hasThumbnails =
        thumbnailImages != null && thumbnailImages!.isNotEmpty;

    for (var i = 0; i < thumbnailCount; i++) {
      final x = i * thumbnailWidth;
      final rect = Rect.fromLTWH(x, 2, thumbnailWidth - 1, size.height - 4);

      // Draw actual thumbnail if available
      if (hasThumbnails && i < thumbnailImages!.length) {
        final image = thumbnailImages![i];
        final srcRect = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );

        // Scale to fit height while maintaining aspect ratio
        final imageAspectRatio = image.width / image.height;
        final destHeight = size.height - 4;
        final destWidth = destHeight * imageAspectRatio;

        // If thumbnail width is wider than dest width, tile; otherwise center-crop
        if (thumbnailWidth >= destWidth) {
          // Center the thumbnail in its slot
          final destRect = Rect.fromLTWH(
            x + (thumbnailWidth - destWidth) / 2,
            2,
            destWidth,
            destHeight,
          );
          canvas.drawImageRect(
            image,
            srcRect,
            destRect,
            Paint()..filterQuality = FilterQuality.medium,
          );
        } else {
          // Crop to fill the slot
          final cropWidth = image.height * (thumbnailWidth / destHeight);
          final cropX = (image.width - cropWidth) / 2;
          final croppedSrcRect = Rect.fromLTWH(
            math.max(0, cropX),
            0,
            math.min(cropWidth, image.width.toDouble()),
            image.height.toDouble(),
          );
          canvas.drawImageRect(
            image,
            croppedSrcRect,
            rect,
            Paint()..filterQuality = FilterQuality.medium,
          );
        }

        // Draw subtle border around thumbnail
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.black.withValues(alpha: 0.2)
            ..strokeWidth = 0.5,
        );

        // Draw timestamp overlay
        _drawTimestamp(canvas, rect, i);
        continue;
      }

      // Draw placeholder/loading state
      if (isLoading) {
        // Shimmer loading animation
        final shimmerOffset = (animationValue + i * 0.1) % 1.0;
        final shimmerGradient = LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.3),
            primaryColor.withValues(alpha: 0.15),
          ],
          stops: [
            math.max(0, shimmerOffset - 0.3),
            shimmerOffset,
            math.min(1, shimmerOffset + 0.3),
          ],
        );

        final shimmerPaint = Paint()
          ..shader = shimmerGradient.createShader(rect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          shimmerPaint,
        );

        // Draw film strip icon in center
        final double iconSize = math.min(rect.width * 0.4, 20);
        final iconRect = Rect.fromCenter(
          center: rect.center,
          width: iconSize,
          height: iconSize,
        );

        // Draw simple film frame icon
        final iconPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(iconRect, const Radius.circular(2)),
          iconPaint,
        );

        // Draw film perforations
        final perfSize = iconSize * 0.15;
        for (var p = 0; p < 3; p++) {
          final perfY = iconRect.top + iconSize * (p + 1) / 4;
          canvas
            ..drawRect(
              Rect.fromLTWH(
                iconRect.left - perfSize - 1,
                perfY - perfSize / 2,
                perfSize,
                perfSize,
              ),
              Paint()..color = primaryColor.withValues(alpha: 0.3),
            )
            ..drawRect(
              Rect.fromLTWH(
                iconRect.right + 1,
                perfY - perfSize / 2,
                perfSize,
                perfSize,
              ),
              Paint()..color = primaryColor.withValues(alpha: 0.3),
            );
        }
      } else {
        // Static placeholder when not loading (fallback)
        final hue = (i * 15 + 200) % 360;
        final saturation = 0.3 + random.nextDouble() * 0.2;
        final lightness = 0.3 + random.nextDouble() * 0.2;

        final color =
            HSLColor.fromAHSL(1, hue.toDouble(), saturation, lightness)
                .toColor();

        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.6),
          ],
        );

        final paint = Paint()..shader = gradient.createShader(rect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );

        // Draw frame indicator lines
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 1;

        // Add some visual variation to simulate video frames
        final lineCount = 3 + (random.nextDouble() * 3).toInt();
        for (var j = 0; j < lineCount; j++) {
          final lineY = rect.top + (rect.height * (j + 1) / (lineCount + 1));
          final lineLength = rect.width * (0.3 + random.nextDouble() * 0.5);
          final lineX =
              rect.left + (rect.width - lineLength) * random.nextDouble();
          canvas.drawLine(
            Offset(lineX, lineY),
            Offset(lineX + lineLength, lineY),
            linePaint,
          );
        }
      }

      // Draw timestamp for placeholders too
      _drawTimestamp(canvas, rect, i);
    }
  }

  void _drawTimestamp(Canvas canvas, Rect rect, int index) {
    // Calculate timestamp for this thumbnail
    final totalSeconds = duration.inSeconds;
    final intervalSeconds = totalSeconds / thumbnailCount;
    final seconds = (index * intervalSeconds).round();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Draw semi-transparent background
    final bgRect = Rect.fromLTWH(
      rect.left + 2,
      rect.bottom - 14,
      rect.width - 4,
      12,
    );
    canvas.drawRect(
      bgRect,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Draw text
    final textSpan = TextSpan(
      text: timeText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.bottom - 13,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbnailStripPainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.zoom != zoom ||
      oldDelegate.thumbnailCount != thumbnailCount ||
      oldDelegate.thumbnailImages != thumbnailImages ||
      oldDelegate.isLoading != isLoading ||
      oldDelegate.animationValue != animationValue;
}

class _MiniWaveformPainter extends CustomPainter {
  _MiniWaveformPainter({
    required this.color,
    required this.duration,
    required this.zoom,
    required this.detections,
  });

  final Color color;
  final Duration duration;
  final double zoom;
  final List<Detection> detections;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0) return;

    // Draw detection regions
    for (final detection in detections) {
      final startX =
          (detection.startTime.inMilliseconds / duration.inMilliseconds) *
              size.width;
      final endX =
          (detection.endTime.inMilliseconds / duration.inMilliseconds) *
              size.width;

      final regionPaint = Paint()..color = Colors.orange.withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        regionPaint,
      );
    }

    // Draw waveform background
    final bgPaint = Paint()..color = color.withValues(alpha: 0.1);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw mini waveform - detail increases with zoom
    final wavePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = math.max(1, zoom * 0.5);

    final centerY = size.height / 2;
    final random = math.Random(42);

    // More detailed waveform at higher zoom/widths
    final step = math.max(1, 3.0 / zoom);
    for (double x = 0; x < size.width; x += step) {
      final amplitude = random.nextDouble() * size.height * 0.35;
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        wavePaint,
      );
    }

    // Draw centerline
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.zoom != zoom ||
      oldDelegate.detections != detections;
}

class _NsfwScorePainter extends CustomPainter {
  _NsfwScorePainter({
    required this.duration,
    required this.frameResults,
    required this.threshold,
    required this.lineColor,
  });

  final Duration duration;
  final List<FrameAnalysisResult> frameResults;
  final double threshold;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds <= 0 || frameResults.isEmpty) {
      return;
    }

    final clampedThreshold = threshold.clamp(0.0, 1.0);
    final thresholdY = (1 - clampedThreshold) * size.height;
    final thresholdPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      thresholdPaint,
    );

    final stride =
        math.max(1, (frameResults.length / math.max(1.0, size.width)).ceil());

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();
    var hasPoint = false;

    void addPoint(FrameAnalysisResult frame) {
      final x = (frame.timestamp.inMilliseconds / duration.inMilliseconds) *
          size.width;
      final y = (1 - frame.nsfw.maxNsfwScore.clamp(0.0, 1.0)) * size.height;
      if (!hasPoint) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
        hasPoint = true;
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    for (var i = 0; i < frameResults.length; i += stride) {
      addPoint(frameResults[i]);
    }
    if (frameResults.length > 1) {
      addPoint(frameResults.last);
    }

    if (!hasPoint) {
      return;
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _NsfwScorePainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.frameResults != frameResults ||
      oldDelegate.threshold != threshold ||
      oldDelegate.lineColor != lineColor;
}

class _NudenetConfidencePainter extends CustomPainter {
  _NudenetConfidencePainter({
    required this.duration,
    required this.frameResults,
    required this.lineColor,
  });

  final Duration duration;
  final List<FrameAnalysisResult> frameResults;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds <= 0 || frameResults.isEmpty) {
      return;
    }

    final stride =
        math.max(1, (frameResults.length / math.max(1.0, size.width)).ceil());

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();
    var hasPoint = false;

    void addPoint(FrameAnalysisResult frame) {
      final x = (frame.timestamp.inMilliseconds / duration.inMilliseconds) *
          size.width;
      final regions = frame.visualContent?.detectedRegions ?? const [];
      final maxConfidence = regions.isEmpty
          ? 0.0
          : regions
              .map((r) => r.confidence)
              .reduce((a, b) => a > b ? a : b)
              .clamp(0.0, 1.0);
      final y = (1 - maxConfidence) * size.height;
      if (!hasPoint) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
        hasPoint = true;
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    for (var i = 0; i < frameResults.length; i += stride) {
      addPoint(frameResults[i]);
    }
    if (frameResults.length > 1) {
      addPoint(frameResults.last);
    }

    if (!hasPoint) {
      return;
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _NudenetConfidencePainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.frameResults != frameResults ||
      oldDelegate.lineColor != lineColor;
}

class _ModestyConfidencePainter extends CustomPainter {
  _ModestyConfidencePainter({
    required this.duration,
    required this.frameResults,
    required this.lineColor,
  });

  final Duration duration;
  final List<FrameAnalysisResult> frameResults;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds <= 0 || frameResults.isEmpty) {
      return;
    }

    final stride =
        math.max(1, (frameResults.length / math.max(1.0, size.width)).ceil());

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();
    var hasPoint = false;

    void addPoint(FrameAnalysisResult frame) {
      final x = (frame.timestamp.inMilliseconds / duration.inMilliseconds) *
          size.width;
      final regions = frame.visualContent?.detectedRegions ?? const [];
      final modestyRegions = regions
          .where((region) => _modestyTrackCategoryIdForLabel(region.label) != null)
          .toList(growable: false);
      final maxConfidence = modestyRegions.isEmpty
          ? 0.0
          : modestyRegions
              .map((region) => region.confidence)
              .reduce((a, b) => a > b ? a : b)
              .clamp(0.0, 1.0);
      final y = (1 - maxConfidence) * size.height;
      if (!hasPoint) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
        hasPoint = true;
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    for (var i = 0; i < frameResults.length; i += stride) {
      addPoint(frameResults[i]);
    }
    if (frameResults.length > 1) {
      addPoint(frameResults.last);
    }

    if (!hasPoint) {
      return;
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ModestyConfidencePainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.frameResults != frameResults ||
      oldDelegate.lineColor != lineColor;
}
