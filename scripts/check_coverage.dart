// Coverage ratchet for the KidsLens revamp (Phase 0.2).
//
// Parses `coverage/lcov.info` (LCOV format), sums LF/LH across every
// `end_of_record` block, and compares the measured line coverage against the
// floor stored in `coverage_floor.txt`. Exits 1 when measured coverage falls
// below the floor, so the CI step "Enforce coverage floor" can fail the build.
//
// Floor file format:
//   - A single line containing a decimal percent, e.g. `43.24`.
//   - A `#` may start a trailing comment: `43.24  # baseline 2026-07-19`.
//   - Blank lines and lines starting with `#` are ignored.
//   - The value is interpreted as **percent** (not 0–1 ratio).
//
// Usage:
//   dart run scripts/check_coverage.dart
//   dart run scripts/check_coverage.dart --lcov path/to/lcov.info \
//                                        --floor-file path/to/coverage_floor.txt
//
// Exit codes:
//   0  measured coverage >= floor
//   1  measured coverage < floor (CI-failing)
//   2  invalid invocation / I/O error (missing floor file, unparseable floor,
//      malformed lcov)
//
// Tests live at `test/scripts/check_coverage_test.dart`.

import 'dart:io';

const _defaultLcovPath = 'coverage/lcov.info';
const _defaultFloorPath = 'coverage_floor.txt';
// Absorbs rounding noise so a 43.242% measurement never flaps against a 43.24
// floor across runs / OS float formatting.
const _epsilonPercent = 0.005;

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }
  if (options.parseError != null) {
    stderr
      ..writeln('error: ${options.parseError}')
      ..writeln(_usage);
    exitCode = 2;
    return;
  }

  final lcovFile = File(options.lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'error: lcov file not found at "${options.lcovPath}". '
      'Run `flutter test --coverage` first.',
    );
    exitCode = 2;
    return;
  }
  final floorFile = File(options.floorPath);
  if (!floorFile.existsSync()) {
    stderr.writeln(
      'error: coverage floor file not found at "${options.floorPath}". '
      'Seed it with the current measured coverage (see Phase 0.2).',
    );
    exitCode = 2;
    return;
  }

  final CoverageStats stats;
  try {
    stats = parseLcov(await lcovFile.readAsString());
  } on LcovParseException catch (e) {
    stderr.writeln('error: failed to parse lcov: ${e.message}');
    exitCode = 2;
    return;
  }

  final double floorPercent;
  try {
    floorPercent = parseFloor(await floorFile.readAsString());
  } on FloorParseException catch (e) {
    stderr.writeln('error: ${e.message} (file: ${options.floorPath})');
    exitCode = 2;
    return;
  }

  final measured = stats.percent;

  stdout
    ..writeln('coverage: ${measured.toStringAsFixed(3)}% '
        '(${stats.totalHit}/${stats.totalFound} lines, '
        '${stats.recordCount} records)')
    ..writeln('floor:    ${floorPercent.toStringAsFixed(3)}% '
        '(from ${options.floorPath})');

  if (measured + _epsilonPercent < floorPercent) {
    stderr.writeln(
      'coverage ratchet FAILED: measured ${measured.toStringAsFixed(3)}% '
      '< floor ${floorPercent.toStringAsFixed(3)}% '
      '(delta ${(floorPercent - measured).toStringAsFixed(3)}%). '
      'Add tests or lower the floor to match this baseline. '
      'The floor must never decrease without a recorded justification.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('coverage ratchet PASSED.');
}

/// Aggregated LCOV line-coverage numbers across all `end_of_record` blocks.
class CoverageStats {
  CoverageStats({
    required this.totalFound,
    required this.totalHit,
    required this.recordCount,
  });

  final int totalFound;
  final int totalHit;
  final int recordCount;

  double get percent => totalFound == 0 ? 0.0 : 100 * totalHit / totalFound;
}

class LcovParseException implements Exception {
  LcovParseException(this.message);
  final String message;
  @override
  String toString() => 'LcovParseException: $message';
}

class FloorParseException implements Exception {
  FloorParseException(this.message);
  final String message;
  @override
  String toString() => 'FloorParseException: $message';
}

/// Parses LCOV text into [CoverageStats].
///
/// Recognises `LF:<n>` (lines found) and `LH:<n>` (lines hit) lines, summing
/// them across every record. Lines we do not understand are ignored, but a
/// malformed `LF:`/`LH:` value (non-integer) throws [LcovParseException] so
/// a corrupt artifact fails loudly rather than silently reporting 0%.
CoverageStats parseLcov(String contents) {
  var totalFound = 0;
  var totalHit = 0;
  var recordCount = 0;
  for (final raw in contents.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    if (line == 'end_of_record') {
      recordCount++;
      continue;
    }
    final lf = _intAfter(line, 'LF:');
    if (lf != null) {
      totalFound += lf;
      continue;
    }
    final lh = _intAfter(line, 'LH:');
    if (lh != null) {
      totalHit += lh;
      continue;
    }
    // All other LCOV lines (SF:, DA:, FN:, FNF:, FNH:, BRH:, etc.) are not
    // needed for line-level coverage accounting.
  }
  return CoverageStats(
    totalFound: totalFound,
    totalHit: totalHit,
    recordCount: recordCount,
  );
}

int? _intAfter(String line, String prefix) {
  if (!line.startsWith(prefix)) return null;
  final value = line.substring(prefix.length).trim();
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw LcovParseException(
      'unparseable $prefix value "$value" (line: "$line")',
    );
  }
  return parsed;
}

/// Parses the floor file contents into a percent value.
///
/// Format: one decimal percent, optionally followed by a `#` comment.
/// Blank lines and lines starting with `#` are ignored. Whitespace around the
/// number is trimmed. Throws [FloorParseException] when the file has no usable
/// numeric value, or when the value is outside [0, 100].
double parseFloor(String contents) {
  for (final raw in contents.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final hashIdx = line.indexOf('#');
    final candidate = (hashIdx >= 0 ? line.substring(0, hashIdx) : line).trim();
    if (candidate.isEmpty) continue;
    final parsed = double.tryParse(candidate);
    if (parsed == null) {
      throw FloorParseException(
        'could not parse floor value "$candidate"',
      );
    }
    if (parsed < 0 || parsed > 100) {
      throw FloorParseException(
        'floor value $parsed is out of range [0, 100]',
      );
    }
    return parsed;
  }
  throw FloorParseException('no floor value found in file');
}

class _Options {
  _Options({
    required this.lcovPath,
    required this.floorPath,
    this.showHelp = false,
    this.parseError,
  });

  factory _Options.parse(List<String> args) {
    var lcovPath = _defaultLcovPath;
    var floorPath = _defaultFloorPath;
    String? error;
    var i = 0;
    while (i < args.length) {
      final a = args[i];
      switch (a) {
        case '-h':
        case '--help':
          return _Options(
            lcovPath: lcovPath,
            floorPath: floorPath,
            showHelp: true,
          );
        case '--lcov':
          if (i + 1 >= args.length) {
            error = '--lcov requires a value';
            break;
          }
          lcovPath = args[++i];
        case '--floor-file':
          if (i + 1 >= args.length) {
            error = '--floor-file requires a value';
            break;
          }
          floorPath = args[++i];
        default:
          error = 'unknown argument "$a"';
      }
      if (error != null) break;
      i++;
    }
    return _Options(
      lcovPath: lcovPath,
      floorPath: floorPath,
      parseError: error,
    );
  }

  final String lcovPath;
  final String floorPath;
  final bool showHelp;
  final String? parseError;
}

const _usage = '''
Usage: dart run scripts/check_coverage.dart [options]

Options:
  --lcov <path>         Path to the lcov.info file (default: coverage/lcov.info)
  --floor-file <path>   Path to the coverage floor file
                         (default: coverage_floor.txt)
  -h, --help            Show this help

Floor file format:
  A single decimal percent (e.g. `43.24`). A `#` introduces a trailing
  comment; blank lines and lines starting with `#` are ignored.

Exit codes:
  0  measured coverage >= floor
  1  measured coverage < floor (ratchet failure)
  2  invalid invocation / I/O or parse error
''';
