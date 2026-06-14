import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:path/path.dart' as p;

class LlamaServerException implements Exception {
  LlamaServerException(this.message);

  final String message;

  @override
  String toString() => 'LlamaServerException: $message';
}

class LlamaServerStartRequest {
  const LlamaServerStartRequest({
    required this.runtimeId,
    required this.modelBundleId,
    required this.modelPath,
    this.mmprojPath,
    this.gpuDeviceIndex,
    this.contextTokens = 16384,
    this.gpuLayers = 999,
    this.embedding = false,
    this.extraArgs = const <String>[],
  });

  final LocalRuntimeId runtimeId;
  final String modelBundleId;
  final String modelPath;
  final String? mmprojPath;
  final int? gpuDeviceIndex;
  final int contextTokens;
  final int gpuLayers;
  final bool embedding;
  final List<String> extraArgs;

  String get slotKey =>
      '${runtimeId.jsonValue}:${gpuDeviceIndex == null ? 'gpu:auto' : 'gpu:$gpuDeviceIndex'}';

  String get serverKey => [
        slotKey,
        modelBundleId,
        p.normalize(modelPath),
        if (mmprojPath != null) p.normalize(mmprojPath!),
        if (embedding) 'embedding',
      ].join('|');
}

class LlamaServerHandle {
  LlamaServerHandle._({
    required this.endpointUri,
    required this.runtimeId,
    required this.modelBundleId,
    required this.pid,
    required this.diagnostics,
    required Future<void> Function() release,
  }) : _release = release;

  final Uri endpointUri;
  final LocalRuntimeId runtimeId;
  final String modelBundleId;
  final int pid;
  final LlamaServerDiagnostics diagnostics;
  final Future<void> Function() _release;

  Future<void> release() => _release();
}

class LlamaServerDiagnostics {
  LlamaServerDiagnostics({int maxEntries = 80}) : _maxEntries = maxEntries;

  final int _maxEntries;
  final _entries = <String>[];

  List<String> get entries => List.unmodifiable(_entries);

  String get text => _entries.join('\n');

  void add(String streamName, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    for (final line in const LineSplitter().convert(trimmed)) {
      _entries.add('[$streamName] $line');
      while (_entries.length > _maxEntries) {
        _entries.removeAt(0);
      }
    }
  }
}

abstract class LlamaManagedProcess {
  int get pid;
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

class DartLlamaManagedProcess implements LlamaManagedProcess {
  DartLlamaManagedProcess(this._process);

  final Process _process;

  @override
  int get pid => _process.pid;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      _process.kill(signal);
}

typedef LlamaProcessStarter = Future<LlamaManagedProcess> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
});

typedef LlamaProcessKiller = bool Function(int pid);

class LlamaServerManager {
  LlamaServerManager({
    required RuntimeBinaryManager runtimeBinaryManager,
    http.Client Function()? httpClientFactory,
    LlamaProcessStarter? processStarter,
    LlamaProcessKiller? processKiller,
    Duration startupTimeout = const Duration(seconds: 45),
    Duration healthPollInterval = const Duration(milliseconds: 250),
    Duration idleTimeout = const Duration(minutes: 10),
    int startupPortAttempts = 3,
  })  : _runtimeBinaryManager = runtimeBinaryManager,
        _httpClientFactory = httpClientFactory ?? http.Client.new,
        _processStarter = processStarter ?? _startDartProcess,
        _processKiller = processKiller ?? Process.killPid,
        _startupTimeout = startupTimeout,
        _healthPollInterval = healthPollInterval,
        _idleTimeout = idleTimeout,
        _startupPortAttempts = startupPortAttempts;

  final RuntimeBinaryManager _runtimeBinaryManager;
  final http.Client Function() _httpClientFactory;
  final LlamaProcessStarter _processStarter;
  final LlamaProcessKiller _processKiller;
  final Duration _startupTimeout;
  final Duration _healthPollInterval;
  final Duration _idleTimeout;
  final int _startupPortAttempts;
  final _activeByKey = <String, _ActiveLlamaServer>{};
  final _activeBySlot = <String, _ActiveLlamaServer>{};
  static const _processLedgerFileName = 'llama_server_processes.json';

  static List<String> buildArguments({
    required LlamaServerStartRequest request,
    required int port,
  }) {
    final args = <String>[
      '--host',
      '127.0.0.1',
      '--port',
      '$port',
      '--model',
      request.modelPath,
      '--ctx-size',
      '${request.contextTokens}',
      '--n-gpu-layers',
      '${request.gpuLayers}',
      '--no-webui',
      if (request.mmprojPath != null) ...[
        '--mmproj',
        request.mmprojPath!,
      ],
      if (request.embedding) ...[
        '--embedding',
        '--pooling',
        'last',
      ],
      ...request.extraArgs,
    ];

    if (request.gpuDeviceIndex != null) {
      args.addAll(['--device', '${request.gpuDeviceIndex}']);
    }
    return args;
  }

  Future<LlamaServerHandle> startVlm(
    LlamaServerStartRequest request,
  ) =>
      _start(request);

  Future<LlamaServerHandle> startEmbedding(
    LlamaServerStartRequest request,
  ) =>
      _start(
        LlamaServerStartRequest(
          runtimeId: request.runtimeId,
          modelBundleId: request.modelBundleId,
          modelPath: request.modelPath,
          mmprojPath: request.mmprojPath,
          gpuDeviceIndex: request.gpuDeviceIndex,
          contextTokens: request.contextTokens,
          gpuLayers: request.gpuLayers,
          embedding: true,
          extraArgs: request.extraArgs,
        ),
      );

  Future<void> stopAll() async {
    final active = _activeByKey.values.toSet().toList(growable: false);
    _activeByKey.clear();
    _activeBySlot.clear();
    await Future.wait(active.map(_stopServer));
  }

  Future<void> dispose() => stopAll();

  Future<void> cleanupStaleChildren() async {
    final ledger = await _processLedgerFile();
    if (!ledger.existsSync()) {
      return;
    }

    final records = await _readProcessLedger();
    for (final record in records) {
      final pid = record['pid'];
      if (pid is! int) {
        continue;
      }
      _processKiller(pid);
    }
    await ledger.delete();
  }

  Future<LlamaServerHandle> _start(LlamaServerStartRequest request) async {
    if (request.runtimeId != LocalRuntimeId.cudaLlamaCpp &&
        request.runtimeId != LocalRuntimeId.vulkanLlamaCpp) {
      throw LlamaServerException(
        'Unsupported llama.cpp runtime: ${request.runtimeId.jsonValue}',
      );
    }

    final existing = _activeByKey[request.serverKey];
    if (existing != null) {
      existing.retain();
      return _handleFor(existing);
    }

    final existingSlot = _activeBySlot[request.slotKey];
    if (existingSlot != null) {
      await _stopAndRemove(existingSlot);
    }

    final executable = await _runtimeBinaryManager.executablePath(
      request.runtimeId,
    );
    Object? lastError;
    for (var attempt = 0; attempt < _startupPortAttempts; attempt++) {
      final port = await _findAvailablePort();
      final endpoint = Uri.parse('http://127.0.0.1:$port');
      final diagnostics = LlamaServerDiagnostics();
      LlamaManagedProcess? process;
      try {
        process = await _processStarter(
          executable,
          buildArguments(request: request, port: port),
          workingDirectory: p.dirname(executable),
        );
        _attachDiagnostics(process, diagnostics);
        final active = _ActiveLlamaServer(
          request: request,
          endpointUri: endpoint,
          process: process,
          diagnostics: diagnostics,
        );
        await _waitForHealthy(active);
        _activeByKey[request.serverKey] = active;
        _activeBySlot[request.slotKey] = active;
        await _recordProcessStart(active);
        return _handleFor(active);
      } catch (error) {
        lastError = error;
        process?.kill();
        if (attempt == _startupPortAttempts - 1) {
          break;
        }
      }
    }

    throw LlamaServerException(
      'Failed to start llama-server for ${request.modelBundleId}: $lastError',
    );
  }

  LlamaServerHandle _handleFor(_ActiveLlamaServer active) =>
      LlamaServerHandle._(
        endpointUri: active.endpointUri,
        runtimeId: active.request.runtimeId,
        modelBundleId: active.request.modelBundleId,
        pid: active.process.pid,
        diagnostics: active.diagnostics,
        release: () => _release(active),
      );

  Future<void> _release(_ActiveLlamaServer active) async {
    active.release();
    if (active.refCount > 0) {
      return;
    }
    active.idleTimer?.cancel();
    active.idleTimer = Timer(_idleTimeout, () {
      unawaited(_stopAndRemove(active));
    });
  }

  Future<void> _stopAndRemove(_ActiveLlamaServer active) async {
    _activeByKey.remove(active.request.serverKey);
    _activeBySlot.remove(active.request.slotKey);
    await _stopServer(active);
  }

  Future<void> _stopServer(_ActiveLlamaServer active) async {
    active.idleTimer?.cancel();
    active.process.kill();
    try {
      await active.process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      active.process.kill(ProcessSignal.sigkill);
    }
    await _removeProcessRecord(active.process.pid);
  }

  Future<void> _waitForHealthy(_ActiveLlamaServer active) async {
    final deadline = DateTime.now().add(_startupTimeout);
    final client = _httpClientFactory();
    try {
      while (DateTime.now().isBefore(deadline)) {
        final exited = await _hasExited(active.process);
        if (exited != null) {
          throw LlamaServerException(
            'llama-server exited during startup with code $exited. ${active.diagnostics.text}',
          );
        }

        try {
          final healthUri = active.endpointUri.replace(path: '/health');
          final response = await client.get(healthUri);
          if (response.statusCode == HttpStatus.ok) {
            return;
          }
        } catch (_) {
          // Server is still starting or the chosen port is not accepting yet.
        }
        await Future<void>.delayed(_healthPollInterval);
      }
      throw LlamaServerException(
        'Timed out waiting for llama-server /health. ${active.diagnostics.text}',
      );
    } finally {
      client.close();
    }
  }

  Future<int?> _hasExited(LlamaManagedProcess process) async {
    final sentinel = Object();
    final result = await Future.any<Object?>([
      process.exitCode,
      Future<Object?>.delayed(Duration.zero, () => sentinel),
    ]);
    return identical(result, sentinel) ? null : result as int?;
  }

  Future<int> _findAvailablePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  void _attachDiagnostics(
    LlamaManagedProcess process,
    LlamaServerDiagnostics diagnostics,
  ) {
    process.stdout
        .transform(utf8.decoder)
        .listen((chunk) => diagnostics.add('stdout', chunk));
    process.stderr
        .transform(utf8.decoder)
        .listen((chunk) => diagnostics.add('stderr', chunk));
  }

  Future<File> _processLedgerFile() async {
    final root = await _runtimeBinaryManager.runtimeRoot;
    return File(p.join(root, _processLedgerFileName));
  }

  Future<List<Map<String, dynamic>>> _readProcessLedger() async {
    final file = await _processLedgerFile();
    if (!file.existsSync()) {
      return <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  Future<void> _writeProcessLedger(
    List<Map<String, dynamic>> records,
  ) async {
    final file = await _processLedgerFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(records));
  }

  Future<void> _recordProcessStart(_ActiveLlamaServer active) async {
    final records = (await _readProcessLedger())
      ..removeWhere((record) => record['pid'] == active.process.pid)
      ..add({
        'pid': active.process.pid,
        'runtimeId': active.request.runtimeId.jsonValue,
        'modelBundleId': active.request.modelBundleId,
        'endpointUri': active.endpointUri.toString(),
        'startedAt': DateTime.now().toIso8601String(),
      });
    await _writeProcessLedger(records);
  }

  Future<void> _removeProcessRecord(int pid) async {
    final records = await _readProcessLedger();
    records.removeWhere((record) => record['pid'] == pid);
    if (records.isEmpty) {
      final file = await _processLedgerFile();
      if (file.existsSync()) {
        await file.delete();
      }
      return;
    }
    await _writeProcessLedger(records);
  }

  static Future<LlamaManagedProcess> _startDartProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    return DartLlamaManagedProcess(process);
  }
}

class _ActiveLlamaServer {
  _ActiveLlamaServer({
    required this.request,
    required this.endpointUri,
    required this.process,
    required this.diagnostics,
  });

  final LlamaServerStartRequest request;
  final Uri endpointUri;
  final LlamaManagedProcess process;
  final LlamaServerDiagnostics diagnostics;
  int refCount = 1;
  Timer? idleTimer;

  void retain() {
    idleTimer?.cancel();
    idleTimer = null;
    refCount += 1;
  }

  void release() {
    if (refCount > 0) {
      refCount -= 1;
    }
  }
}
