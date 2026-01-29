import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/blur_region_overlay.dart';
import 'package:kidslens_video_editor/state/providers/playback_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Preview panel for video/audio with playback controls using media_kit
class PreviewPanel extends ConsumerStatefulWidget {
  const PreviewPanel({
    required this.media,
    required this.detections,
    required this.editActions,
    super.key,
    this.onEditActionUpdated,
    this.editingBlurActionId,
    this.onEditingBlurActionChanged,
  });

  final MediaFile? media;
  final List<Detection> detections;
  final List<EditAction> editActions;
  final void Function(EditAction)? onEditActionUpdated;
  final String? editingBlurActionId;
  final void Function(String?)? onEditingBlurActionChanged;

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  Player? _player;
  VideoController? _videoController;
  String? _currentMediaPath;
  /// Tracks the previous audio effect state to detect changes
  AudioEffectState _previousEffectState = AudioEffectState.none;
  int _previousBeepFrequency = 0;
  bool _isFullScreen = false;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _player = Player();
    _videoController = VideoController(_player!);

    // Register player with playback provider after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(playbackNotifierProvider.notifier).setPlayer(_player!);
      }
    });

    // Listen to player streams and update provider
    _positionSubscription = _player!.stream.position.listen((position) {
      if (!mounted) return;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(playbackNotifierProvider.notifier).updatePosition(position);
      });
      _checkAndApplyEditActions(position);
    });

    _durationSubscription = _player!.stream.duration.listen((duration) {
      if (!mounted) return;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(playbackNotifierProvider.notifier).updateDuration(duration);
      });
    });

    _playingSubscription = _player!.stream.playing.listen((playing) {
      if (!mounted) return;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(playbackNotifierProvider.notifier).updatePlaying(isPlaying: playing);
        // Handle playback stop - beep should stop immediately
        if (!playing) {
          _stopAllAudioEffects();
        }
      });
    });

    // Load initial media if available
    _loadMedia();
  }

  /// Stop all audio effects and restore normal playback volume
  void _stopAllAudioEffects() {
    // Stop beep audio
    ref.read(beepAudioServiceProvider).stopBeep();
    
    // Reset effect state
    _previousEffectState = AudioEffectState.none;
    _previousBeepFrequency = 0;
    
    // Restore user's intended volume
    final userVolume = ref.read(playbackNotifierProvider).userVolume;
    _player?.setVolume(userVolume * 100);
  }

  void _checkAndApplyEditActions(Duration position) {
    final playbackState = ref.read(playbackNotifierProvider);
    
    // Only apply effects during active playback
    if (!playbackState.isPlaying) {
      return;
    }
    
    // Find any cut actions that should skip
    for (final action in widget.editActions) {
      if (!action.enabled) continue;
      
      if (action.type == EditActionType.cut || action.type == EditActionType.skip) {
        if (action.containsTime(position)) {
          // Skip past this section
          _player?.seek(action.endTime);
          return;
        }
      }
    }
    
    // Determine current audio effect state
    var newEffectState = AudioEffectState.none;
    var beepFrequency = 1000;
    
    // Check for beep region (takes precedence over mute)
    final beepAction = widget.editActions.firstWhere(
      (action) =>
          action.enabled &&
          action.type == EditActionType.beep &&
          action.containsTime(position),
      orElse: () => EditAction.mute(
        id: '',
        mediaId: '',
        startTime: Duration.zero,
        endTime: Duration.zero,
      ),
    );
    
    if (beepAction.id.isNotEmpty) {
      newEffectState = AudioEffectState.beep;
      beepFrequency = beepAction.beepFrequency.toInt();
    } else {
      // Check for mute region
      final inMuteRegion = widget.editActions.any((action) =>
          action.enabled &&
          action.type == EditActionType.mute &&
          action.containsTime(position),);
      
      if (inMuteRegion) {
        newEffectState = AudioEffectState.muted;
      }
    }
    
    // Apply audio effect changes
    _applyAudioEffectState(newEffectState, beepFrequency, playbackState.userVolume);
  }

  /// Apply the audio effect state, managing player volume and beep playback
  void _applyAudioEffectState(AudioEffectState newState, int beepFrequency, double userVolume) {
    final beepService = ref.read(beepAudioServiceProvider);
    
    // Check if state changed
    final stateChanged = newState != _previousEffectState;
    final frequencyChanged = newState == AudioEffectState.beep && 
                             beepFrequency != _previousBeepFrequency;
    
    if (!stateChanged && !frequencyChanged) {
      return; // No change, nothing to do
    }
    
    // Handle transition from previous state
    if (_previousEffectState == AudioEffectState.beep && newState != AudioEffectState.beep) {
      // Was beeping, now not beeping - stop beep
      beepService.stopBeep();
    }
    
    // Apply new state
    switch (newState) {
      case AudioEffectState.none:
        // Normal playback - restore user volume
        _player?.setVolume(userVolume * 100);
        
      case AudioEffectState.muted:
        // Mute the video player
        _player?.setVolume(0);
        
      case AudioEffectState.beep:
        // Mute video and play beep
        _player?.setVolume(0);
        beepService.startBeep(frequency: beepFrequency);
    }
    
    // Update provider state for UI indicators
    ref.read(playbackNotifierProvider.notifier).updateAudioEffect(
      newState, 
      beepFrequency: beepFrequency,
    );
    
    // Remember current state for next comparison
    _previousEffectState = newState;
    _previousBeepFrequency = beepFrequency;
  }

  @override
  void didUpdateWidget(PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if media changed
    if (widget.media?.path != oldWidget.media?.path) {
      _loadMedia();
    }
  }

  void _loadMedia() {
    if (widget.media == null) {
      _stopAllAudioEffects();
      _player?.stop();
      _currentMediaPath = null;
      return;
    }

    final mediaPath = widget.media!.path;
    if (mediaPath == _currentMediaPath) return;

    // Stop any effects from previous media
    _stopAllAudioEffects();
    
    _currentMediaPath = mediaPath;

    // Check if file exists
    final file = File(mediaPath);
    if (!file.existsSync()) {
      debugPrint('Media file not found: $mediaPath');
      return;
    }

    // Open media file
    _player?.open(Media(mediaPath), play: false);
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions first to prevent callbacks after dispose
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    
    // Stop all audio effects
    _stopAllAudioEffects();
    
    // Dispose the player
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playbackState = ref.watch(playbackNotifierProvider);

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Preview area
          Expanded(
            child: widget.media == null
                ? _buildEmptyState(context)
                : widget.media!.isVideo
                    ? _buildVideoPreview(context, playbackState)
                    : _buildAudioPreview(context, playbackState),
          ),
          
          // Playback controls
          if (widget.media != null)
            _buildPlaybackControls(context, playbackState),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a media file to preview',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context, PlaybackState playbackState) {
    final position = playbackState.position;
    
    // Detection overlays for current position
    final activeDetections = widget.detections
        .where((d) => d.containsTime(position) && !d.isRejected)
        .toList();

    // Active blur actions for current position
    final activeBlurActions = widget.editActions
        .where((a) => a.type == EditActionType.blur && 
                      a.enabled && 
                      a.containsTime(position),)
        .toList();

    // Active mute actions for current position
    final isMuted = widget.editActions.any((a) => 
        a.type == EditActionType.mute && 
        a.enabled && 
        a.containsTime(position),);

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = widget.media!.aspectRatio > 0 
            ? widget.media!.aspectRatio 
            : 16 / 9;
        
        // Calculate actual video display size
        var videoWidth = constraints.maxWidth;
        var videoHeight = videoWidth / aspectRatio;
        
        if (videoHeight > constraints.maxHeight) {
          videoHeight = constraints.maxHeight;
          videoWidth = videoHeight * aspectRatio;
        }
        
        final displaySize = Size(videoWidth, videoHeight);

        return Stack(
          children: [
            // Video player
            Center(
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: Stack(
                  children: [
                    // Video widget - wrapped to disable default gesture handlers
                    if (_videoController != null) IgnorePointer(
                            child: Video(
                              controller: _videoController!,
                              controls: (state) => const SizedBox.shrink(),
                            ),
                          ) else const ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    
                    // Blur overlays during playback
                    ...activeBlurActions.map((action) {
                      final isEditing = widget.editingBlurActionId == action.id;
                      
                      if (isEditing) {
                        return BlurRegionOverlay(
                          blurAction: action,
                          videoSize: displaySize,
                          isSelected: true,
                          isEditing: true,
                          onBoundingBoxChanged: (newBox) {
                            widget.onEditActionUpdated?.call(
                              action.copyWith(boundingBox: newBox),
                            );
                          },
                          onIntensityChanged: (intensity) {
                            widget.onEditActionUpdated?.call(
                              action.copyWith(blurIntensity: intensity),
                            );
                          },
                          onSelected: () {
                            widget.onEditingBlurActionChanged?.call(action.id);
                          },
                        );
                      } else {
                        return SimpleBlurOverlay(
                          boundingBox: action.boundingBox,
                          intensity: action.blurIntensity,
                          videoSize: displaySize,
                        );
                      }
                    }),
                    
                    // Detection visual overlays
                    ...activeDetections
                        .where((d) => d.isVisualDetection)
                        .map(_buildDetectionOverlay),
                  ],
                ),
              ),
            ),
            
            // Detection indicators on the side
            if (activeDetections.isNotEmpty)
              Positioned(
                top: 8,
                right: 48, // Make room for fullscreen button
                child: Column(
                  children: activeDetections.map((d) => 
                    _buildDetectionBadge(context, d),).toList(),
                ),
              ),

            // Fullscreen toggle button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => _toggleFullScreen(context),
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
              ),
            ),

            // Mute indicator
            if (isMuted)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Muted', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // Play/Pause overlay on tap
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Clear blur editing when tapping elsewhere
                  if (widget.editingBlurActionId != null) {
                    widget.onEditingBlurActionChanged?.call(null);
                  } else {
                    ref.read(playbackNotifierProvider.notifier).playOrPause();
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: !playbackState.isPlaying
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Selection indicator
            if (playbackState.hasSelection)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Selection: ${_formatDuration(playbackState.selectionStart!)} - ${_formatDuration(playbackState.selectionEnd!)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetectionOverlay(Detection detection) {
    // For visual detections, we would show bounding boxes here
    if (detection.isVisualDetection) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _getDetectionColor(detection),
            width: 3,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetectionBadge(BuildContext context, Detection detection) {
    final color = _getDetectionColor(detection);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDetectionIcon(detection),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            detection.typeDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context, PlaybackState playbackState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final position = playbackState.position;

    // Detection indicators for audio
    final activeDetections = widget.detections
        .where((d) => d.containsTime(position) && !d.isRejected)
        .toList();

    return Column(
      children: [
        // Audio info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audiotrack,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.media!.name,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        
        // Waveform visualization
        Expanded(
          child: _buildWaveform(context, playbackState),
        ),
        
        // Active detections
        if (activeDetections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: activeDetections.map((d) => 
                _buildDetectionBadge(context, d),).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWaveform(BuildContext context, PlaybackState playbackState) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = playbackState.duration.inMilliseconds > 0 
        ? playbackState.duration 
        : (widget.media?.duration ?? Duration.zero);
    
    return CustomPaint(
      painter: _WaveformPainter(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHigh,
        position: playbackState.position,
        duration: duration,
        detections: widget.detections,
        editActions: widget.editActions,
        selectionStart: playbackState.selectionStart,
        selectionEnd: playbackState.selectionEnd,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildPlaybackControls(BuildContext context, PlaybackState playbackState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = playbackState.duration.inMilliseconds > 0 
        ? playbackState.duration 
        : (widget.media?.duration ?? Duration.zero);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Timeline scrubber
          Row(
            children: [
              Text(
                _formatDuration(playbackState.position),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? (playbackState.position.inMilliseconds / 
                           duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0,
                    onChanged: (value) {
                      final seekPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      ref.read(playbackNotifierProvider.notifier).seek(seekPosition);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Playback buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => ref.read(playbackNotifierProvider.notifier).seek(Duration.zero),
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPosition = Duration(
                    milliseconds: math.max(0, playbackState.position.inMilliseconds - 10000),
                  );
                  ref.read(playbackNotifierProvider.notifier).seek(newPosition);
                },
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () => ref.read(playbackNotifierProvider.notifier).playOrPause(),
                child: Icon(playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  final newPosition = Duration(
                    milliseconds: math.min(
                      duration.inMilliseconds,
                      playbackState.position.inMilliseconds + 10000,
                    ),
                  );
                  ref.read(playbackNotifierProvider.notifier).seek(newPosition);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => ref.read(playbackNotifierProvider.notifier).seek(duration),
              ),
              
              const SizedBox(width: 16),

              // Selection buttons
              IconButton(
                icon: Icon(
                  Icons.start,
                  color: playbackState.selectionStart != null ? Colors.blue : null,
                ),
                tooltip: 'Set selection start (I)',
                onPressed: () => ref.read(playbackNotifierProvider.notifier).setSelectionStart(),
              ),
              IconButton(
                icon: Icon(
                  Icons.last_page,
                  color: playbackState.selectionEnd != null ? Colors.blue : null,
                ),
                tooltip: 'Set selection end (O)',
                onPressed: () => ref.read(playbackNotifierProvider.notifier).setSelectionEnd(),
              ),
              if (playbackState.hasSelection)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear selection',
                  onPressed: () => ref.read(playbackNotifierProvider.notifier).clearSelection(),
                ),
              
              const SizedBox(width: 16),
              
              // Volume control
              IconButton(
                icon: Icon(
                  playbackState.volume == 0 ? Icons.volume_off : Icons.volume_up,
                  size: 18,
                ),
                onPressed: () {
                  ref.read(playbackNotifierProvider.notifier).setVolume(
                    playbackState.volume == 0 ? 1.0 : 0,
                  );
                },
              ),
              SizedBox(
                width: 100,
                child: Slider(
                  value: playbackState.volume,
                  onChanged: (value) {
                    ref.read(playbackNotifierProvider.notifier).setVolume(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDetectionColor(Detection detection) {
    switch (detection.type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.nsfw:
        return Colors.red;
      case ContentType.violence:
        return Colors.deepOrange;
      case ContentType.blood:
        return Colors.red.shade900;
      case ContentType.weapons:
        return Colors.amber;
    }
  }

  IconData _getDetectionIcon(Detection detection) {
    switch (detection.type) {
      case ContentType.profanity:
        return Icons.volume_off;
      case ContentType.nsfw:
        return Icons.visibility_off;
      case ContentType.violence:
        return Icons.sports_mma;
      case ContentType.blood:
        return Icons.water_drop;
      case ContentType.weapons:
        return Icons.warning;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final frames = ((duration.inMilliseconds % 1000) / 33.33).round();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
  }

  void _toggleFullScreen(BuildContext context) {
    if (_isFullScreen) {
      Navigator.of(context).pop();
      setState(() => _isFullScreen = false);
    } else {
      setState(() => _isFullScreen = true);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _FullScreenPreview(
            player: _player,
            videoController: _videoController,
            media: widget.media,
            detections: widget.detections,
            editActions: widget.editActions,
            playbackNotifier: ref.read(playbackNotifierProvider.notifier),
            onExitFullScreen: () {
              setState(() => _isFullScreen = false);
            },
          ),
        ),
      );
    }
  }
}

/// Full-screen preview overlay
class _FullScreenPreview extends StatefulWidget {
  const _FullScreenPreview({
    required this.player,
    required this.videoController,
    required this.media,
    required this.detections,
    required this.editActions,
    required this.playbackNotifier,
    required this.onExitFullScreen,
  });

  final Player? player;
  final VideoController? videoController;
  final MediaFile? media;
  final List<Detection> detections;
  final List<EditAction> editActions;
  final PlaybackNotifier playbackNotifier;
  final VoidCallback onExitFullScreen;

  @override
  State<_FullScreenPreview> createState() => _FullScreenPreviewState();
}

class _FullScreenPreviewState extends State<_FullScreenPreview> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          children: [
            // Video
            Center(
              child: widget.videoController != null
                  ? Video(
                      controller: widget.videoController!,
                      controls: (state) => const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
                    stops: [0.0, 0.15, 0.85, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                widget.onExitFullScreen();
                                Navigator.of(context).pop();
                              },
                            ),
                            const Spacer(),
                            if (widget.media != null)
                              Text(
                                widget.media!.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                              onPressed: () {
                                widget.onExitFullScreen();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Center play button
                      StreamBuilder<bool>(
                        stream: widget.player?.stream.playing,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                                onPressed: () {
                                  final position = widget.player?.state.position ?? Duration.zero;
                                  widget.player?.seek(Duration(
                                    milliseconds: math.max(0, position.inMilliseconds - 10000),
                                  ));
                                },
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                onPressed: () => widget.playbackNotifier.playOrPause(),
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                                onPressed: () {
                                  final position = widget.player?.state.position ?? Duration.zero;
                                  final duration = widget.player?.state.duration ?? Duration.zero;
                                  widget.player?.seek(Duration(
                                    milliseconds: math.min(
                                      duration.inMilliseconds,
                                      position.inMilliseconds + 10000,
                                    ),
                                  ));
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const Spacer(),
                      
                      // Bottom controls with timeline
                      StreamBuilder<Duration>(
                        stream: widget.player?.stream.position,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: widget.player?.stream.duration,
                            builder: (context, durationSnapshot) {
                              final position = positionSnapshot.data ?? Duration.zero;
                              final duration = durationSnapshot.data ?? 
                                  (widget.media?.duration ?? Duration.zero);
                              
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white38,
                                        thumbColor: Colors.white,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      ),
                                      child: Slider(
                                        value: duration.inMilliseconds > 0
                                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                            : 0,
                                        onChanged: (value) {
                                          widget.player?.seek(Duration(
                                            milliseconds: (value * duration.inMilliseconds).round(),
                                          ));
                                        },
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for waveform visualization
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.color,
    required this.backgroundColor,
    required this.position,
    required this.duration,
    required this.detections,
    required this.editActions,
    this.selectionStart,
    this.selectionEnd,
  });

  final Color color;
  final Color backgroundColor;
  final Duration position;
  final Duration duration;
  final List<Detection> detections;
  final List<EditAction> editActions;
  final Duration? selectionStart;
  final Duration? selectionEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (duration.inMilliseconds == 0) return;

    // Draw selection region
    if (selectionStart != null && selectionEnd != null) {
      final startX = (selectionStart!.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      final endX = (selectionEnd!.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2);
      
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        selectionPaint,
      );
    }

    // Draw edit action regions
    for (final action in editActions) {
      if (!action.enabled) continue;
      
      final startX = (action.startTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      final endX = (action.endTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      
      final actionPaint = Paint()
        ..color = _getEditActionColor(action.type).withValues(alpha: 0.3);
      
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        actionPaint,
      );
    }

    // Draw detection regions
    for (final detection in detections) {
      if (detection.isRejected) continue;
      
      final startX = (detection.startTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      final endX = (detection.endTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      
      final detectionPaint = Paint()
        ..color = _getDetectionColor(detection.type).withValues(alpha: 0.3);
      
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        detectionPaint,
      );
    }

    // Draw fake waveform
    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    
    final centerY = size.height / 2;
    final random = math.Random(42); // Fixed seed for consistent waveform
    
    for (double x = 0; x < size.width; x += 2) {
      final amplitude = random.nextDouble() * size.height * 0.35;
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        wavePaint,
      );
    }

    // Draw position indicator
    final positionX = (position.inMilliseconds / 
        duration.inMilliseconds) * size.width;
    final positionPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(positionX, 0),
      Offset(positionX, size.height),
      positionPaint,
    );
  }

  Color _getDetectionColor(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.nsfw:
        return Colors.red;
      case ContentType.violence:
        return Colors.deepOrange;
      case ContentType.blood:
        return Colors.red.shade900;
      case ContentType.weapons:
        return Colors.amber;
    }
  }

  Color _getEditActionColor(EditActionType type) {
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

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.position != position ||
        oldDelegate.duration != duration ||
        oldDelegate.detections != detections ||
        oldDelegate.editActions != editActions ||
        oldDelegate.selectionStart != selectionStart ||
        oldDelegate.selectionEnd != selectionEnd;
}
