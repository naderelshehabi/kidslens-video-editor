import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class HighPerformanceDownloadException implements Exception {
  HighPerformanceDownloadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'HighPerformanceDownloadException: $message';
}

class HighPerformanceDownloadResult {
  const HighPerformanceDownloadResult({
    required this.bytesWritten,
    required this.parallelized,
  });

  final int bytesWritten;
  final bool parallelized;
}

typedef DownloadRequestCustomizer = void Function(http.BaseRequest request);
typedef DownloadProgressCallback = void Function(int bytesDelta);

class HighPerformanceDownloader {
  const HighPerformanceDownloader({
    this.maxParallelRequests = 8,
    this.segmentSizeBytes = 32 * 1024 * 1024,
    this.minParallelFileBytes = 64 * 1024 * 1024,
  });

  static const _maxRedirects = 8;

  final int maxParallelRequests;
  final int segmentSizeBytes;
  final int minParallelFileBytes;

  Future<HighPerformanceDownloadResult> download({
    required http.Client client,
    required Uri uri,
    required File destination,
    int expectedSizeBytes = 0,
    String? expectedSha256,
    DownloadRequestCustomizer? customizeRequest,
    DownloadProgressCallback? onProgress,
  }) async {
    await destination.parent.create(recursive: true);
    final partial = File('${destination.path}.partial');
    await _deleteIfExists(partial);

    final canTryParallel = expectedSizeBytes >= minParallelFileBytes &&
        maxParallelRequests > 1 &&
        segmentSizeBytes > 0;

    try {
      final result = canTryParallel
          ? await _downloadParallelOrFallback(
              client: client,
              uri: uri,
              partial: partial,
              expectedSizeBytes: expectedSizeBytes,
              customizeRequest: customizeRequest,
              onProgress: onProgress,
            )
          : await _downloadSingleStream(
              client: client,
              uri: uri,
              partial: partial,
              expectedSizeBytes: expectedSizeBytes,
              customizeRequest: customizeRequest,
              onProgress: onProgress,
            );

      await _verifyDownloadedFile(
        partial: partial,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
      );
      await _deleteIfExists(destination);
      await partial.rename(destination.path);
      return result;
    } catch (_) {
      await _deleteIfExists(partial);
      rethrow;
    }
  }

  Future<HighPerformanceDownloadResult> _downloadParallelOrFallback({
    required http.Client client,
    required Uri uri,
    required File partial,
    required int expectedSizeBytes,
    required DownloadRequestCustomizer? customizeRequest,
    required DownloadProgressCallback? onProgress,
  }) async {
    final probeResponse = await _sendGet(
      client: client,
      originalUri: uri,
      headers: const {HttpHeaders.rangeHeader: 'bytes=0-0'},
      customizeRequest: customizeRequest,
    );
    if (probeResponse.statusCode == HttpStatus.ok) {
      return _writeSingleStreamResponse(
        response: probeResponse,
        partial: partial,
        expectedSizeBytes: expectedSizeBytes,
        onProgress: onProgress,
      );
    }
    if (probeResponse.statusCode != HttpStatus.partialContent) {
      await probeResponse.stream.drain<void>();
      throw HighPerformanceDownloadException(
        'HTTP ${probeResponse.statusCode} while probing range support',
        statusCode: probeResponse.statusCode,
      );
    }
    await probeResponse.stream.drain<void>();

    final output = await _createPreallocated(partial, expectedSizeBytes);
    final writeLock = _AsyncLock();
    final ranges = _rangesFor(expectedSizeBytes);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        nextIndex += 1;
        if (index >= ranges.length) return;
        final range = ranges[index];
        await _downloadRange(
          client: client,
          uri: uri,
          output: output,
          writeLock: writeLock,
          range: range,
          customizeRequest: customizeRequest,
          onProgress: onProgress,
        );
      }
    }

    final workerCount = ranges.length < maxParallelRequests
        ? ranges.length
        : maxParallelRequests;
    try {
      await Future.wait([for (var i = 0; i < workerCount; i += 1) worker()]);
    } finally {
      await output.close();
    }
    return HighPerformanceDownloadResult(
      bytesWritten: expectedSizeBytes,
      parallelized: true,
    );
  }

  Future<void> _downloadRange({
    required http.Client client,
    required Uri uri,
    required RandomAccessFile output,
    required _AsyncLock writeLock,
    required _ByteRange range,
    required DownloadRequestCustomizer? customizeRequest,
    required DownloadProgressCallback? onProgress,
  }) async {
    final response = await _sendGet(
      client: client,
      originalUri: uri,
      headers: {
        HttpHeaders.rangeHeader: 'bytes=${range.start}-${range.end}',
      },
      customizeRequest: customizeRequest,
    );
    if (response.statusCode != HttpStatus.partialContent) {
      await response.stream.drain<void>();
      throw HighPerformanceDownloadException(
        'HTTP ${response.statusCode} while downloading range '
        '${range.start}-${range.end}',
        statusCode: response.statusCode,
      );
    }

    var position = range.start;
    var written = 0;
    await for (final chunk in response.stream) {
      await writeLock.synchronized(() async {
        await output.setPosition(position);
        await output.writeFrom(chunk);
        position += chunk.length;
        written += chunk.length;
      });
      onProgress?.call(chunk.length);
    }

    if (written != range.length) {
      throw HighPerformanceDownloadException(
        'Range ${range.start}-${range.end} size mismatch: expected '
        '${range.length}, got $written',
      );
    }
  }

  Future<HighPerformanceDownloadResult> _downloadSingleStream({
    required http.Client client,
    required Uri uri,
    required File partial,
    required int expectedSizeBytes,
    required DownloadRequestCustomizer? customizeRequest,
    required DownloadProgressCallback? onProgress,
  }) async {
    final response = await _sendGet(
      client: client,
      originalUri: uri,
      headers: const {},
      customizeRequest: customizeRequest,
    );
    if (response.statusCode != HttpStatus.ok) {
      await response.stream.drain<void>();
      throw HighPerformanceDownloadException(
        'HTTP ${response.statusCode} while downloading file',
        statusCode: response.statusCode,
      );
    }
    return _writeSingleStreamResponse(
      response: response,
      partial: partial,
      expectedSizeBytes: expectedSizeBytes,
      onProgress: onProgress,
    );
  }

  Future<HighPerformanceDownloadResult> _writeSingleStreamResponse({
    required http.StreamedResponse response,
    required File partial,
    required int expectedSizeBytes,
    required DownloadProgressCallback? onProgress,
  }) async {
    final sink = partial.openWrite();
    var written = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        written += chunk.length;
        onProgress?.call(chunk.length);
      }
    } finally {
      await sink.close();
    }
    if (expectedSizeBytes > 0 && written != expectedSizeBytes) {
      throw HighPerformanceDownloadException(
        'Downloaded size mismatch: expected $expectedSizeBytes, got $written',
      );
    }
    return HighPerformanceDownloadResult(
      bytesWritten: written,
      parallelized: false,
    );
  }

  Future<RandomAccessFile> _createPreallocated(File file, int sizeBytes) async {
    final raf = await file.open(mode: FileMode.write);
    if (sizeBytes > 0) {
      await raf.setPosition(sizeBytes - 1);
      await raf.writeByte(0);
    }
    return raf;
  }

  List<_ByteRange> _rangesFor(int sizeBytes) {
    final ranges = <_ByteRange>[];
    var start = 0;
    while (start < sizeBytes) {
      final end = (start + segmentSizeBytes - 1).clamp(0, sizeBytes - 1);
      ranges.add(_ByteRange(start: start, end: end));
      start = end + 1;
    }
    return ranges;
  }

  Future<void> _verifyDownloadedFile({
    required File partial,
    required int expectedSizeBytes,
    required String? expectedSha256,
  }) async {
    if (expectedSizeBytes > 0 && await partial.length() != expectedSizeBytes) {
      throw HighPerformanceDownloadException(
        'Downloaded file size mismatch after write',
      );
    }
    final normalizedSha = expectedSha256?.trim().toLowerCase();
    if (normalizedSha != null && normalizedSha.isNotEmpty) {
      final digest = await sha256.bind(partial.openRead()).first;
      if (digest.toString().toLowerCase() != normalizedSha) {
        throw HighPerformanceDownloadException(
          'Downloaded file checksum mismatch',
        );
      }
    }
  }

  Future<http.StreamedResponse> _sendGet({
    required http.Client client,
    required Uri originalUri,
    required Map<String, String> headers,
    required DownloadRequestCustomizer? customizeRequest,
  }) async {
    var uri = originalUri;
    for (var redirectCount = 0;
        redirectCount <= _maxRedirects;
        redirectCount += 1) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      if (redirectCount == 0 || uri.host == originalUri.host) {
        customizeRequest?.call(request);
      }

      final response = await client.send(request);
      if (!_isRedirect(response.statusCode)) {
        return response;
      }

      final location = response.headers[HttpHeaders.locationHeader] ??
          response.headers['location'];
      await response.stream.drain<void>();
      if (location == null || location.trim().isEmpty) {
        throw HighPerformanceDownloadException(
          'HTTP ${response.statusCode} redirect without Location',
          statusCode: response.statusCode,
        );
      }
      uri = uri.resolve(location);
    }

    throw HighPerformanceDownloadException(
      'Too many redirects while downloading file',
    );
  }

  bool _isRedirect(int statusCode) =>
      statusCode == HttpStatus.movedPermanently ||
      statusCode == HttpStatus.found ||
      statusCode == HttpStatus.seeOther ||
      statusCode == HttpStatus.temporaryRedirect ||
      statusCode == HttpStatus.permanentRedirect;

  Future<void> _deleteIfExists(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

class _ByteRange {
  const _ByteRange({required this.start, required this.end});

  final int start;
  final int end;

  int get length => end - start + 1;
}

class _AsyncLock {
  Future<void> _tail = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.catchError((_) {}).then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }
}
