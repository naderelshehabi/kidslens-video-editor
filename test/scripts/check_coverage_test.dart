// Tests for scripts/check_coverage.dart (Phase 0.2 coverage ratchet).
//
// Coverage is exercised end-to-end via `dart run` + Process.run on temporary
// fixture files. This is the established pattern in this repo (see
// test/services/frame_sampling_chunk_selection_test.dart) and keeps the script
// as a true entry point rather than requiring a library-extract refactor.
//
// Note: inside `flutter_tester`, the spawned process environment does NOT
// inherit a PATH that reaches the Dart SDK. We resolve the dart executable
// from Platform.resolvedExecutable, which lives at
//   <flutter>/bin/cache/artifacts/engine/<os>/flutter_tester[.exe]
// and derives the dart SDK path as
//   <flutter>/bin/cache/dart-sdk/bin/dart[.exe].
// When the resolved path does not exist (e.g. a custom test runner with no
// Flutter cache), the CLI tests are skipped with a visible reason.

@Tags(['scripts'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _resolveDartExecutable() {
  // Platform.resolvedExecutable is the flutter_tester binary. Its absolute
  // path is something like:
  //   <flutter>/bin/cache/artifacts/engine/<host>/flutter_tester[.exe]
  // We need the dart SDK binary at:
  //   <flutter>/bin/cache/dart-sdk/bin/dart[.exe]
  //
  // Rather than hard-code the depth, walk up the parent chain probing for the
  // dart-sdk layout at each level; the first ancestor that contains it is
  // <flutter>. This is robust against future Flutter layout tweaks.
  final suffix = Platform.isWindows
      ? r'\bin\cache\dart-sdk\bin\dart.exe'
      : '/bin/cache/dart-sdk/bin/dart';
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = '${dir.path}$suffix';
    if (File(candidate).existsSync()) {
      return candidate;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      // Reached filesystem root.
      break;
    }
    dir = parent;
  }
  return null;
}

void main() {
  group('check_coverage.dart CLI', () {
    late Directory temp;
    late String scriptPath;
    late String? dartExe;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('check_coverage_test_');
      // The script lives at <repo>/scripts/check_coverage.dart; this test file
      // lives at <repo>/test/scripts/check_coverage_test.dart. Resolve repo
      // root from the test file's own path.
      final thisFile = File(r'D:\Projects\naderelshehabi\kidslens-video-editor'
          r'\test\scripts\check_coverage_test.dart');
      final repoRoot = thisFile.parent.parent.parent;
      scriptPath = '${repoRoot.path}\\scripts\\check_coverage.dart';
      dartExe = _resolveDartExecutable();
    });

    tearDown(() async {
      if (temp.existsSync()) {
        await temp.delete(recursive: true);
      }
    });

    Future<ProcessResult> run({
      required String lcovPath,
      required String floorPath,
    }) async {
      final dart = dartExe;
      if (dart == null) {
        throw StateError(
          'dart executable could not be resolved from '
          '${Platform.resolvedExecutable}',
        );
      }
      return Process.run(
        dart,
        ['run', scriptPath, '--lcov', lcovPath, '--floor-file', floorPath],
      );
    }

    Future<File> write(String name, String contents) async =>
        File('${temp.path}\\$name').writeAsString(contents);

    test('passes when measured coverage > floor', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:100
LH:80
end_of_record
''');
      final floor = await write('floor.txt', '75');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 0, reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('coverage ratchet PASSED'));
      expect(r.stdout.toString(), contains('80.000% (80/100'));
    });

    test('passes when measured coverage equals floor (no flap)', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:100
LH:80
end_of_record
''');
      final floor = await write('floor.txt', '80');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 0, reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('PASSED'));
    });

    test('passes when floor is 0 and lcov has no hit data yet', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '');
      final floor = await write('floor.txt', '0');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 0, reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('0.000% (0/0'));
    });

    test('aggregates multiple records correctly', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
DA:1,1
FNF:5
FNH:3
LF:100
LH:70
end_of_record
SF:lib/b.dart
BRDA:1,0,0,1
LF:50
LH:30
end_of_record
''');
      final floor = await write('floor.txt', '65');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      // 70+30 = 100 hits out of 150 lines = 66.667% > 65% floor -> pass.
      expect(r.exitCode, 0, reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('100/150 lines'));
      expect(r.stdout.toString(), contains('66.667%'));
    });

    test('fails with exit 1 when measured coverage < floor', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:100
LH:50
end_of_record
''');
      final floor = await write('floor.txt', '75');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 1);
      expect(r.stderr.toString(), contains('coverage ratchet FAILED'));
      expect(r.stderr.toString(), contains('50.000% < floor 75.000%'));
      expect(
        r.stderr.toString(),
        contains('The floor must never decrease without'),
      );
    });

    test('floor file may carry a trailing # comment', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:100
LH:80
end_of_record
''');
      final floor =
          await write('floor.txt', '80  # baseline 2026-07-19 revamp 0.2');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 0, reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('floor:    80.000%'));
    });

    test('floor file may carry leading comment lines', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:100
LH:80
end_of_record
''');
      final floor = await write('floor.txt', '''
# revamp coverage ratchet
# bumped after Phase 1

80
''');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 0, reason: r.stderr.toString());
    });

    test('out-of-range floor exits 2', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:10
LH:5
end_of_record
''');
      final floor = await write('floor.txt', '150');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('out of range'));
    });

    test('non-numeric floor value exits 2', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:10
LH:5
end_of_record
''');
      final floor = await write('floor.txt', 'high');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('could not parse floor value'));
    });

    test('floor file with only comments exits 2', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:10
LH:5
end_of_record
''');
      final floor = await write('floor.txt', '# just a comment\n');
      final r = await run(lcovPath: lcov.path, floorPath: floor.path);
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('no floor value found'));
    });

    test('missing lcov file exits 2 with actionable message', () async {
      if (dartExe == null) return;
      final floor = await write('floor.txt', '40');
      final r = await Process.run(
        dartExe!,
        [
          'run',
          scriptPath,
          '--lcov',
          '${temp.path}\\missing.info',
          '--floor-file',
          floor.path,
        ],
      );
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('lcov file not found'));
      expect(r.stderr.toString(), contains('flutter test --coverage'));
    });

    test('missing floor file exits 2 with actionable message', () async {
      if (dartExe == null) return;
      final lcov = await write('lcov.info', '''
SF:lib/a.dart
LF:10
LH:5
end_of_record
''');
      final r = await Process.run(
        dartExe!,
        [
          'run',
          scriptPath,
          '--lcov',
          lcov.path,
          '--floor-file',
          '${temp.path}\\no-floor.txt',
        ],
      );
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('floor file not found'));
      expect(r.stderr.toString(), contains('Seed it with the current'));
    });

    test('--help prints usage and exits 0', () async {
      if (dartExe == null) return;
      final r = await Process.run(dartExe!, ['run', scriptPath, '--help']);
      expect(r.exitCode, 0);
      expect(r.stdout.toString(), contains('Usage:'));
      expect(r.stdout.toString(), contains('--lcov'));
      expect(r.stdout.toString(), contains('--floor-file'));
    });

    test('unknown flag exits 2 with parse error', () async {
      if (dartExe == null) return;
      final r = await Process.run(dartExe!, ['run', scriptPath, '--bogus']);
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('unknown argument "--bogus"'));
    });

    test('--lcov without a value exits 2', () async {
      if (dartExe == null) return;
      final r = await Process.run(dartExe!, ['run', scriptPath, '--lcov']);
      expect(r.exitCode, 2);
      expect(r.stderr.toString(), contains('--lcov requires a value'));
    });

    test('dart executable resolution (informational)', () {
      // Sanity check that the resolver finds a usable dart. On a dev machine
      // where dartExe comes back null, every CLI test silently no-ops with an
      // early `if (dartExe == null) return;`. This test surfaces a loud
      // warning instead so a broken resolution path doesn't silently
      // disable the whole CLI suite.
      if (dartExe == null) {
        // ignore: avoid_print
        print(
          'WARNING: could not resolve dart.exe from '
          '${Platform.resolvedExecutable}. CLI tests in this file were '
          'skipped. CI uses the standard Flutter layout; if you see this '
          'locally, update _resolveDartExecutable for your setup.',
        );
        return;
      }
      expect(File(dartExe!).existsSync(), isTrue);
    });
  });
}
