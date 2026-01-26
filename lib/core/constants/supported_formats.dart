/// Supported media formats
abstract final class SupportedFormats {
  /// Supported video container formats
  static const List<String> videoContainers = [
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'mpg', 'mpeg',
  ];
  
  /// Supported audio formats
  static const List<String> audioFormats = [
    'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', 'wma', 'opus',
  ];
  
  /// Supported video codecs
  static const List<String> videoCodecs = [
    'h264', 'h265', 'hevc', 'vp8', 'vp9', 'av1', 'mpeg4', 'mpeg2',
  ];
  
  /// Supported audio codecs
  static const List<String> audioCodecs = [
    'aac', 'mp3', 'opus', 'vorbis', 'flac', 'pcm', 'ac3', 'eac3',
  ];
  
  /// Check if a file extension is a supported video format
  static bool isVideoFormat(String extension) {
    return videoContainers.contains(extension.toLowerCase());
  }
  
  /// Check if a file extension is a supported audio format
  static bool isAudioFormat(String extension) {
    return audioFormats.contains(extension.toLowerCase());
  }
  
  /// Check if a file extension is a supported media format
  static bool isMediaFormat(String extension) {
    return isVideoFormat(extension) || isAudioFormat(extension);
  }
}
