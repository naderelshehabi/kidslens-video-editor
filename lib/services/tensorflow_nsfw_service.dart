import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class TensorflowNsfwService {
  const TensorflowNsfwService();

  Future<List<Map<String, double>>> runBatchInference({
    required String modelDir,
    required List<List<int>> rgbDataBatch,
    required int width,
    required int height,
  }) async {
    if (rgbDataBatch.isEmpty) return const <Map<String, double>>[];

    final node = await _resolveNodeExec();
    final runtimeDir = _resolveRuntimeDir();
    final scriptPath = p.join(runtimeDir.path, 'nsfw_inference.js');
    if (!File(scriptPath).existsSync()) {
      throw TensorflowNsfwException(
        'TensorFlow inference script not found: $scriptPath',
      );
    }
    await _ensureNodeModules(node, runtimeDir);

    final frames = rgbDataBatch
        .map(
          (rgb) => <String, dynamic>{
            'width': width,
            'height': height,
            'rgb': base64Encode(rgb),
          },
        )
        .toList(growable: false);
    final requestPayload = jsonEncode(<String, dynamic>{
      'modelDir': modelDir.replaceAll('\\', '/'),
      'frames': frames,
    });

    final process = await Process.start(
      node.command,
      <String>[
        ...node.args,
        scriptPath,
      ],
      runInShell: Platform.isWindows,
      workingDirectory: runtimeDir.path,
      environment: Map<String, String>.from(Platform.environment)
        ..putIfAbsent('TF_CPP_MIN_LOG_LEVEL', () => '2'),
    );

    process.stdin.write(requestPayload);
    await process.stdin.close();

    final stdoutText = await process.stdout.transform(utf8.decoder).join();
    final stderrText = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw TensorflowNsfwException(
        'TensorFlow inference failed ($exitCode): $stderrText',
      );
    }

    final decoded = jsonDecode(stdoutText) as Map<String, dynamic>;
    final rawResults = decoded['results'];
    if (rawResults is! List) {
      throw const TensorflowNsfwException(
        'Invalid TensorFlow response payload',
      );
    }

    return rawResults
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw const TensorflowNsfwException(
              'Invalid TensorFlow result entry',
            );
          }
          return entry.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          );
        })
        .cast<Map<String, double>>()
        .toList(growable: false);
  }

  Future<_NodeExec> _resolveNodeExec() async {
    if (Platform.isWindows) {
      final bundled = File(
        '${Directory.current.path}\\native\\tensorflow\\node\\windows-x64\\node.exe',
      );
      if (bundled.existsSync()) {
        return _NodeExec(command: bundled.path, args: const <String>[]);
      }
    }

    final candidates = <_NodeExec>[
      const _NodeExec(command: 'node', args: <String>[]),
    ];
    for (final candidate in candidates) {
      try {
        final probe = await Process.run(
          candidate.command,
          <String>[...candidate.args, '--version'],
          runInShell: Platform.isWindows,
        );
        if (probe.exitCode == 0) {
          return candidate;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    throw const TensorflowNsfwException(
      'Node.js runtime not found. Bundle node at native/tensorflow/node/windows-x64/node.exe or install Node.js 18+.',
    );
  }

  Directory _resolveRuntimeDir() => Directory(
        p.join(Directory.current.path, 'native', 'tensorflow', 'runtime'),
      );

  Future<void> _ensureNodeModules(_NodeExec node, Directory runtimeDir) async {
    final packageJson = File(p.join(runtimeDir.path, 'package.json'));
    if (!packageJson.existsSync()) {
      throw TensorflowNsfwException(
        'TensorFlow runtime package not found at ${runtimeDir.path}',
      );
    }

    final nodeModulesDir = Directory(p.join(runtimeDir.path, 'node_modules'));
    if (nodeModulesDir.existsSync()) {
      return;
    }

    final npmCommand = Platform.isWindows ? 'npm.cmd' : 'npm';
    final install = await Process.run(
      npmCommand,
      const <String>['install', '--omit=dev'],
      runInShell: Platform.isWindows,
      workingDirectory: runtimeDir.path,
      environment: Map<String, String>.from(Platform.environment),
    );
    if (install.exitCode != 0) {
      throw TensorflowNsfwException(
        'Failed to install TensorFlow runtime dependencies: ${install.stderr}',
      );
    }
  }
}

class _NodeExec {
  const _NodeExec({
    required this.command,
    required this.args,
  });

  final String command;
  final List<String> args;
}

class TensorflowNsfwException implements Exception {
  const TensorflowNsfwException(this.message);

  final String message;

  @override
  String toString() => 'TensorflowNsfwException: $message';
}
