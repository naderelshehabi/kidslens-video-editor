#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// FFmpeg Binary Downloader for KidsLens Video Editor
///
/// Downloads FFmpeg binaries for the specified platform from trusted sources:
/// - Windows: BtbN/FFmpeg-Builds (GitHub)
/// - macOS: evermeet.cx
/// - Linux: johnvansickle.com
///
/// Usage:
///   dart run scripts/download_ffmpeg.dart [options]
///
/// Options:
///   --platform=<platform>  Target platform (windows-x64, windows-arm64,
///                          macos-universal, linux-x64, linux-arm64)
///   --version=<version>    FFmpeg version (default: latest)
///   --output=<dir>         Output directory (default: native/ffmpeg/binaries)
///   --force                Force re-download even if binaries exist
///   --help                 Show this help message
library download_ffmpeg;

import 'dart:convert';
import 'dart:io';

/// Supported platforms
enum FFmpegPlatform {
  windowsX64('windows-x64'),
  windowsArm64('windows-arm64'),
  macosUniversal('macos-universal'),
  linuxX64('linux-x64'),
  linuxArm64('linux-arm64');

  const FFmpegPlatform(this.name);
  final String name;

  static FFmpegPlatform? fromString(String name) {
    for (final platform in values) {
      if (platform.name == name) return platform;
    }
    return null;
  }

  static FFmpegPlatform detectCurrent() {
    if (Platform.isWindows) {
      // Check for ARM64 Windows
      final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
      if (arch.toLowerCase().contains('arm')) {
        return FFmpegPlatform.windowsArm64;
      }
      return FFmpegPlatform.windowsX64;
    } else if (Platform.isMacOS) {
      return FFmpegPlatform.macosUniversal;
    } else if (Platform.isLinux) {
      // Check for ARM64 Linux
      final result = Process.runSync('uname', ['-m']);
      final arch = result.stdout.toString().trim();
      if (arch == 'aarch64' || arch == 'arm64') {
        return FFmpegPlatform.linuxArm64;
      }
      return FFmpegPlatform.linuxX64;
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}

/// Download progress tracker
class DownloadProgress {
  int bytesReceived = 0;
  int? totalBytes;
  DateTime startTime = DateTime.now();

  void update(int received, int? total) {
    bytesReceived = received;
    totalBytes = total;
    _printProgress();
  }

  void _printProgress() {
    final percent = totalBytes != null
        ? (bytesReceived / totalBytes! * 100).toStringAsFixed(1)
        : '?';
    final receivedMB = (bytesReceived / 1024 / 1024).toStringAsFixed(1);
    final totalMB = totalBytes != null
        ? (totalBytes! / 1024 / 1024).toStringAsFixed(1)
        : '?';

    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final speed = elapsed > 0
        ? (bytesReceived / 1024 / 1024 / elapsed).toStringAsFixed(1)
        : '?';

    stdout.write(
      '\r  Downloading: $receivedMB MB / $totalMB MB ($percent%) - $speed MB/s    ',
    );
  }

  void complete() {
    final elapsed = DateTime.now().difference(startTime);
    final totalMB = (bytesReceived / 1024 / 1024).toStringAsFixed(1);
    print('\n  Downloaded $totalMB MB in ${elapsed.inSeconds}s');
  }
}

/// Main downloader class
class FFmpegDownloader {
  FFmpegDownloader({
    required this.platform,
    required this.outputDir,
    this.force = false,
  });
  final FFmpegPlatform platform;
  final String outputDir;
  final bool force;
  final HttpClient _httpClient = HttpClient();

  /// Get download URL for the platform
  Future<String> _getDownloadUrl() async {
    switch (platform) {
      case FFmpegPlatform.windowsX64:
        return _getWindowsUrl('win64');
      case FFmpegPlatform.windowsArm64:
        return _getWindowsUrl('winarm64');
      case FFmpegPlatform.macosUniversal:
        return _getMacOSUrl();
      case FFmpegPlatform.linuxX64:
        return _getLinuxUrl('amd64');
      case FFmpegPlatform.linuxArm64:
        return _getLinuxUrl('arm64');
    }
  }

  /// Get Windows FFmpeg URL from BtbN/FFmpeg-Builds
  Future<String> _getWindowsUrl(String arch) async {
    // Use GitHub API to get latest release
    final uri = Uri.parse(
      'https://api.github.com/repos/BtbN/FFmpeg-Builds/releases/latest',
    );

    try {
      final request = await _httpClient.getUrl(uri);
      request.headers.add('User-Agent', 'KidsLens-Video-Editor');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final assets = json['assets'] as List<dynamic>;

        // Look for LGPL shared build
        final pattern = RegExp('ffmpeg-.*-$arch-lgpl-shared\\.zip');
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final name = assetMap['name'] as String;
          if (pattern.hasMatch(name)) {
            return assetMap['browser_download_url'] as String;
          }
        }
      }
    } catch (e) {
      print('  Warning: Failed to fetch latest release, using fallback URL');
    }

    // Fallback to a known good version
    return 'https://github.com/BtbN/FFmpeg-Builds/releases/download/'
        'latest/ffmpeg-master-latest-$arch-lgpl-shared.zip';
  }

  /// Get macOS FFmpeg URL from evermeet.cx
  // evermeet.cx provides static builds for macOS
  String _getMacOSUrl() => 'https://evermeet.cx/ffmpeg/getrelease/zip';

  /// Get Linux FFmpeg URL from johnvansickle.com
  String _getLinuxUrl(String arch) =>
      'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$arch-static.tar.xz';

  /// Download file with progress
  Future<File> _downloadFile(String url, String destPath) async {
    print('  URL: $url');

    final uri = Uri.parse(url);
    final request = await _httpClient.getUrl(uri);
    request.headers.add('User-Agent', 'KidsLens-Video-Editor');
    request.followRedirects = true;

    final response = await request.close();

    if (response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers.value('location');
      if (redirectUrl != null) {
        return _downloadFile(redirectUrl, destPath);
      }
    }

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download: HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final file = File(destPath);
    await file.parent.create(recursive: true);

    final progress = DownloadProgress();
    final totalBytes = response.contentLength;
    var receivedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      progress.update(receivedBytes, totalBytes > 0 ? totalBytes : null);
    }
    await sink.close();
    progress.complete();

    return file;
  }

  /// Extract archive based on extension
  Future<void> _extractArchive(File archive, Directory destDir) async {
    final archivePath = archive.path;
    await destDir.create(recursive: true);

    print('  Extracting to: ${destDir.path}');

    if (archivePath.endsWith('.zip')) {
      await _extractZip(archive, destDir);
    } else if (archivePath.endsWith('.tar.xz')) {
      await _extractTarXz(archive, destDir);
    } else if (archivePath.endsWith('.7z')) {
      await _extract7z(archive, destDir);
    } else {
      throw UnsupportedError('Unknown archive format: $archivePath');
    }
  }

  /// Extract ZIP archive
  Future<void> _extractZip(File archive, Directory destDir) async {
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Expand-Archive',
        '-Path',
        archive.path,
        '-DestinationPath',
        destDir.path,
        '-Force',
      ]);
      if (result.exitCode != 0) {
        throw Exception('Failed to extract ZIP: ${result.stderr}');
      }
    } else {
      final result = await Process.run('unzip', [
        '-o',
        archive.path,
        '-d',
        destDir.path,
      ]);
      if (result.exitCode != 0) {
        throw Exception('Failed to extract ZIP: ${result.stderr}');
      }
    }
  }

  /// Extract tar.xz archive
  Future<void> _extractTarXz(File archive, Directory destDir) async {
    final result = await Process.run('tar', [
      '-xJf',
      archive.path,
      '-C',
      destDir.path,
      '--strip-components=1',
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to extract tar.xz: ${result.stderr}');
    }
  }

  /// Extract 7z archive (for macOS ffprobe)
  Future<void> _extract7z(File archive, Directory destDir) async {
    final result = await Process.run('7z', [
      'x',
      archive.path,
      '-o${destDir.path}',
      '-y',
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to extract 7z: ${result.stderr}');
    }
  }

  /// Find and copy FFmpeg binaries to destination
  Future<void> _copyBinaries(Directory extractDir, Directory destDir) async {
    final binaries = platform == FFmpegPlatform.windowsX64 ||
            platform == FFmpegPlatform.windowsArm64
        ? ['ffmpeg.exe', 'ffprobe.exe']
        : ['ffmpeg', 'ffprobe'];

    await destDir.create(recursive: true);

    for (final binary in binaries) {
      File? sourceFile;

      // Search for the binary in extracted directory
      await for (final entity in extractDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(binary)) {
          // Prefer files in bin/ directory
          if (entity.path.contains('bin')) {
            sourceFile = entity;
            break;
          }
          sourceFile ??= entity;
        }
      }

      if (sourceFile == null) {
        print('  Warning: $binary not found in extracted files');
        continue;
      }

      final destFile = File('${destDir.path}/$binary');
      await sourceFile.copy(destFile.path);
      print('  Copied: $binary');

      // Make executable on Unix
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', destFile.path]);
      }
    }

    // Copy DLLs for Windows shared builds
    if (platform == FFmpegPlatform.windowsX64 ||
        platform == FFmpegPlatform.windowsArm64) {
      await for (final entity in extractDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dll')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final destFile = File('${destDir.path}/$fileName');
          if (!destFile.existsSync()) {
            await entity.copy(destFile.path);
          }
        }
      }
      print('  Copied required DLLs');
    }
  }

  /// Download ffprobe separately for macOS
  Future<void> _downloadMacOSFfprobe(Directory destDir) async {
    print('\n  Downloading ffprobe for macOS...');
    const url = 'https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip';

    final tempDir = await Directory.systemTemp.createTemp('ffprobe_');
    try {
      final archiveFile = await _downloadFile(
        url,
        '${tempDir.path}/ffprobe.zip',
      );
      await _extractZip(archiveFile, tempDir);

      // Find and copy ffprobe
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('ffprobe')) {
          final destFile = File('${destDir.path}/ffprobe');
          await entity.copy(destFile.path);
          await Process.run('chmod', ['+x', destFile.path]);
          print('  Copied: ffprobe');
          break;
        }
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  /// Main download method
  Future<void> download() async {
    final platformDir = Directory('$outputDir/${platform.name}');

    // Check if binaries already exist
    final ffmpegBinary = platform == FFmpegPlatform.windowsX64 ||
            platform == FFmpegPlatform.windowsArm64
        ? 'ffmpeg.exe'
        : 'ffmpeg';
    final existingBinary = File('${platformDir.path}/$ffmpegBinary');

    if (existingBinary.existsSync() && !force) {
      print('  FFmpeg binaries already exist at: ${platformDir.path}');
      print('  Use --force to re-download');
      return;
    }

    print('Downloading FFmpeg for ${platform.name}...');

    // Create temp directory for download
    final tempDir = await Directory.systemTemp.createTemp('ffmpeg_download_');
    final archiveExt = platform == FFmpegPlatform.linuxX64 ||
            platform == FFmpegPlatform.linuxArm64
        ? 'tar.xz'
        : 'zip';
    final archivePath = '${tempDir.path}/ffmpeg.$archiveExt';

    try {
      // Download archive
      final url = await _getDownloadUrl();
      final archiveFile = await _downloadFile(url, archivePath);

      // Extract archive
      final extractDir = Directory('${tempDir.path}/extracted');
      await _extractArchive(archiveFile, extractDir);

      // Copy binaries to destination
      await _copyBinaries(extractDir, platformDir);

      // For macOS, download ffprobe separately (evermeet.cx provides them separately)
      if (platform == FFmpegPlatform.macosUniversal) {
        final ffprobeFile = File('${platformDir.path}/ffprobe');
        if (!ffprobeFile.existsSync()) {
          await _downloadMacOSFfprobe(platformDir);
        }
      }

      print('\n✓ FFmpeg binaries installed to: ${platformDir.path}');

      // Verify installation
      await _verifyInstallation(platformDir);
    } finally {
      // Cleanup temp directory
      await tempDir.delete(recursive: true);
    }
  }

  /// Verify FFmpeg installation
  Future<void> _verifyInstallation(Directory dir) async {
    final ffmpegPath = platform == FFmpegPlatform.windowsX64 ||
            platform == FFmpegPlatform.windowsArm64
        ? '${dir.path}/ffmpeg.exe'
        : '${dir.path}/ffmpeg';

    try {
      final result = await Process.run(
        ffmpegPath,
        ['-version'],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final versionMatch = RegExp(r'ffmpeg version (\S+)').firstMatch(output);
        if (versionMatch != null) {
          print('  Verified: FFmpeg ${versionMatch.group(1)}');
        }
      }
    } catch (e) {
      print('  Warning: Could not verify installation: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Parse command line arguments
Map<String, String> parseArgs(List<String> args) {
  final result = <String, String>{};

  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      } else {
        result[parts[0]] = 'true';
      }
    }
  }

  return result;
}

/// Show help message
void showHelp() {
  print('''
FFmpeg Binary Downloader for KidsLens Video Editor

Usage:
  dart run scripts/download_ffmpeg.dart [options]

Options:
  --platform=<platform>  Target platform:
                         - windows-x64 (default on Windows x64)
                         - windows-arm64
                         - macos-universal (default on macOS)
                         - linux-x64 (default on Linux x64)
                         - linux-arm64
  --output=<dir>         Output directory
                         (default: native/ffmpeg/binaries)
  --force                Force re-download even if binaries exist
  --help                 Show this help message

Examples:
  # Download for current platform
  dart run scripts/download_ffmpeg.dart

  # Download for specific platform
  dart run scripts/download_ffmpeg.dart --platform=windows-x64

  # Force re-download
  dart run scripts/download_ffmpeg.dart --force
''');
}

/// Main entry point
Future<void> main(List<String> args) async {
  final parsedArgs = parseArgs(args);

  if (parsedArgs.containsKey('help')) {
    showHelp();
    return;
  }

  // Determine platform
  FFmpegPlatform platform;
  if (parsedArgs.containsKey('platform')) {
    platform = FFmpegPlatform.fromString(parsedArgs['platform']!) ??
        FFmpegPlatform.detectCurrent();
  } else {
    platform = FFmpegPlatform.detectCurrent();
  }

  // Determine output directory
  final scriptDir = File(Platform.script.toFilePath()).parent.parent;
  final outputDir =
      parsedArgs['output'] ?? '${scriptDir.path}/native/ffmpeg/binaries';

  final force = parsedArgs.containsKey('force');

  print('╔════════════════════════════════════════════════════════════╗');
  print('║       FFmpeg Downloader for KidsLens Video Editor          ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');
  print('Platform: ${platform.name}');
  print('Output: $outputDir');
  print('');

  final downloader = FFmpegDownloader(
    platform: platform,
    outputDir: outputDir,
    force: force,
  );

  try {
    await downloader.download();
  } catch (e, stack) {
    print('\n✗ Error: $e');
    if (parsedArgs.containsKey('verbose')) {
      print(stack);
    }
    exit(1);
  } finally {
    downloader.dispose();
  }
}
