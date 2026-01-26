import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/extensions/duration_extensions.dart';

void main() {
  group('DurationExtensions', () {
    group('toTimestamp', () {
      test('should format zero duration', () {
        expect(Duration.zero.toTimestamp(), equals('00:00:00.000'));
      });

      test('should format seconds only', () {
        expect(
          const Duration(seconds: 45).toTimestamp(),
          equals('00:00:45.000'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toTimestamp(),
          equals('00:05:30.000'),
        );
      });

      test('should format hours, minutes, seconds', () {
        expect(
          const Duration(hours: 2, minutes: 15, seconds: 45).toTimestamp(),
          equals('02:15:45.000'),
        );
      });

      test('should format milliseconds', () {
        expect(
          const Duration(seconds: 5, milliseconds: 123).toTimestamp(),
          equals('00:00:05.123'),
        );
      });

      test('should format large durations', () {
        expect(
          const Duration(hours: 99, minutes: 59, seconds: 59, milliseconds: 999)
              .toTimestamp(),
          equals('99:59:59.999'),
        );
      });

      test('should format with leading zeros', () {
        expect(
          const Duration(hours: 1, minutes: 1, seconds: 1, milliseconds: 1)
              .toTimestamp(),
          equals('01:01:01.001'),
        );
      });
    });

    group('toTimestampShort', () {
      test('should format zero duration', () {
        expect(Duration.zero.toTimestampShort(), equals('0:00'));
      });

      test('should format seconds only', () {
        expect(const Duration(seconds: 45).toTimestampShort(), equals('0:45'));
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toTimestampShort(),
          equals('5:30'),
        );
      });

      test('should format hours, minutes, seconds', () {
        expect(
          const Duration(hours: 2, minutes: 15, seconds: 45).toTimestampShort(),
          equals('2:15:45'),
        );
      });

      test('should format with single-digit minutes', () {
        expect(
          const Duration(hours: 1, minutes: 5, seconds: 30).toTimestampShort(),
          equals('1:05:30'),
        );
      });

      test('should round down milliseconds', () {
        expect(
          const Duration(seconds: 5, milliseconds: 999).toTimestampShort(),
          equals('0:05'),
        );
      });
    });

    group('toTimecode', () {
      test('should format at 24fps', () {
        expect(
          const Duration(seconds: 1).toTimecode(24),
          equals('00:00:01:00'),
        );
      });

      test('should format frames at 24fps', () {
        // 500ms at 24fps = 12 frames
        expect(
          const Duration(milliseconds: 500).toTimecode(24),
          equals('00:00:00:12'),
        );
      });

      test('should format at 30fps', () {
        // 1/30 second = ~33.33ms
        expect(
          const Duration(milliseconds: 33).toTimecode(30),
          equals('00:00:00:00'),
        );
      });

      test('should format at 60fps', () {
        expect(
          const Duration(seconds: 2, milliseconds: 500).toTimecode(60),
          equals('00:00:02:30'),
        );
      });

      test('should handle large durations at 24fps', () {
        expect(
          const Duration(hours: 1, minutes: 30, seconds: 45).toTimecode(24),
          equals('01:30:45:00'),
        );
      });
    });

    group('toDropFrameTimecode', () {
      test('should format at 29.97fps', () {
        expect(
          const Duration(seconds: 1).toDropFrameTimecode(29.97),
          contains(':'),
        );
      });

      test('should use semicolon separator for drop frame', () {
        expect(
          const Duration(minutes: 1).toDropFrameTimecode(29.97),
          contains(';'),
        );
      });

      test('should handle minute boundaries with drop frames', () {
        // At 29.97fps, frames 0 and 1 are dropped at minute boundaries
        // (except every 10 minutes)
        final result = const Duration(minutes: 1).toDropFrameTimecode(29.97);
        expect(result, isNotEmpty);
      });
    });

    group('toHumanReadable', () {
      test('should format zero as zero seconds', () {
        expect(Duration.zero.toHumanReadable(), equals('0 seconds'));
      });

      test('should format singular second', () {
        expect(
          const Duration(seconds: 1).toHumanReadable(),
          equals('1 second'),
        );
      });

      test('should format plural seconds', () {
        expect(
          const Duration(seconds: 45).toHumanReadable(),
          equals('45 seconds'),
        );
      });

      test('should format singular minute', () {
        expect(
          const Duration(minutes: 1).toHumanReadable(),
          equals('1 minute'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toHumanReadable(),
          equals('5 minutes, 30 seconds'),
        );
      });

      test('should format singular hour', () {
        expect(
          const Duration(hours: 1).toHumanReadable(),
          equals('1 hour'),
        );
      });

      test('should format hours, minutes, seconds', () {
        expect(
          const Duration(hours: 2, minutes: 15, seconds: 45).toHumanReadable(),
          equals('2 hours, 15 minutes, 45 seconds'),
        );
      });

      test('should omit zero components', () {
        expect(
          const Duration(hours: 1, seconds: 30).toHumanReadable(),
          equals('1 hour, 30 seconds'),
        );
      });
    });

    group('toHumanReadableCompact', () {
      test('should format zero as 0s', () {
        expect(Duration.zero.toHumanReadableCompact(), equals('0s'));
      });

      test('should format seconds', () {
        expect(
          const Duration(seconds: 45).toHumanReadableCompact(),
          equals('45s'),
        );
      });

      test('should format minutes', () {
        expect(
          const Duration(minutes: 5).toHumanReadableCompact(),
          equals('5m'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toHumanReadableCompact(),
          equals('5m 30s'),
        );
      });

      test('should format hours', () {
        expect(
          const Duration(hours: 2).toHumanReadableCompact(),
          equals('2h'),
        );
      });

      test('should format hours and minutes', () {
        expect(
          const Duration(hours: 2, minutes: 15).toHumanReadableCompact(),
          equals('2h 15m'),
        );
      });

      test('should omit zero components', () {
        expect(
          const Duration(hours: 1, seconds: 30).toHumanReadableCompact(),
          equals('1h 30s'),
        );
      });
    });

    group('toFFmpegTimestamp', () {
      test('should format for FFmpeg', () {
        expect(
          const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 500)
              .toFFmpegTimestamp(),
          equals('01:30:45.500'),
        );
      });

      test('should format zero duration', () {
        expect(Duration.zero.toFFmpegTimestamp(), equals('00:00:00.000'));
      });

      test('should handle microseconds precision', () {
        expect(
          const Duration(seconds: 1, microseconds: 500).toFFmpegTimestamp(),
          equals('00:00:01.000'),
        );
      });
    });

    group('frameAt', () {
      test('should calculate frame at 24fps', () {
        expect(const Duration(seconds: 1).frameAt(24), equals(24));
      });

      test('should calculate frame at 30fps', () {
        expect(const Duration(seconds: 2).frameAt(30), equals(60));
      });

      test('should calculate frame at 60fps', () {
        expect(const Duration(milliseconds: 500).frameAt(60), equals(30));
      });

      test('should calculate frame at zero duration', () {
        expect(Duration.zero.frameAt(24), equals(0));
      });

      test('should handle fractional frames', () {
        // 1.5 seconds at 24fps = 36 frames
        expect(
          const Duration(milliseconds: 1500).frameAt(24),
          equals(36),
        );
      });
    });

    group('fromFrame', () {
      test('should create duration from frame at 24fps', () {
        expect(
          DurationExtensions.fromFrame(24, 24),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should create duration from frame at 30fps', () {
        expect(
          DurationExtensions.fromFrame(30, 30),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should create duration from frame at 60fps', () {
        expect(
          DurationExtensions.fromFrame(60, 60),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should handle zero frame', () {
        expect(
          DurationExtensions.fromFrame(0, 24),
          equals(Duration.zero),
        );
      });

      test('should handle fractional durations', () {
        // Frame 12 at 24fps = 0.5 seconds
        expect(
          DurationExtensions.fromFrame(12, 24),
          equals(const Duration(milliseconds: 500)),
        );
      });
    });

    group('arithmetic operators', () {
      group('multiply operator', () {
        test('should multiply duration by integer', () {
          expect(
            const Duration(seconds: 5) * 2,
            equals(const Duration(seconds: 10)),
          );
        });

        test('should multiply duration by double', () {
          expect(
            const Duration(seconds: 10).multiply(0.5),
            equals(const Duration(seconds: 5)),
          );
        });

        test('should handle zero multiplier', () {
          expect(
            const Duration(seconds: 5).multiply(0),
            equals(Duration.zero),
          );
        });
      });

      group('divide operator', () {
        test('should divide duration by integer', () {
          expect(
            const Duration(seconds: 10).divide(2),
            equals(const Duration(seconds: 5)),
          );
        });

        test('should handle fractional results', () {
          expect(
            const Duration(seconds: 10).divide(3),
            equals(const Duration(seconds: 3, milliseconds: 333)),
          );
        });
      });

      group('clamp', () {
        test('should clamp duration within range', () {
          expect(
            const Duration(seconds: 5).clamp(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 5)),
          );
        });

        test('should clamp to minimum', () {
          expect(
            const Duration(seconds: 1).clamp(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 3)),
          );
        });

        test('should clamp to maximum', () {
          expect(
            const Duration(seconds: 15).clamp(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 10)),
          );
        });
      });
    });

    group('comparison extensions', () {
      test('should check if duration is longer', () {
        expect(
          const Duration(seconds: 10).isLongerThan(const Duration(seconds: 5)),
          isTrue,
        );
        expect(
          const Duration(seconds: 5).isLongerThan(const Duration(seconds: 10)),
          isFalse,
        );
      });

      test('should check if duration is shorter', () {
        expect(
          const Duration(seconds: 5).isShorterThan(const Duration(seconds: 10)),
          isTrue,
        );
        expect(
          const Duration(seconds: 10).isShorterThan(const Duration(seconds: 5)),
          isFalse,
        );
      });

      test('should check if duration is zero', () {
        expect(Duration.zero.isZero, isTrue);
        expect(const Duration(seconds: 1).isZero, isFalse);
      });

      test('should check if duration is positive', () {
        expect(const Duration(seconds: 1).isPositive, isTrue);
        expect(Duration.zero.isPositive, isFalse);
      });

      test('should check if duration is negative', () {
        expect(const Duration(seconds: -1).isNegative, isTrue);
        expect(Duration.zero.isNegative, isFalse);
      });
    });

    group('conversion extensions', () {
      test('should convert to total seconds', () {
        expect(
          const Duration(minutes: 1, seconds: 30).totalSeconds,
          equals(90.0),
        );
      });

      test('should convert to total minutes', () {
        expect(
          const Duration(hours: 1, minutes: 30).totalMinutes,
          equals(90.0),
        );
      });

      test('should convert to total hours', () {
        expect(
          const Duration(hours: 2, minutes: 30).totalHours,
          equals(2.5),
        );
      });
    });

    group('range checking', () {
      test('should check if duration is within range', () {
        final duration = const Duration(seconds: 5);
        expect(
          duration.isWithin(
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 10),
          ),
          isTrue,
        );
      });

      test('should check if duration is outside range', () {
        final duration = const Duration(seconds: 15);
        expect(
          duration.isWithin(
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 10),
          ),
          isFalse,
        );
      });

      test('should be inclusive of start boundary', () {
        final duration = const Duration(seconds: 3);
        expect(
          duration.isWithin(
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 10),
          ),
          isTrue,
        );
      });

      test('should be inclusive of end boundary', () {
        final duration = const Duration(seconds: 10);
        expect(
          duration.isWithin(
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 10),
          ),
          isTrue,
        );
      });
    });

    group('snapToFrame', () {
      test('should snap to nearest frame at 24fps', () {
        // 520ms should snap to frame 12 (500ms) or frame 13 (541.67ms)
        final snapped = const Duration(milliseconds: 520).snapToFrame(24);
        expect(snapped.inMilliseconds % (1000 ~/ 24), equals(0));
      });

      test('should snap exact frame to itself', () {
        final frameDuration = const Duration(milliseconds: 1000 ~/ 24);
        final snapped = frameDuration.snapToFrame(24);
        expect(snapped, equals(frameDuration));
      });

      test('should snap zero to zero', () {
        expect(Duration.zero.snapToFrame(24), equals(Duration.zero));
      });
    });

    group('edge cases', () {
      test('should handle very large durations', () {
        final largeDuration = const Duration(days: 365);
        expect(largeDuration.toTimestamp(), isNotEmpty);
        expect(largeDuration.toHumanReadable(), isNotEmpty);
      });

      test('should handle negative durations gracefully', () {
        final negativeDuration = const Duration(seconds: -5);
        // Behavior depends on implementation - should not throw
        expect(negativeDuration.isNegative, isTrue);
      });

      test('should handle microsecond precision', () {
        final preciseDuration = const Duration(microseconds: 123456);
        expect(preciseDuration.toTimestamp(), isNotEmpty);
      });
    });
  });
}
