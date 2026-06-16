import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';
import 'package:kidslens_video_editor/services/detection/vss_validation_report.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final options = _ValidationOptions.parse(args);
  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }

  final dataset = EvaluationDataset.fromJson(
    jsonDecode(await File(options.manifestPath).readAsString())
        as Map<String, dynamic>,
  );
  final issues = [
    ...dataset.validate(),
    ..._missingClipFileIssues(dataset, options.datasetRoot),
  ];
  if (issues.isNotEmpty) {
    stderr.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'status': 'invalid_dataset',
        'issues': issues,
      }),
    );
    exitCode = 2;
    return;
  }

  final profileRuns = options.predictionsPath == null
      ? await _runExternalPipelineCommands(options, dataset)
      : await _readPredictions(options.predictionsPath!);

  final report = const VssValidationReportBuilder().build(
    dataset: dataset,
    datasetRoot: p.normalize(p.absolute(options.datasetRoot)),
    profileRuns: profileRuns,
  );
  final outputFile = options.outputPath == null
      ? File(
          p.join(
            'docs',
            'implement',
            'validation-reports',
            '${DateTime.now().toUtc().toIso8601String().substring(0, 10)}-rtx-validation.json',
          ),
        )
      : File(options.outputPath!);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString('${report.toPrettyJson()}\n');

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'status': report.comparison.exitGate.passed ? 'passed' : 'failed',
      'outputPath': outputFile.path,
      'exitGate': report.comparison.exitGate.toJson(),
    }),
  );
  if (!report.comparison.exitGate.passed && options.failOnExitGate) {
    exitCode = 1;
  }
}

Future<List<VssValidationProfileRun>> _readPredictions(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  return VssValidationPredictionsFile.fromJson(decoded as Map<String, dynamic>)
      .profileRuns;
}

Future<List<VssValidationProfileRun>> _runExternalPipelineCommands(
  _ValidationOptions options,
  EvaluationDataset dataset,
) async {
  final command = options.analysisCommand;
  if (command == null) {
    throw ArgumentError(
      'Provide either --predictions or --analysis-command. See --help.',
    );
  }
  final commandParts = _splitCommand(command);
  if (commandParts.isEmpty) {
    throw ArgumentError('--analysis-command cannot be empty');
  }

  final profileRuns = <VssValidationProfileRun>[];
  for (final profile in options.profiles) {
    final detectionsByClipId = <String, List<EvaluationAnnotation>>{};
    final chunkLatencyMs = <int>[];
    final memoryUsageMb = <int>[];
    final vramUsageMb = <int>[];
    final errors = <String>[];
    var schemaFailureCount = 0;
    var crashCount = 0;

    for (final clip in dataset.clips) {
      final clipPath =
          p.normalize(p.join(options.datasetRoot, clip.relativePath));
      final replacements = <String, String>{
        'profileId': profile.id,
        'profileName': profile.displayName,
        'clipId': clip.id,
        'mediaId': clip.mediaId,
        'clipPath': clipPath,
        'manifestPath': options.manifestPath,
        'datasetRoot': options.datasetRoot,
      };
      final exe = _replacePlaceholders(commandParts.first, replacements);
      final args = [
        for (final arg in commandParts.skip(1))
          _replacePlaceholders(arg, replacements),
      ];

      final sampler = _NvidiaSmiSampler(interval: options.gpuPollInterval);
      await sampler.start();
      late final ProcessResult result;
      try {
        result = await Process.run(exe, args).timeout(options.commandTimeout);
      } on Object catch (error) {
        crashCount += 1;
        errors.add('${clip.id}: command failed: $error');
        await sampler.stop();
        vramUsageMb.addAll(sampler.samples);
        continue;
      }
      await sampler.stop();
      vramUsageMb.addAll(sampler.samples);

      if (result.exitCode != 0) {
        crashCount += 1;
        errors.add(
          '${clip.id}: command exited ${result.exitCode}: ${result.stderr}',
        );
        continue;
      }
      try {
        final decoded = jsonDecode('${result.stdout}') as Map<String, dynamic>;
        final clipOutput = _ClipCommandOutput.fromJson(decoded);
        detectionsByClipId[clip.id] = clipOutput.detections;
        chunkLatencyMs.addAll(clipOutput.chunkLatencyMs);
        memoryUsageMb.addAll(clipOutput.memoryUsageMb);
        vramUsageMb.addAll(clipOutput.vramUsageMb);
        schemaFailureCount += clipOutput.schemaFailureCount;
        crashCount += clipOutput.crashCount;
        errors.addAll(clipOutput.errors.map((error) => '${clip.id}: $error'));
      } on Object catch (error) {
        schemaFailureCount += 1;
        errors.add('${clip.id}: invalid command JSON: $error');
      }
    }

    profileRuns.add(
      VssValidationProfileRun(
        predictions: EvaluationProfilePredictions.forBuiltInProfile(
          profile: profile,
          detectionsByClipId: detectionsByClipId,
          runtimeId: options.runtimeId,
          chunkLatencyMs: chunkLatencyMs,
          memoryUsageMb: memoryUsageMb,
          vramUsageMb: vramUsageMb,
        ),
        schemaFailureCount: schemaFailureCount,
        crashCount: crashCount,
        errors: errors,
      ),
    );
  }
  return profileRuns;
}

List<String> _missingClipFileIssues(
  EvaluationDataset dataset,
  String datasetRoot,
) =>
    [
      for (final clip in dataset.clips)
        if (!File(p.join(datasetRoot, clip.relativePath)).existsSync())
          '${clip.id}: missing clip file ${p.join(datasetRoot, clip.relativePath)}',
    ];

class _ClipCommandOutput {
  const _ClipCommandOutput({
    required this.detections,
    required this.chunkLatencyMs,
    required this.memoryUsageMb,
    required this.vramUsageMb,
    required this.schemaFailureCount,
    required this.crashCount,
    required this.errors,
  });

  factory _ClipCommandOutput.fromJson(Map<String, dynamic> json) =>
      _ClipCommandOutput(
        detections: _readList(json, 'detections')
            .map(
              (entry) => EvaluationAnnotation.fromJson(
                _readMap(entry, 'detections[]'),
              ),
            )
            .toList(growable: false),
        chunkLatencyMs: _readOptionalIntList(json, 'chunkLatencyMs'),
        memoryUsageMb: _readOptionalIntList(json, 'memoryUsageMb'),
        vramUsageMb: _readOptionalIntList(json, 'vramUsageMb'),
        schemaFailureCount:
            _readOptionalInt(json, 'schemaFailureCount', defaultValue: 0),
        crashCount: _readOptionalInt(json, 'crashCount', defaultValue: 0),
        errors: _readOptionalStringList(json, 'errors'),
      );

  final List<EvaluationAnnotation> detections;
  final List<int> chunkLatencyMs;
  final List<int> memoryUsageMb;
  final List<int> vramUsageMb;
  final int schemaFailureCount;
  final int crashCount;
  final List<String> errors;
}

class _NvidiaSmiSampler {
  _NvidiaSmiSampler({required this.interval});

  final Duration interval;
  final samples = <int>[];
  Timer? _timer;

  Future<void> start() async {
    await _sample();
    _timer = Timer.periodic(interval, (_) => unawaited(_sample()));
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _sample();
  }

  Future<void> _sample() async {
    try {
      final result = await Process.run(
        'nvidia-smi',
        const [
          '--query-gpu=memory.used',
          '--format=csv,noheader,nounits',
        ],
      );
      if (result.exitCode != 0) return;
      for (final line in '${result.stdout}'.split(RegExp(r'\r?\n'))) {
        final value = int.tryParse(line.trim());
        if (value != null) samples.add(value);
      }
    } catch (_) {
      // nvidia-smi is optional; absence keeps VRAM samples empty.
    }
  }
}

class _ValidationOptions {
  const _ValidationOptions({
    required this.datasetRoot,
    required this.manifestPath,
    required this.predictionsPath,
    required this.outputPath,
    required this.analysisCommand,
    required this.profiles,
    required this.runtimeId,
    required this.commandTimeout,
    required this.gpuPollInterval,
    required this.failOnExitGate,
    required this.showHelp,
  });

  factory _ValidationOptions.parse(List<String> args) {
    String? datasetRoot;
    String? manifestPath;
    String? predictionsPath;
    String? outputPath;
    String? analysisCommand;
    String? runtimeId;
    var profiles = EvaluationProfileId.values.toList(growable: false);
    var commandTimeout = const Duration(minutes: 20);
    var gpuPollInterval = const Duration(seconds: 2);
    var failOnExitGate = false;
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
        case '--dataset-root':
          datasetRoot = readValue();
        case '--manifest':
          manifestPath = readValue();
        case '--predictions':
          predictionsPath = readValue();
        case '--output':
          outputPath = readValue();
        case '--analysis-command':
          analysisCommand = readValue();
        case '--profile':
          profiles = [
            for (final value in readValue().split(','))
              _parseProfile(value.trim()),
          ];
        case '--runtime-id':
          runtimeId = readValue();
        case '--command-timeout-minutes':
          commandTimeout = Duration(minutes: int.parse(readValue()));
        case '--gpu-poll-seconds':
          gpuPollInterval = Duration(seconds: int.parse(readValue()));
        case '--fail-on-exit-gate':
          failOnExitGate = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          throw ArgumentError('Unknown argument: $arg');
      }
    }

    if (showHelp) {
      return _ValidationOptions(
        datasetRoot: '.',
        manifestPath: '',
        predictionsPath: predictionsPath,
        outputPath: outputPath,
        analysisCommand: analysisCommand,
        profiles: profiles,
        runtimeId: runtimeId,
        commandTimeout: commandTimeout,
        gpuPollInterval: gpuPollInterval,
        failOnExitGate: failOnExitGate,
        showHelp: true,
      );
    }

    if (datasetRoot == null) {
      throw ArgumentError('--dataset-root is required');
    }
    if (manifestPath == null) {
      throw ArgumentError('--manifest is required');
    }
    if (predictionsPath == null && analysisCommand == null) {
      throw ArgumentError(
        'Either --predictions or --analysis-command is required',
      );
    }
    if (predictionsPath != null && analysisCommand != null) {
      throw ArgumentError(
        'Use either --predictions or --analysis-command, not both',
      );
    }

    return _ValidationOptions(
      datasetRoot: datasetRoot,
      manifestPath: manifestPath,
      predictionsPath: predictionsPath,
      outputPath: outputPath,
      analysisCommand: analysisCommand,
      profiles: profiles,
      runtimeId: runtimeId,
      commandTimeout: commandTimeout,
      gpuPollInterval: gpuPollInterval,
      failOnExitGate: failOnExitGate,
      showHelp: false,
    );
  }

  final String datasetRoot;
  final String manifestPath;
  final String? predictionsPath;
  final String? outputPath;
  final String? analysisCommand;
  final List<EvaluationProfileId> profiles;
  final String? runtimeId;
  final Duration commandTimeout;
  final Duration gpuPollInterval;
  final bool failOnExitGate;
  final bool showHelp;
}

EvaluationProfileId _parseProfile(String value) {
  final profile = EvaluationProfileId.tryParse(value);
  if (profile == null) {
    throw ArgumentError('Unknown profile: $value');
  }
  return profile;
}

List<String> _splitCommand(String command) {
  final parts = <String>[];
  final current = StringBuffer();
  var quote = '';
  for (var i = 0; i < command.length; i += 1) {
    final char = command[i];
    if ((char == '"' || char == "'") && quote.isEmpty) {
      quote = char;
      continue;
    }
    if (char == quote) {
      quote = '';
      continue;
    }
    if (char.trim().isEmpty && quote.isEmpty) {
      if (current.isNotEmpty) {
        parts.add(current.toString());
        current.clear();
      }
      continue;
    }
    current.write(char);
  }
  if (quote.isNotEmpty) throw ArgumentError('Unterminated quote in command');
  if (current.isNotEmpty) parts.add(current.toString());
  return parts;
}

String _replacePlaceholders(String value, Map<String, String> replacements) {
  var next = value;
  for (final entry in replacements.entries) {
    next = next.replaceAll('{${entry.key}}', entry.value);
  }
  return next;
}

Map<String, dynamic> _readMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field must be an object');
}

List<dynamic> _readList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is List) return value;
  throw FormatException('$field must be a list');
}

int _readOptionalInt(
  Map<String, dynamic> json,
  String field, {
  required int defaultValue,
}) {
  final value = json[field];
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.round();
  throw FormatException('$field must be an integer');
}

List<int> _readOptionalIntList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const <int>[];
  if (value is! List) throw FormatException('$field must be a list');
  return value.map((entry) {
    if (entry is int) return entry;
    if (entry is num) return entry.round();
    throw FormatException('$field entries must be integers');
  }).toList(growable: false);
}

List<String> _readOptionalStringList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const <String>[];
  if (value is! List) throw FormatException('$field must be a list');
  return value.map((entry) => '$entry').toList(growable: false);
}

const _usage = '''
Run the VSS Phase 10 RTX validation report driver.

This runner is local-only. It validates a supplied EvaluationDataset manifest,
checks that every referenced clip exists under --dataset-root, collects
predictions, compares profiles with EvaluationRunner, records latency/VRAM/
schema/crash metrics, and writes:
  docs/implement/validation-reports/<date>-rtx-validation.json

Prediction JSON mode:
  dart run scripts/vss_validation_runner.dart ^
    --dataset-root D:\\validation-clips ^
    --manifest D:\\validation-clips\\manifest.json ^
    --predictions D:\\validation-clips\\predictions.json

External command mode:
  dart run scripts/vss_validation_runner.dart ^
    --dataset-root D:\\validation-clips ^
    --manifest D:\\validation-clips\\manifest.json ^
    --analysis-command "flutter test test/manual/vss_profile_runner_test.dart --plain-name {profileId} --dart-define=CLIP={clipPath}"

The external command is invoked once per profile and clip. It must write JSON to
stdout:
  {
    "detections": [EvaluationAnnotation JSON...],
    "chunkLatencyMs": [4100, 3900],
    "memoryUsageMb": [1200],
    "vramUsageMb": [8200],
    "schemaFailureCount": 0,
    "crashCount": 0,
    "errors": []
  }

Placeholders available in --analysis-command:
  {profileId}, {profileName}, {clipId}, {mediaId}, {clipPath},
  {manifestPath}, {datasetRoot}

Options:
  --profile legacy_only,vlm_only,vlm_plus_legacy_evidence,vlm_plus_grounding
  --runtime-id cuda_llamacpp
  --output path\\report.json
  --command-timeout-minutes 20
  --gpu-poll-seconds 2
  --fail-on-exit-gate
''';
