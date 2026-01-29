import 'package:kidslens_video_editor/data/models/models.dart';

import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

/// Strategy for selecting sample segment
enum SampleStrategy {
  beginning,
  middle,
  end,
  random,
  detectInteresting,
}

/// Service for running analysis on a sample segment
class SampleAnalysisService {
  SampleAnalysisService({
    required this.analysisService,
    required this.mediaService,
  });

  static const Duration sampleDuration = Duration(seconds: 5);

  final AnalysisService analysisService;
  final MediaService mediaService;

  /// Extract a representative sample offset from the media
  Future<Duration> selectSampleOffset(
    MediaFile media, {
    Duration? userPreference,
    SampleStrategy strategy = SampleStrategy.detectInteresting,
  }) async {
    if (userPreference != null) {
      return _clampOffset(userPreference, media.duration);
    }

    switch (strategy) {
      case SampleStrategy.beginning:
        return Duration.zero;
      case SampleStrategy.middle:
        final middle = media.duration ~/ 2;
        return _clampOffset(middle, media.duration);
      case SampleStrategy.end:
        final end = media.duration - sampleDuration;
        return _clampOffset(end, media.duration);
      case SampleStrategy.random:
        final maxOffset = media.duration - sampleDuration;
        if (maxOffset <= Duration.zero) return Duration.zero;
        final randomMs = DateTime.now().millisecondsSinceEpoch %
            maxOffset.inMilliseconds;
        return Duration(milliseconds: randomMs);
      case SampleStrategy.detectInteresting:
        return _detectInterestingOffset(media);
    }
  }

  /// Detect an "interesting" segment with potential content
  Future<Duration> _detectInterestingOffset(MediaFile media) async {
    // TODO: Implement scene change detection to find interesting segments
    // For now, use middle of the video
    final middle = media.duration ~/ 2;
    return _clampOffset(middle, media.duration);
  }

  Duration _clampOffset(Duration offset, Duration totalDuration) {
    final maxOffset = totalDuration - sampleDuration;
    if (offset < Duration.zero) return Duration.zero;
    if (offset > maxOffset) return maxOffset.isNegative ? Duration.zero : maxOffset;
    return offset;
  }

  /// Run analysis on a sample segment
  Stream<AnalysisProgress> analyzeSample(
    MediaFile media,
    Duration offset,
    AnalysisSettings settings,
  ) async* {
    // TODO: Extract sample segment and run analysis
    // For now, delegate to full analysis service
    await for (final progress in analysisService.analyze(
      media.path,
      settings,
    )) {
      yield progress;
    }
  }
}

/// Result of sample analysis
class SampleAnalysisResult {
  const SampleAnalysisResult({
    required this.sampleOffset,
    required this.sampleDuration,
    required this.settingsUsed,
    required this.profanityCount,
    required this.nudityCount,
    required this.violenceCount,
  }) : hasContent = profanityCount > 0 || nudityCount > 0 || violenceCount > 0;

  final Duration sampleOffset;
  final Duration sampleDuration;
  final AnalysisSettings settingsUsed;
  final int profanityCount;
  final int nudityCount;
  final int violenceCount;
  final bool hasContent;
}
