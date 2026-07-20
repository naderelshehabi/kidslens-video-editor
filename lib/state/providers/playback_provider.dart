import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:media_kit/media_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playback_provider.g.dart';

/// Represents the current audio effect state during playback
enum AudioEffectState {
  /// No effect active - play audio at user volume
  none,

  /// Mute effect - silence the audio
  muted,

  /// Beep effect - play beep tone (video audio is muted)
  beep,
}

/// Centralized playback state shared between timeline and preview panel
class PlaybackState {
  const PlaybackState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.userVolume = 1.0,
    this.audioEffectState = AudioEffectState.none,
    this.beepFrequency = 1000,
    this.playbackSpeed = 1.0,
    this.selectionStart,
    this.selectionEnd,
    this.player,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;

  /// The user-controlled volume (0.0 to 1.0) - independent of effects
  final double userVolume;

  /// The current audio effect state
  final AudioEffectState audioEffectState;

  /// The current beep frequency (only relevant when audioEffectState == beep)
  final int beepFrequency;
  final double playbackSpeed;
  final Duration? selectionStart;
  final Duration? selectionEnd;
  final Player? player;

  PlaybackState copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    double? userVolume,
    AudioEffectState? audioEffectState,
    int? beepFrequency,
    double? playbackSpeed,
    Duration? selectionStart,
    Duration? selectionEnd,
    Player? player,
    bool clearSelection = false,
  }) =>
      PlaybackState(
        position: position ?? this.position,
        duration: duration ?? this.duration,
        isPlaying: isPlaying ?? this.isPlaying,
        userVolume: userVolume ?? this.userVolume,
        audioEffectState: audioEffectState ?? this.audioEffectState,
        beepFrequency: beepFrequency ?? this.beepFrequency,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        selectionStart:
            clearSelection ? null : (selectionStart ?? this.selectionStart),
        selectionEnd:
            clearSelection ? null : (selectionEnd ?? this.selectionEnd),
        player: player ?? this.player,
      );

  /// Check if there is a valid selection
  bool get hasSelection =>
      selectionStart != null &&
      selectionEnd != null &&
      selectionEnd! > selectionStart!;

  /// Get the selection duration
  Duration get selectionDuration =>
      hasSelection ? selectionEnd! - selectionStart! : Duration.zero;

  /// The effective volume for the video player (considering effects)
  /// Returns 0.0 when muted or beeping, userVolume otherwise
  double get effectiveVolume =>
      audioEffectState == AudioEffectState.none ? userVolume : 0.0;

  /// Legacy getter for compatibility - returns userVolume
  double get volume => userVolume;
}

/// Provider for managing playback state
@Riverpod(keepAlive: true)
class PlaybackNotifier extends _$PlaybackNotifier {
  @override
  PlaybackState build() => const PlaybackState();

  /// Set the player instance
  void setPlayer(Player player) {
    state = state.copyWith(player: player);
  }

  /// Update position from player stream
  void updatePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  /// Update duration from player stream
  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  /// Update playing state from player stream
  void updatePlaying({required bool isPlaying}) {
    // When playback stops, reset audio effect state
    if (!isPlaying) {
      state = state.copyWith(
        isPlaying: false,
        audioEffectState: AudioEffectState.none,
      );
    } else {
      state = state.copyWith(isPlaying: true);
    }
  }

  /// Update the audio effect state (mute/beep/none)
  /// This is called by the preview panel when checking edit action regions
  void updateAudioEffect(
    AudioEffectState effectState, {
    int beepFrequency = 1000,
  }) {
    if (state.audioEffectState != effectState ||
        (effectState == AudioEffectState.beep &&
            state.beepFrequency != beepFrequency)) {
      state = state.copyWith(
        audioEffectState: effectState,
        beepFrequency: beepFrequency,
      );
    }
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await state.player?.seek(position);
    state = state.copyWith(position: position);
  }

  /// Play or pause
  Future<void> playOrPause() async {
    await state.player?.playOrPause();
  }

  /// Play
  Future<void> play() async {
    await state.player?.play();
  }

  /// Pause
  Future<void> pause() async {
    await state.player?.pause();
  }

  /// Stop
  Future<void> stop() async {
    await state.player?.stop();
  }

  /// Set user volume (0.0 to 1.0) - this is independent of mute/beep effects
  Future<void> setVolume(double volume) async {
    state = state.copyWith(userVolume: volume);
    // Apply volume immediately considering current effect state
    _applyEffectiveVolume();
  }

  /// Apply the effective volume to the player based on effect state
  void _applyEffectiveVolume() {
    final effectiveVol = state.effectiveVolume;
    state.player?.setVolume(effectiveVol * 100);
  }

  /// Sync the player volume with current effect state
  /// Call this when audio effect changes
  void syncPlayerVolume() {
    _applyEffectiveVolume();
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await state.player?.setRate(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Set selection range
  void setSelection(Duration start, Duration end) {
    state = state.copyWith(
      selectionStart: start,
      selectionEnd: end,
    );
  }

  /// Set selection start at current position
  void setSelectionStart() {
    state = state.copyWith(selectionStart: state.position);
  }

  /// Set selection end at current position
  void setSelectionEnd() {
    if (state.selectionStart != null &&
        state.position > state.selectionStart!) {
      state = state.copyWith(selectionEnd: state.position);
    }
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Create an edit action from the current selection
  EditAction? createEditActionFromSelection({
    required String mediaId,
    required EditActionType type,
    BoundingBox? boundingBox,
    String? detectionId,
  }) {
    if (!state.hasSelection) return null;

    return EditAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mediaId: mediaId,
      type: type,
      startTime: state.selectionStart!,
      endTime: state.selectionEnd!,
      boundingBox: boundingBox,
      detectionId: detectionId,
      createdAt: DateTime.now(),
    );
  }

  /// Reset the playback state
  void reset() {
    state = const PlaybackState();
  }
}
