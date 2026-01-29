import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

/// Service for generating and playing beep tones during video playback.
/// 
/// This service manages the lifecycle of beep audio playback:
/// - Beep starts only when explicitly requested while video is playing
/// - Beep stops immediately when video pauses/stops or exits the effect region
/// - Frequency changes are handled by stopping and restarting with new frequency
class BeepAudioService {
  Player? _beepPlayer;
  bool _isPlaying = false;
  int _currentFrequency = 0;
  final Map<int, String> _cachedBeepPaths = {};

  /// Whether the beep is currently playing
  bool get isPlaying => _isPlaying;

  /// The current beep frequency (0 if not playing)
  int get currentFrequency => _isPlaying ? _currentFrequency : 0;

  /// Start playing a beep tone at the specified frequency.
  /// If already playing at the same frequency, this is a no-op.
  /// If playing at a different frequency, stops and restarts.
  Future<void> startBeep({int frequency = 1000}) async {
    // Already playing at same frequency - no-op
    if (_isPlaying && _currentFrequency == frequency) {
      return;
    }

    // Playing at different frequency - stop first
    if (_isPlaying && _currentFrequency != frequency) {
      await _stopBeepInternal();
    }

    try {
      // Get or generate beep audio file
      final beepPath = await _getOrCreateBeepAudioPath(frequency);
      if (beepPath == null) {
        debugPrint('BeepAudioService: Failed to get beep audio path');
        return;
      }

      // Create player for beep
      _beepPlayer = Player();
      await _beepPlayer!.setPlaylistMode(PlaylistMode.loop);
      await _beepPlayer!.open(Media(beepPath), play: true);
      
      _isPlaying = true;
      _currentFrequency = frequency;
      
      debugPrint('BeepAudioService: Started beep at ${frequency}Hz');
    } catch (e) {
      debugPrint('BeepAudioService: Error starting beep: $e');
      await _cleanupPlayer();
    }
  }

  /// Stop playing the beep tone immediately.
  /// This is safe to call even if no beep is playing.
  Future<void> stopBeep() async {
    if (!_isPlaying) {
      return;
    }
    await _stopBeepInternal();
    debugPrint('BeepAudioService: Stopped beep');
  }

  /// Internal stop method that always executes
  Future<void> _stopBeepInternal() async {
    try {
      await _beepPlayer?.stop();
    } catch (e) {
      debugPrint('BeepAudioService: Error stopping player: $e');
    }
    await _cleanupPlayer();
  }

  /// Clean up the player resources
  Future<void> _cleanupPlayer() async {
    try {
      await _beepPlayer?.dispose();
    } catch (e) {
      debugPrint('BeepAudioService: Error disposing player: $e');
    }
    _beepPlayer = null;
    _isPlaying = false;
    _currentFrequency = 0;
  }

  /// Get path to beep audio file, generating if needed
  Future<String?> _getOrCreateBeepAudioPath(int frequency) async {
    // Check cache first
    if (_cachedBeepPaths.containsKey(frequency)) {
      final cachedPath = _cachedBeepPaths[frequency]!;
      final file = File(cachedPath);
      if (await file.exists()) {
        return cachedPath;
      }
      // Cached file was deleted, remove from cache
      _cachedBeepPaths.remove(frequency);
    }

    try {
      // Generate WAV file with beep tone
      final wavData = _generateSineWave(frequency: frequency);
      
      final tempDir = await getTemporaryDirectory();
      final beepFile = File('${tempDir.path}/kidslens_beep_$frequency.wav');
      await beepFile.writeAsBytes(wavData);
      
      _cachedBeepPaths[frequency] = beepFile.path;
      
      return beepFile.path;
    } catch (e) {
      debugPrint('BeepAudioService: Error generating beep audio: $e');
      return null;
    }
  }

  /// Generate a WAV file containing a sine wave at the specified frequency
  Uint8List _generateSineWave({
    int frequency = 1000,
    int sampleRate = 44100,
    double durationSeconds = 0.5,
    double volume = 0.5,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    
    // Generate sine wave samples
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      samples[i] = math.sin(2 * math.pi * frequency * t) * volume;
    }
    
    // Convert to 16-bit PCM
    final pcmData = Int16List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      pcmData[i] = (samples[i] * 32767).toInt().clamp(-32768, 32767);
    }
    
    // Create WAV file
    return _createWavFile(pcmData, sampleRate);
  }

  /// Create a WAV file from PCM data
  Uint8List _createWavFile(Int16List pcmData, int sampleRate) {
    final dataSize = pcmData.length * 2;
    final fileSize = 36 + dataSize;
    
    final buffer = ByteData(44 + dataSize);
    var offset = 0;
    
    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E
    
    // fmt subchunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little); // Subchunk1Size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // AudioFormat (PCM)
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // NumChannels (mono)
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little); // SampleRate
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); // ByteRate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // BlockAlign
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // BitsPerSample
    offset += 2;
    
    // data subchunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little); // Subchunk2Size
    offset += 4;
    
    // Audio data
    for (final sample in pcmData) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }
    
    return buffer.buffer.asUint8List();
  }

  /// Set beep volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_beepPlayer != null) {
      await _beepPlayer!.setVolume(volume * 100);
    }
  }

  /// Dispose resources and clean up cached files
  Future<void> dispose() async {
    await _stopBeepInternal();
    
    // Clean up cached files
    for (final path in _cachedBeepPaths.values) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('BeepAudioService: Error deleting cached file: $e');
      }
    }
    _cachedBeepPaths.clear();
  }
}
