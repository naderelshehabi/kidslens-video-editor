import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Caches ASR transcription results to avoid redundant re-transcription.
///
/// Cache key is based on audio file size, modification time, model ID,
/// and language. Results are stored as JSON files in the app cache directory.
class AsrCacheService {
  Directory? _cacheDir;

  /// Initialize the cache directory.
  ///
  /// If [cacheDirectory] is provided it is used directly, bypassing
  /// [getApplicationCacheDirectory]. This is useful for tests.
  Future<void> init({Directory? cacheDirectory}) async {
    if (cacheDirectory != null) {
      _cacheDir = cacheDirectory;
    } else {
      final appCache = await getApplicationCacheDirectory();
      _cacheDir = Directory(p.join(appCache.path, 'asr_cache'));
    }
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
  }

  /// Generate a cache key from transcription parameters.
  ///
  /// Uses file size + modification time instead of file hash for speed.
  String _cacheKey({
    required String audioPath,
    required String modelId,
    required String? language,
  }) {
    final file = File(audioPath);
    final stat = file.statSync();
    final raw =
        '${stat.size}_${stat.modified.millisecondsSinceEpoch}_${modelId}_${language ?? "auto"}';
    // Simple hash to avoid filesystem issues with long keys
    var hash = 0;
    for (final c in raw.codeUnits) {
      hash = ((hash << 5) - hash + c) & 0x7FFFFFFF;
    }
    return hash.toRadixString(36);
  }

  /// Look up a cached transcript. Returns null if not cached.
  Future<Transcript?> lookup({
    required String audioPath,
    required String modelId,
    String? language,
  }) async {
    if (_cacheDir == null) await init();
    try {
      final key = _cacheKey(
        audioPath: audioPath,
        modelId: modelId,
        language: language,
      );
      final file = File(p.join(_cacheDir!.path, '$key.json'));
      if (!file.existsSync()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      debugPrint('[AsrCache] Cache hit for $key');
      return Transcript.fromJson(json);
    } catch (e) {
      debugPrint('[AsrCache] Cache lookup failed: $e');
      return null;
    }
  }

  /// Store a transcript result in the cache.
  Future<void> store({
    required String audioPath,
    required String modelId,
    String? language,
    required Transcript transcript,
  }) async {
    if (_cacheDir == null) await init();
    try {
      final key = _cacheKey(
        audioPath: audioPath,
        modelId: modelId,
        language: language,
      );
      final file = File(p.join(_cacheDir!.path, '$key.json'));
      await file.writeAsString(jsonEncode(transcript.toJson()));
      debugPrint('[AsrCache] Stored cache for $key');
    } catch (e) {
      debugPrint('[AsrCache] Cache store failed: $e');
    }
  }

  /// Clear all cached results.
  Future<void> clearAll() async {
    if (_cacheDir == null) await init();
    try {
      if (_cacheDir!.existsSync()) {
        await _cacheDir!.delete(recursive: true);
        _cacheDir!.createSync(recursive: true);
      }
      debugPrint('[AsrCache] Cache cleared');
    } catch (e) {
      debugPrint('[AsrCache] Cache clear failed: $e');
    }
  }

  /// Get the total size of the cache in bytes.
  Future<int> cacheSize() async {
    if (_cacheDir == null) await init();
    if (!_cacheDir!.existsSync()) return 0;
    var total = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
