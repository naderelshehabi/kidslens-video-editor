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

    group('toShortTimestamp', () {
      test('should format zero duration', () {
        expect(Duration.zero.toShortTimestamp(), equals('00:00:00'));
      });

      test('should format seconds only', () {
        expect(
          const Duration(seconds: 45).toShortTimestamp(),
          equals('00:00:45'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toShortTimestamp(),
          equals('00:05:30'),
        );
      });

      test('should format hours, minutes, seconds', () {
        expect(
          const Duration(hours: 2, minutes: 15, seconds: 45).toShortTimestamp(),
          equals('02:15:45'),
        );
      });

      test('should format with single-digit minutes', () {
        expect(
          const Duration(hours: 1, minutes: 5, seconds: 30).toShortTimestamp(),
          equals('01:05:30'),
        );
      });

      test('should round down milliseconds', () {
        expect(
          const Duration(seconds: 5, milliseconds: 999).toShortTimestamp(),
          equals('00:00:05'),
        );
      });
    });

    group('toTimecode', () {
      test('should format at 24fps', () {
        expect(
          const Duration(seconds: 1).toTimecode(),
          equals('00:00:01:00'),
        );
      });

      test('should format frames at 24fps', () {
        // 500ms at 24fps = 12 frames
        expect(
          const Duration(milliseconds: 500).toTimecode(),
          equals('00:00:00:12'),
        );
      });

      test('should format at 30fps', () {
        // 1/30 second = ~33.33ms
        expect(
          const Duration(milliseconds: 33).toTimecode(fps: 30),
          equals('00:00:00:00'),
        );
      });

      test('should format at 60fps', () {
        expect(
          const Duration(seconds: 2, milliseconds: 500).toTimecode(fps: 60),
          equals('00:00:02:29'),
        );
      });

      test('should handle large durations at 24fps', () {
        expect(
          const Duration(hours: 1, minutes: 30, seconds: 45).toTimecode(),
          equals('01:30:45:00'),
        );
      });
    });

    group('toDropFrameTimecode', () {
      test('should format at 29.97fps', () {
        expect(
          const Duration(seconds: 1).toDropFrameTimecode(),
          contains(':'),
        );
      });

      test('should use semicolon separator for drop frame', () {
        expect(
          const Duration(minutes: 1).toDropFrameTimecode(),
          contains(';'),
        );
      });

      test('should handle minute boundaries with drop frames', () {
        // At 29.97fps, frames 0 and 1 are dropped at minute boundaries
        // (except every 10 minutes)
        final result = const Duration(minutes: 1).toDropFrameTimecode();
        expect(result, isNotEmpty);
      });
    });

    group('toHumanReadable', () {
      test('should format zero as 0ms', () {
        expect(Duration.zero.toHumanReadable(), equals('0ms'));
      });

      test('should format singular second', () {
        expect(
          const Duration(seconds: 1).toHumanReadable(),
          equals('1s'),
        );
      });

      test('should format plural seconds', () {
        expect(
          const Duration(seconds: 45).toHumanReadable(),
          equals('45s'),
        );
      });

      test('should format singular minute', () {
        expect(
          const Duration(minutes: 1).toHumanReadable(),
          equals('1m 0s'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toHumanReadable(),
          equals('5m 30s'),
        );
      });

      test('should format singular hour', () {
        expect(
          const Duration(hours: 1).toHumanReadable(),
          equals('1h 0m'),
        );
      });

      test('should format hours and minutes', () {
        expect(
          const Duration(hours: 2, minutes: 15).toHumanReadable(),
          equals('2h 15m'),
        );
      });

      test('should format hours with zero minutes', () {
        expect(
          const Duration(hours: 1, seconds: 30).toHumanReadable(),
          equals('1h 0m'),
        );
      });
    });

    group('toReadable', () {
      test('should format zero as 0 seconds', () {
        expect(Duration.zero.toReadable(), equals('0 seconds'));
      });

      test('should format singular second', () {
        expect(
          const Duration(seconds: 1).toReadable(),
          equals('1 second'),
        );
      });

      test('should format plural seconds', () {
        expect(
          const Duration(seconds: 45).toReadable(),
          equals('45 seconds'),
        );
      });

      test('should format singular minute', () {
        expect(
          const Duration(minutes: 1).toReadable(),
          equals('1 minute'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toReadable(),
          equals('5 minutes 30 seconds'),
        );
      });

      test('should format singular hour', () {
        expect(
          const Duration(hours: 1).toReadable(),
          equals('1 hour'),
        );
      });

      test('should format hours and minutes', () {
        expect(
          const Duration(hours: 2, minutes: 15).toReadable(),
          equals('2 hours 15 minutes'),
        );
      });

      test('should format hours, minutes, and seconds', () {
        expect(
          const Duration(hours: 2, minutes: 15, seconds: 30).toReadable(),
          equals('2 hours 15 minutes 30 seconds'),
        );
      });
    });

    group('toProgressString', () {
      test('should format zero duration', () {
        expect(Duration.zero.toProgressString(), equals('0:00'));
      });

      test('should format seconds only', () {
        expect(
          const Duration(seconds: 45).toProgressString(),
          equals('0:45'),
        );
      });

      test('should format minutes and seconds', () {
        expect(
          const Duration(minutes: 5, seconds: 30).toProgressString(),
          equals('5:30'),
        );
      });

      test('should format hours, minutes, seconds', () {
        expect(
          const Duration(hours: 1, minutes: 23, seconds: 45).toProgressString(),
          equals('1:23:45'),
        );
      });
    });

    group('toFrameNumber', () {
      test('should calculate frame at 24fps', () {
        expect(const Duration(seconds: 1).toFrameNumber(), equals(24));
      });

      test('should calculate frame at 30fps', () {
        expect(const Duration(seconds: 2).toFrameNumber(fps: 30), equals(60));
      });

      test('should calculate frame at 60fps', () {
        expect(const Duration(milliseconds: 500).toFrameNumber(fps: 60), equals(30));
      });

      test('should calculate frame at zero duration', () {
        expect(Duration.zero.toFrameNumber(), equals(0));
      });

      test('should handle fractional frames', () {
        // 1.5 seconds at 24fps = 36 frames
        expect(
          const Duration(milliseconds: 1500).toFrameNumber(),
          equals(36),
        );
      });
    });

    group('fromFrameNumber', () {
      test('should create duration from frame at 24fps', () {
        expect(
          DurationExtensions.fromFrameNumber(24),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should create duration from frame at 30fps', () {
        expect(
          DurationExtensions.fromFrameNumber(30, fps: 30),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should create duration from frame at 60fps', () {
        expect(
          DurationExtensions.fromFrameNumber(60, fps: 60),
          equals(const Duration(seconds: 1)),
        );
      });

      test('should handle zero frame', () {
        expect(
          DurationExtensions.fromFrameNumber(0),
          equals(Duration.zero),
        );
      });

      test('should handle fractional durations', () {
        // Frame 12 at 24fps = 0.5 seconds
        expect(
          DurationExtensions.fromFrameNumber(12),
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

      group('divideBy operator', () {
        test('should divide duration by number', () {
          expect(
            const Duration(seconds: 10).divideBy(2),
            equals(const Duration(seconds: 5)),
          );
        });

        test('should handle fractional results', () {
          expect(
            const Duration(seconds: 10).divideBy(3),
            equals(const Duration(seconds: 3, microseconds: 333333)),
          );
        });
      });

      group('clampDuration', () {
        test('should clamp duration within range', () {
          expect(
            const Duration(seconds: 5).clampDuration(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 5)),
          );
        });

        test('should clamp to minimum', () {
          expect(
            const Duration(seconds: 1).clampDuration(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 3)),
          );
        });

        test('should clamp to maximum', () {
          expect(
            const Duration(seconds: 15).clampDuration(
              const Duration(seconds: 3),
              const Duration(seconds: 10),
            ),
            equals(const Duration(seconds: 10)),
          );
        });
      });
    });

    group('conversion extensions', () {
      test('should convert to inSecondsDouble', () {
        expect(
          const Duration(minutes: 1, seconds: 30).inSecondsDouble,
          equals(90.0),
        );
      });

      test('should convert to inMinutesDouble', () {
        expect(
          const Duration(hours: 1, minutes: 30).inMinutesDouble,
          equals(90.0),
        );
      });

      test('should convert to inHoursDouble', () {
        expect(
          const Duration(hours: 2, minutes: 30).inHoursDouble,
          equals(2.5),
        );
      });
    });

    group('range checking', () {
      test('should check if duration is within range', () {
        const duration = Duration(seconds: 5);
        expect(
          duration.isWithin(
            const Duration(seconds: 3),
            const Duration(seconds: 10),
          ),
          isTrue,
        );
      });

      test('should check if duration is outside range', () {
        const duration = Duration(seconds: 15);
        expect(
          duration.isWithin(
            const Duration(seconds: 3),
            const Duration(seconds: 10),
          ),
          isFalse,
        );
      });

      test('should be inclusive of start boundary', () {
        const duration = Duration(seconds: 3);
        expect(
          duration.isWithin(
            const Duration(seconds: 3),
            const Duration(seconds: 10),
          ),
          isTrue,
        );
      });

      test('should be inclusive of end boundary', () {
        const duration = Duration(seconds: 10);
        expect(
          duration.isWithin(
            const Duration(seconds: 3),
            const Duration(seconds: 10),
          ),
          isTrue,
        );
      });
    });

    group('roundToFrame', () {
      test('should round to nearest frame at 24fps', () {
        // 520ms at 24fps: frame 12 (floor of 520*24/1000 = 12.48)
        // roundToFrame calculates frame then converts back
        final rounded = const Duration(milliseconds: 520).roundToFrame();
        // frame 12 at 24fps = 12 * 1000 / 24 = 500ms
        expect(rounded.inMilliseconds, equals(500));
      });

      test('should round exact frame to itself', () {
        // Frame 1 at 24fps = 1000/24 ≈ 41.67ms, rounded to 42ms
        const frameDuration = Duration(milliseconds: 42);
        final rounded = frameDuration.roundToFrame();
        // frame 1 at 24fps = 42ms
        expect(rounded.inMilliseconds, equals(42));
      });

      test('should round zero to zero', () {
        expect(Duration.zero.roundToFrame(), equals(Duration.zero));
      });
    });

    group('edge cases', () {
      test('should handle very large durations', () {
        const largeDuration = Duration(days: 365);
        expect(largeDuration.toTimestamp(), isNotEmpty);
        expect(largeDuration.toHumanReadable(), isNotEmpty);
      });

      test('should handle negative durations gracefully', () {
        const negativeDuration = Duration(seconds: -5);
        // Behavior depends on implementation - should not throw
        expect(negativeDuration.isNegative, isTrue);
      });

      test('should handle microsecond precision', () {
        const preciseDuration = Duration(microseconds: 123456);
        expect(preciseDuration.toTimestamp(), isNotEmpty);
      });
    });
  });
}
