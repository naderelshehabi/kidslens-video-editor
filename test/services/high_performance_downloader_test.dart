import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/services/high_performance_downloader.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kidslens_hpdl_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('downloads large files with parallel range requests', () async {
    final bytes = List<int>.generate(17, (index) => index + 1);
    final ranges = <String>[];
    final client = _FakeHttpClient((request) {
      final range = request.headers[HttpHeaders.rangeHeader];
      if (range != null) {
        ranges.add(range);
        final parsed = _parseRange(range);
        return http.Response.bytes(
          bytes.sublist(parsed.start, parsed.end + 1),
          HttpStatus.partialContent,
          headers: {
            HttpHeaders.contentRangeHeader:
                'bytes ${parsed.start}-${parsed.end}/${bytes.length}',
          },
        );
      }
      return http.Response.bytes(bytes, HttpStatus.ok);
    });
    final destination = File(p.join(tempDir.path, 'model.gguf'));
    var progressBytes = 0;

    final result = await const HighPerformanceDownloader(
      maxParallelRequests: 3,
      segmentSizeBytes: 4,
      minParallelFileBytes: 1,
    ).download(
      client: client,
      uri: Uri.parse('https://example.test/model.gguf'),
      destination: destination,
      expectedSizeBytes: bytes.length,
      expectedSha256: sha256.convert(bytes).toString(),
      onProgress: (delta) => progressBytes += delta,
    );

    expect(result.parallelized, isTrue);
    expect(progressBytes, bytes.length);
    expect(await destination.readAsBytes(), bytes);
    expect(ranges.first, 'bytes=0-0');
    expect(
      ranges.skip(1),
      containsAll(['bytes=0-3', 'bytes=4-7', 'bytes=8-11', 'bytes=12-15']),
    );
    expect(ranges.skip(1), contains('bytes=16-16'));
  });

  test('falls back to single stream when server ignores range requests',
      () async {
    final bytes = List<int>.generate(11, (index) => 100 + index);
    final requests = <String?>[];
    final client = _FakeHttpClient((request) {
      requests.add(request.headers[HttpHeaders.rangeHeader]);
      return http.Response.bytes(bytes, HttpStatus.ok);
    });
    final destination = File(p.join(tempDir.path, 'fallback.gguf'));
    var progressBytes = 0;

    final result = await const HighPerformanceDownloader(
      maxParallelRequests: 4,
      segmentSizeBytes: 3,
      minParallelFileBytes: 1,
    ).download(
      client: client,
      uri: Uri.parse('https://example.test/fallback.gguf'),
      destination: destination,
      expectedSizeBytes: bytes.length,
      onProgress: (delta) => progressBytes += delta,
    );

    expect(result.parallelized, isFalse);
    expect(progressBytes, bytes.length);
    expect(await destination.readAsBytes(), bytes);
    expect(requests, ['bytes=0-0']);
  });

  test('downloads ranges correctly from a real HttpServer', () async {
    final bytes = List<int>.generate(13, (index) => index + 20);
    final ranges = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));
    server.listen((request) async {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range == null) {
        request.response.add(bytes);
        await request.response.close();
        return;
      }
      ranges.add(range);
      final parsed = _parseRange(range);
      final slice = bytes.sublist(parsed.start, parsed.end + 1);
      request.response.statusCode = HttpStatus.partialContent;
      request.response.contentLength = slice.length;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes ${parsed.start}-${parsed.end}/${bytes.length}',
      );
      request.response.add(slice);
      await request.response.close();
    });
    final destination = File(p.join(tempDir.path, 'server.gguf'));

    final result = await const HighPerformanceDownloader(
      maxParallelRequests: 3,
      segmentSizeBytes: 4,
      minParallelFileBytes: 1,
    ).download(
      client: http.Client(),
      uri: Uri.parse('http://127.0.0.1:${server.port}/server.gguf'),
      destination: destination,
      expectedSizeBytes: bytes.length,
      expectedSha256: sha256.convert(bytes).toString(),
    );

    expect(result.parallelized, isTrue);
    expect(await destination.readAsBytes(), bytes);
    expect(ranges.first, 'bytes=0-0');
  });

  test('downloads multiple ranged files sequentially with one client', () async {
    const firstBytes = <int>[1, 2, 3, 4];
    const secondBytes = <int>[5, 6, 7];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));
    server.listen((request) async {
      final bytes = switch (request.uri.path) {
        '/first.gguf' => firstBytes,
        '/second.gguf' => secondBytes,
        _ => const <int>[],
      };
      if (bytes.isEmpty) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range == null) {
        request.response.add(bytes);
        await request.response.close();
        return;
      }
      final parsed = _parseRange(range);
      final slice = bytes.sublist(parsed.start, parsed.end + 1);
      request.response.statusCode = HttpStatus.partialContent;
      request.response.contentLength = slice.length;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes ${parsed.start}-${parsed.end}/${bytes.length}',
      );
      request.response.add(slice);
      await request.response.close();
    });

    final client = http.Client();
    addTearDown(client.close);
    const downloader = HighPerformanceDownloader(
      maxParallelRequests: 2,
      segmentSizeBytes: 2,
      minParallelFileBytes: 1,
    );
    final firstDestination = File(p.join(tempDir.path, 'first.gguf'));
    final secondDestination = File(p.join(tempDir.path, 'second.gguf'));

    await downloader.download(
      client: client,
      uri: Uri.parse('http://127.0.0.1:${server.port}/first.gguf'),
      destination: firstDestination,
      expectedSizeBytes: firstBytes.length,
      expectedSha256: sha256.convert(firstBytes).toString(),
    );
    await downloader.download(
      client: client,
      uri: Uri.parse('http://127.0.0.1:${server.port}/second.gguf'),
      destination: secondDestination,
      expectedSizeBytes: secondBytes.length,
      expectedSha256: sha256.convert(secondBytes).toString(),
    );

    expect(await firstDestination.readAsBytes(), firstBytes);
    expect(await secondDestination.readAsBytes(), secondBytes);
  });
}

_Range _parseRange(String value) {
  final match = RegExp(r'^bytes=(\d+)-(\d+)$').firstMatch(value);
  if (match == null) {
    throw StateError('Invalid range header: $value');
  }
  return _Range(
    start: int.parse(match.group(1)!),
    end: int.parse(match.group(2)!),
  );
}

class _Range {
  const _Range({required this.start, required this.end});

  final int start;
  final int end;
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.handler);

  final FutureOr<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
