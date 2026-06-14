import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _SmokeOptions.parse(args);
  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }

  final missing = options.missingInputs();
  if (missing.isNotEmpty) {
    final message =
        'SKIPPED: missing required llama.cpp/Qwen3-VL smoke inputs: ${missing.join(', ')}';
    if (options.requireArtifacts) {
      stderr.writeln(message);
      exitCode = 2;
    } else {
      stdout.writeln(message);
    }
    return;
  }

  final port = options.port ?? await _findFreeLoopbackPort();
  final process = await Process.start(
    options.serverExe!,
    <String>[
      '-m',
      options.modelPath!,
      '--mmproj',
      options.mmprojPath!,
      '--host',
      '127.0.0.1',
      '--port',
      '$port',
      '-ngl',
      '${options.gpuLayers}',
      '--ctx-size',
      '${options.contextSize}',
      '--parallel',
      '1',
      '--jinja',
      '--no-webui',
    ],
  );
  final logs = _RingBuffer(limit: 80);
  final stdoutSub = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => logs.add('stdout: $line'));
  final stderrSub = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => logs.add('stderr: $line'));

  try {
    final healthMs = await _waitForHealth(
      port: port,
      timeout: options.startupTimeout,
    );
    final response = await _sendSmokeRequest(
      port: port,
      imagePaths: options.imagePaths,
      timeout: options.requestTimeout,
    );
    stdout.writeln(
      jsonEncode(
        <String, Object?>{
          'status': 'passed',
          'port': port,
          'healthMs': healthMs,
          'imageCount': options.imagePaths.length,
          'responsePreview': response.length > 500
              ? '${response.substring(0, 500)}...'
              : response,
        },
      ),
    );
  } catch (error) {
    stderr.writeln(
      jsonEncode(
        <String, Object?>{
          'status': 'failed',
          'error': '$error',
          'recentServerLogs': logs.lines,
        },
      ),
    );
    exitCode = 1;
  } finally {
    process.kill();
    await stdoutSub.cancel();
    await stderrSub.cancel();
  }
}

Future<int> _findFreeLoopbackPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<int> _waitForHealth({
  required int port,
  required Duration timeout,
}) async {
  final client = HttpClient();
  final started = DateTime.now();
  try {
    while (DateTime.now().difference(started) < timeout) {
      try {
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:$port/health'),
        );
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode == HttpStatus.ok) {
          return DateTime.now().difference(started).inMilliseconds;
        }
      } catch (_) {
        // Server is still starting.
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  } finally {
    client.close(force: true);
  }
  throw TimeoutException('llama-server /health did not become ready', timeout);
}

Future<String> _sendSmokeRequest({
  required int port,
  required List<String> imagePaths,
  required Duration timeout,
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final content = <Map<String, Object?>>[
      <String, Object?>{
        'type': 'text',
        'text':
            'Return only JSON: {"caption": string, "findings": []}. Describe whether the frames contain unsafe family content.',
      },
    ];
    for (var i = 0; i < imagePaths.length; i += 1) {
      final bytes = await File(imagePaths[i]).readAsBytes();
      content
        ..add(
          <String, Object?>{
            'type': 'text',
            'text': 'frame ${i + 1}/${imagePaths.length}',
          },
        )
        ..add(
          <String, Object?>{
            'type': 'image_url',
            'image_url': <String, Object?>{
              'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
            },
          },
        );
    }

    final request = await client
        .postUrl(Uri.parse('http://127.0.0.1:$port/v1/chat/completions'))
        .timeout(timeout);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode(
        <String, Object?>{
          'model': 'qwen3-vl-smoke',
          'messages': <Map<String, Object?>>[
            <String, Object?>{
              'role': 'system',
              'content':
                  'You are a local family-safety video analysis smoke test.',
            },
            <String, Object?>{
              'role': 'user',
              'content': content,
            },
          ],
          'max_tokens': 256,
          'temperature': 0.1,
          'response_format': <String, Object?>{'type': 'json_object'},
        },
      ),
    );
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'chat completion failed with HTTP ${response.statusCode}: $body',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('chat completion response is not JSON');
    }
    return body;
  } finally {
    client.close(force: true);
  }
}

class _SmokeOptions {
  const _SmokeOptions({
    required this.serverExe,
    required this.modelPath,
    required this.mmprojPath,
    required this.imagePaths,
    required this.port,
    required this.contextSize,
    required this.gpuLayers,
    required this.startupTimeout,
    required this.requestTimeout,
    required this.requireArtifacts,
    required this.showHelp,
  });

  factory _SmokeOptions.parse(List<String> args) {
    String? serverExe;
    String? modelPath;
    String? mmprojPath;
    final imagePaths = <String>[];
    int? port;
    var contextSize = 8192;
    var gpuLayers = 99;
    var startupTimeout = const Duration(seconds: 120);
    var requestTimeout = const Duration(seconds: 90);
    var requireArtifacts = false;
    var showHelp = false;

    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      String readValue() {
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for $arg');
        }
        i += 1;
        return args[i];
      }

      switch (arg) {
        case '--server-exe':
          serverExe = readValue();
        case '--model':
          modelPath = readValue();
        case '--mmproj':
          mmprojPath = readValue();
        case '--image':
          imagePaths.add(readValue());
        case '--port':
          port = int.parse(readValue());
        case '--ctx-size':
          contextSize = int.parse(readValue());
        case '--gpu-layers':
          gpuLayers = int.parse(readValue());
        case '--startup-timeout-seconds':
          startupTimeout = Duration(seconds: int.parse(readValue()));
        case '--request-timeout-seconds':
          requestTimeout = Duration(seconds: int.parse(readValue()));
        case '--require-artifacts':
          requireArtifacts = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          throw ArgumentError('Unknown argument: $arg');
      }
    }

    return _SmokeOptions(
      serverExe: serverExe,
      modelPath: modelPath,
      mmprojPath: mmprojPath,
      imagePaths: imagePaths,
      port: port,
      contextSize: contextSize,
      gpuLayers: gpuLayers,
      startupTimeout: startupTimeout,
      requestTimeout: requestTimeout,
      requireArtifacts: requireArtifacts,
      showHelp: showHelp,
    );
  }

  final String? serverExe;
  final String? modelPath;
  final String? mmprojPath;
  final List<String> imagePaths;
  final int? port;
  final int contextSize;
  final int gpuLayers;
  final Duration startupTimeout;
  final Duration requestTimeout;
  final bool requireArtifacts;
  final bool showHelp;

  List<String> missingInputs() {
    final missing = <String>[];
    if (serverExe == null || !File(serverExe!).existsSync()) {
      missing.add('--server-exe');
    }
    if (modelPath == null || !File(modelPath!).existsSync()) {
      missing.add('--model');
    }
    if (mmprojPath == null || !File(mmprojPath!).existsSync()) {
      missing.add('--mmproj');
    }
    if (imagePaths.isEmpty) {
      missing.add('--image');
    }
    for (final imagePath in imagePaths) {
      if (!File(imagePath).existsSync()) {
        missing.add('--image=$imagePath');
      }
    }
    return missing;
  }
}

class _RingBuffer {
  _RingBuffer({required this.limit});

  final int limit;
  final List<String> _lines = <String>[];

  List<String> get lines => List<String>.unmodifiable(_lines);

  void add(String line) {
    _lines.add(line);
    if (_lines.length > limit) {
      _lines.removeAt(0);
    }
  }
}

const _usage = '''
Run the VSS Phase 0.5 llama.cpp + Qwen3-VL smoke spike.

This script is intentionally manual: it verifies the exact pinned runtime and
model artifacts before the production RuntimeBinaryManager is implemented.

Required when artifacts are present:
  dart run scripts/vss_llamacpp_smoke_spike.dart ^
    --server-exe C:\\path\\to\\llama-server.exe ^
    --model C:\\models\\Qwen3VL-8B-Instruct-Q4_K_M.gguf ^
    --mmproj C:\\models\\mmproj-Qwen3VL-8B-Instruct-F16.gguf ^
    --image C:\\frames\\frame1.jpg ^
    --image C:\\frames\\frame2.jpg

Useful options:
  --require-artifacts            Exit non-zero instead of SKIPPED when inputs are absent.
  --ctx-size 8192                Context size for the smoke run.
  --gpu-layers 99                llama.cpp GPU layer count.
  --port 43187                   Fixed loopback port. Defaults to a free port.
  --startup-timeout-seconds 120  Time to wait for /health.
  --request-timeout-seconds 90   Time to wait for chat completion.

Expected pass signal:
  {"status":"passed","port":...,"healthMs":...,"imageCount":...}

Failure signals:
  - /health timeout
  - non-200 /v1/chat/completions response
  - non-JSON OpenAI-compatible response envelope
''';
