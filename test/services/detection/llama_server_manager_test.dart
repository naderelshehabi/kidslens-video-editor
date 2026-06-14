import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/llama_server_manager.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  test('builds llama-server arguments for multimodal VLM runtime', () {
    final args = LlamaServerManager.buildArguments(
      request: const LlamaServerStartRequest(
        runtimeId: LocalRuntimeId.cudaLlamaCpp,
        modelBundleId: 'qwen3_vl_8b_instruct_gguf_q4km',
        modelPath: r'C:\models\qwen.gguf',
        mmprojPath: r'C:\models\mmproj.gguf',
        gpuDeviceIndex: 0,
        contextTokens: 8192,
        gpuLayers: 99,
      ),
      port: 8123,
    );

    expect(
      args,
      containsAllInOrder([
        '--host',
        '127.0.0.1',
        '--port',
        '8123',
        '--model',
        r'C:\models\qwen.gguf',
        '--ctx-size',
        '8192',
        '--n-gpu-layers',
        '99',
        '--mmproj',
        r'C:\models\mmproj.gguf',
      ]),
    );
    expect(args, contains('--no-webui'));
    expect(args, containsAllInOrder(['--device', '0']));
  });

  test(
    'starts a process, polls /health, and stops after idle release',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'kidslens_llama_server_test_',
      );
      final started = <_StartedProcess>[];
      final manager = LlamaServerManager(
        runtimeBinaryManager: _FakeRuntimeBinaryManager(
          'llama-server.exe',
          root: tempDir.path,
        ),
        idleTimeout: const Duration(milliseconds: 20),
        healthPollInterval: const Duration(milliseconds: 5),
        startupTimeout: const Duration(seconds: 2),
        processStarter: (
          executable,
          arguments, {
          workingDirectory,
          environment,
        }) async {
          final port = _argValue(arguments, '--port');
          final server = await _healthyServer(int.parse(port));
          final process = _FakeProcess(onKill: () async => server.close());
          started.add(
            _StartedProcess(
              executable: executable,
              arguments: arguments,
              process: process,
            ),
          );
          return process;
        },
      );

      final handle = await manager.startVlm(_request());

      expect(handle.endpointUri.host, '127.0.0.1');
      expect(handle.pid, started.single.process.pid);
      expect(started.single.arguments, contains('--model'));
      expect(
        File(p.join(tempDir.path, 'llama_server_processes.json')).existsSync(),
        isTrue,
      );

      await handle.release();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(started.single.process.wasKilled, isTrue);
      expect(
        File(p.join(tempDir.path, 'llama_server_processes.json')).existsSync(),
        isFalse,
      );
      await manager.dispose();
      await tempDir.delete(recursive: true);
    },
  );

  test('reuses an active server for the same model and GPU slot', () async {
    var starts = 0;
    late HttpServer server;
    final manager = LlamaServerManager(
      runtimeBinaryManager: _FakeRuntimeBinaryManager('llama-server.exe'),
      idleTimeout: const Duration(seconds: 5),
      healthPollInterval: const Duration(milliseconds: 5),
      startupTimeout: const Duration(seconds: 2),
      processStarter: (_, arguments, {workingDirectory, environment}) async {
        starts += 1;
        server =
            await _healthyServer(int.parse(_argValue(arguments, '--port')));
        return _FakeProcess(onKill: () async => server.close());
      },
    );

    final first = await manager.startVlm(_request());
    final second = await manager.startVlm(_request());

    expect(starts, 1);
    expect(second.endpointUri, first.endpointUri);

    await first.release();
    await second.release();
    await manager.dispose();
  });

  test('replaces an existing server when another model uses the same GPU slot',
      () async {
    final processes = <_FakeProcess>[];
    final servers = <HttpServer>[];
    final manager = LlamaServerManager(
      runtimeBinaryManager: _FakeRuntimeBinaryManager('llama-server.exe'),
      healthPollInterval: const Duration(milliseconds: 5),
      startupTimeout: const Duration(seconds: 2),
      processStarter: (_, arguments, {workingDirectory, environment}) async {
        final server =
            await _healthyServer(int.parse(_argValue(arguments, '--port')));
        servers.add(server);
        final process = _FakeProcess(onKill: () async => server.close());
        processes.add(process);
        return process;
      },
    );

    final first = await manager.startVlm(_request(modelBundleId: 'model_a'));
    final second = await manager.startVlm(_request(modelBundleId: 'model_b'));

    expect(processes.first.wasKilled, isTrue);
    expect(second.endpointUri, isNot(first.endpointUri));

    await second.release();
    await manager.dispose();
    for (final server in servers) {
      await server.close(force: true);
    }
  });

  test('reports startup diagnostics when process exits before health',
      () async {
    final manager = LlamaServerManager(
      runtimeBinaryManager: _FakeRuntimeBinaryManager('llama-server.exe'),
      healthPollInterval: const Duration(milliseconds: 5),
      startupTimeout: const Duration(milliseconds: 100),
      startupPortAttempts: 1,
      processStarter: (_, __, {workingDirectory, environment}) async {
        final process = _FakeProcess();
        process.stderrController.add(utf8.encode('CUDA out of memory'));
        process.completeExit(42);
        return process;
      },
    );

    await expectLater(
      manager.startVlm(_request()),
      throwsA(
        isA<LlamaServerException>().having(
          (error) => error.message,
          'message',
          contains('CUDA out of memory'),
        ),
      ),
    );
  });

  test('cleanupStaleChildren kills recorded KidsLens llama-server pids',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'kidslens_llama_server_ledger_test_',
    );
    final ledger = File(p.join(tempDir.path, 'llama_server_processes.json'));
    await ledger.writeAsString(
      jsonEncode([
        {'pid': 111, 'modelBundleId': 'old_a'},
        {'pid': 222, 'modelBundleId': 'old_b'},
        {'pid': 'bad', 'modelBundleId': 'ignored'},
      ]),
    );
    final killed = <int>[];
    final manager = LlamaServerManager(
      runtimeBinaryManager: _FakeRuntimeBinaryManager(
        'llama-server.exe',
        root: tempDir.path,
      ),
      processKiller: (pid) {
        killed.add(pid);
        return true;
      },
    );

    await manager.cleanupStaleChildren();

    expect(killed, [111, 222]);
    expect(ledger.existsSync(), isFalse);
    await tempDir.delete(recursive: true);
  });
}

LlamaServerStartRequest _request({String modelBundleId = 'qwen'}) =>
    LlamaServerStartRequest(
      runtimeId: LocalRuntimeId.cudaLlamaCpp,
      modelBundleId: modelBundleId,
      modelPath: 'model.gguf',
      mmprojPath: 'mmproj.gguf',
      gpuDeviceIndex: 0,
    );

String _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index < 0 || index == args.length - 1) {
    throw StateError('Missing $flag in $args');
  }
  return args[index + 1];
}

Future<HttpServer> _healthyServer(int port) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  unawaited(
    server.listen((request) {
      if (request.uri.path == '/health') {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('OK');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      unawaited(request.response.close());
    }).asFuture<void>(),
  );
  return server;
}

class _StartedProcess {
  const _StartedProcess({
    required this.executable,
    required this.arguments,
    required this.process,
  });

  final String executable;
  final List<String> arguments;
  final _FakeProcess process;
}

class _FakeRuntimeBinaryManager extends RuntimeBinaryManager {
  _FakeRuntimeBinaryManager(this.path, {this.root = '.'})
      : super(customRuntimeRoot: root);

  final String path;
  final String root;

  @override
  Future<String> executablePath(LocalRuntimeId runtimeId) async => path;

  @override
  Future<String> get runtimeRoot async => root;
}

class _FakeProcess implements LlamaManagedProcess {
  _FakeProcess({this.onKill}) : pid = _nextPid++;

  static int _nextPid = 1000;

  final Future<void> Function()? onKill;
  final stdoutController = StreamController<List<int>>();
  final stderrController = StreamController<List<int>>();
  final _exit = Completer<int>();
  bool wasKilled = false;

  @override
  final int pid;

  @override
  Stream<List<int>> get stdout => stdoutController.stream;

  @override
  Stream<List<int>> get stderr => stderrController.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    wasKilled = true;
    unawaited(onKill?.call());
    completeExit(-1);
    unawaited(stdoutController.close());
    unawaited(stderrController.close());
    return true;
  }

  void completeExit(int code) {
    if (!_exit.isCompleted) {
      _exit.complete(code);
    }
  }
}
