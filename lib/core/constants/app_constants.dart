/// Application-wide constants
abstract final class AppConstants {
  // ============================================================
  // Application Identity
  // ============================================================

  /// Application name
  static const String appName = 'KidsLens';

  /// Application display name
  static const String appDisplayName = 'KidsLens Video Editor';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Application build number
  static const int appBuildNumber = 1;

  /// Full version string
  static const String fullVersion = '$appVersion+$appBuildNumber';

  /// Copyright notice
  static const String copyright = '© 2026 KidsLens. All rights reserved.';

  // ============================================================
  // Supported Media Formats
  // ============================================================

  /// Supported video container formats
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    'mpg',
    'mpeg',
  ];

  /// Supported audio formats
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'm4a',
    'ogg',
    'wma',
    'opus',
  ];

  /// Supported video codecs
  static const List<String> supportedVideoCodecs = [
    'h264',
    'h265',
    'hevc',
    'vp8',
    'vp9',
    'av1',
    'mpeg4',
    'mpeg2',
  ];

  /// Supported audio codecs
  static const List<String> supportedAudioCodecs = [
    'aac',
    'mp3',
    'opus',
    'vorbis',
    'flac',
    'pcm',
    'ac3',
    'eac3',
  ];

  // ============================================================
  // Default Thresholds
  // ============================================================

  /// Default violence detection confidence threshold (0.0 - 1.0)
  static const double defaultViolenceThreshold = 0.65;

  /// Default nudity detection confidence threshold (0.0 - 1.0)
  static const double defaultNudityThreshold = 0.70;

  /// Default profanity detection confidence threshold (0.0 - 1.0)
  static const double defaultProfanityThreshold = 0.80;

  /// Default drug/substance detection confidence threshold (0.0 - 1.0)
  static const double defaultDrugThreshold = 0.60;

  /// Default weapon detection confidence threshold (0.0 - 1.0)
  static const double defaultWeaponThreshold = 0.55;

  /// Default gore detection confidence threshold (0.0 - 1.0)
  static const double defaultGoreThreshold = 0.50;

  /// Minimum confidence for any detection to be considered valid
  static const double minimumConfidence = 0.30;

  /// Minimum segment duration for detection regions (milliseconds)
  static const int minDetectionDurationMs = 500;

  /// Padding around detected content for safer editing (milliseconds)
  static const int detectionPaddingMs = 250;

  // ============================================================
  // Model Tier Specifications
  // ============================================================

  /// Model tier definitions with performance characteristics
  static const Map<String, ModelTierSpec> modelTiers = {
    'lite': ModelTierSpec(
      name: 'Lite',
      description: 'Fast processing, lower accuracy',
      vramRequirementMB: 512,
      diskRequirementMB: 100,
      realtimeMultiple: 5,
      accuracyPercent: 85,
    ),
    'balanced': ModelTierSpec(
      name: 'Balanced',
      description: 'Good balance of speed and accuracy',
      vramRequirementMB: 2048,
      diskRequirementMB: 500,
      realtimeMultiple: 3,
      accuracyPercent: 92,
    ),
    'quality': ModelTierSpec(
      name: 'Quality',
      description: 'Highest accuracy, slower processing',
      vramRequirementMB: 4096,
      diskRequirementMB: 1500,
      realtimeMultiple: 1.5,
      accuracyPercent: 97,
    ),
  };

  // ============================================================
  // Frame Buffer Settings
  // ============================================================

  /// Maximum frame buffer for 4K content
  static const int maxFrames4K = 30;

  /// Maximum frame buffer for HD content (1080p)
  static const int maxFramesHD = 60;

  /// Maximum frame buffer for SD content
  static const int maxFramesSD = 120;

  /// Frame batch size for GPU processing
  static const int frameBatchSize = 8;

  // ============================================================
  // Analysis Settings
  // ============================================================

  /// Sample analysis duration for quick preview
  static const Duration sampleDuration = Duration(seconds: 5);

  /// A/V sync tolerance
  static const Duration syncTolerance = Duration(milliseconds: 40);

  /// Target realtime multiple for analysis
  static const double targetRealtimeMultiple = 3;

  /// Maximum video duration for processing (10 hours)
  static const Duration maxVideoDuration = Duration(hours: 10);

  /// Minimum video duration for processing
  static const Duration minVideoDuration = Duration(seconds: 1);

  /// Analysis progress update interval
  static const Duration progressUpdateInterval = Duration(milliseconds: 100);

  // ============================================================
  // Network & Download Settings
  // ============================================================

  /// Model download chunk size
  static const int downloadChunkSize = 1024 * 1024; // 1MB

  /// HuggingFace API base URL
  static const String huggingFaceBaseUrl = 'https://huggingface.co';

  /// Network timeout for downloads
  static const Duration downloadTimeout = Duration(minutes: 30);

  /// Network timeout for API requests
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for operations
  static const int maxRetries = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================================
  // Export Settings
  // ============================================================

  /// Default export video codec
  static const String defaultExportVideoCodec = 'h264';

  /// Default export audio codec
  static const String defaultExportAudioCodec = 'aac';

  /// Default export container format
  static const String defaultExportContainer = 'mp4';

  /// Default export video bitrate (Mbps)
  static const double defaultExportVideoBitrateMbps = 8;

  /// Default export audio bitrate (kbps)
  static const int defaultExportAudioBitrateKbps = 192;

  /// Default export frame rate
  static const double defaultExportFrameRate = 30;

  // ============================================================
  // Cache & Storage Settings
  // ============================================================

  /// Maximum cache size (GB)
  static const int maxCacheSizeGB = 10;

  /// Temporary file retention period
  static const Duration tempFileRetention = Duration(days: 7);

  /// Artifact file extension
  static const String artifactExtension = 'klens';

  /// Auto-save interval for projects
  static const Duration autoSaveInterval = Duration(minutes: 5);
}

/// Specification for a model tier
class ModelTierSpec {
  const ModelTierSpec({
    required this.name,
    required this.description,
    required this.vramRequirementMB,
    required this.diskRequirementMB,
    required this.realtimeMultiple,
    required this.accuracyPercent,
  });

  /// Display name of the tier
  final String name;

  /// Description of the tier's characteristics
  final String description;

  /// VRAM requirement in megabytes
  final int vramRequirementMB;

  /// Disk space requirement in megabytes
  final int diskRequirementMB;

  /// Processing speed as multiple of realtime (higher = faster)
  final double realtimeMultiple;

  /// Estimated accuracy percentage
  final int accuracyPercent;

  /// Format VRAM requirement for display
  String get vramDisplay {
    if (vramRequirementMB >= 1024) {
      return '${(vramRequirementMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$vramRequirementMB MB';
  }

  /// Format disk requirement for display
  String get diskDisplay {
    if (diskRequirementMB >= 1024) {
      return '${(diskRequirementMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$diskRequirementMB MB';
  }

  /// Format speed for display
  String get speedDisplay => '${realtimeMultiple}x realtime';
}
