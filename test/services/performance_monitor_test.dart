import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/performance_monitor.dart';

void main() {
  late PerformanceMonitor monitor;

  setUp(() {
    // Reset the singleton before each test
    PerformanceMonitor.reset();
    monitor = PerformanceMonitor.instance();
  });

  tearDown(PerformanceMonitor.reset);

  group('PerformanceMonitor', () {
    group('singleton', () {
      test('should return same instance', () {
        final instance1 = PerformanceMonitor.instance();
        final instance2 = PerformanceMonitor.instance();

        expect(identical(instance1, instance2), isTrue);
      });

      test('should create new instance after reset', () {
        final instance1 = PerformanceMonitor.instance()
          ..recordTiming('test', const Duration(milliseconds: 100));

        PerformanceMonitor.reset();

        final instance2 = PerformanceMonitor.instance();
        expect(instance2.getAverageTiming('test'), isNull);
        // Use instance1 to avoid unused_local_variable warning
        expect(instance1, isNotNull);
      });
    });

    group('recordTiming()', () {
      test('should store timing for new operation', () {
        monitor.recordTiming(
          'test_operation',
          const Duration(milliseconds: 100),
        );

        final average = monitor.getAverageTiming('test_operation');
        expect(average, isNotNull);
        expect(average, equals(const Duration(milliseconds: 100)));
      });

      test('should store multiple timings for same operation', () {
        monitor
          ..recordTiming('test_operation', const Duration(milliseconds: 100))
          ..recordTiming('test_operation', const Duration(milliseconds: 200))
          ..recordTiming('test_operation', const Duration(milliseconds: 300));

        final stats = monitor.getStats('test_operation');
        expect(stats, isNotNull);
        expect(stats!.count, equals(3));
      });

      test('should track operations independently', () {
        monitor
          ..recordTiming('operation_a', const Duration(milliseconds: 100))
          ..recordTiming('operation_b', const Duration(milliseconds: 200));

        expect(
          monitor.getAverageTiming('operation_a'),
          equals(const Duration(milliseconds: 100)),
        );
        expect(
          monitor.getAverageTiming('operation_b'),
          equals(const Duration(milliseconds: 200)),
        );
      });
    });

    group('getAverageTiming()', () {
      test('should return correct average for single timing', () {
        monitor.recordTiming('test', const Duration(milliseconds: 500));

        final average = monitor.getAverageTiming('test');
        expect(average, equals(const Duration(milliseconds: 500)));
      });

      test('should return correct average for multiple timings', () {
        monitor
          ..recordTiming('test', const Duration(milliseconds: 100))
          ..recordTiming('test', const Duration(milliseconds: 200))
          ..recordTiming('test', const Duration(milliseconds: 300));

        final average = monitor.getAverageTiming('test');
        // (100 + 200 + 300) / 3 = 200
        expect(average, equals(const Duration(milliseconds: 200)));
      });

      test('should return null for unknown operation', () {
        final average = monitor.getAverageTiming('unknown_operation');

        expect(average, isNull);
      });

      test('should return null for empty string operation', () {
        final average = monitor.getAverageTiming('');

        expect(average, isNull);
      });
    });

    group('getRecommendedTier()', () {
      test('should return valid tier', () {
        final tier = monitor.getRecommendedTier();

        expect(tier, isIn(ModelTier.values));
      });

      test('should return medium tier when no data recorded', () {
        final tier = monitor.getRecommendedTier();

        expect(tier, equals(ModelTier.medium));
      });

      test('should return high tier for fast frame inference', () {
        // Record fast timings
        for (var i = 0; i < 10; i++) {
          monitor.recordTiming(
            'frame_inference',
            const Duration(milliseconds: 30),
          );
        }

        final tier = monitor.getRecommendedTier();
        expect(tier, equals(ModelTier.high));
      });

      test('should return low tier for slow frame inference', () {
        // Record slow timings
        for (var i = 0; i < 10; i++) {
          monitor.recordTiming(
            'frame_inference',
            const Duration(milliseconds: 500),
          );
        }

        final tier = monitor.getRecommendedTier();
        expect(tier, equals(ModelTier.low));
      });

      test('should return medium tier for moderate performance', () {
        // Record medium-speed timings
        for (var i = 0; i < 10; i++) {
          monitor.recordTiming(
            'frame_inference',
            const Duration(milliseconds: 100),
          );
        }

        final tier = monitor.getRecommendedTier();
        expect(tier, equals(ModelTier.medium));
      });
    });

    group('clear()', () {
      test('should remove all recorded data', () {
        monitor
          ..recordTiming('operation_a', const Duration(milliseconds: 100))
          ..recordTiming('operation_b', const Duration(milliseconds: 200))
          ..clear();

        expect(monitor.getAverageTiming('operation_a'), isNull);
        expect(monitor.getAverageTiming('operation_b'), isNull);
        expect(monitor.operations, isEmpty);
      });

      test('should reset tier recommendation after clear', () {
        // Record some fast timings
        for (var i = 0; i < 10; i++) {
          monitor.recordTiming(
            'frame_inference',
            const Duration(milliseconds: 30),
          );
        }

        monitor.clear();

        // Should return default medium tier
        final tier = monitor.getRecommendedTier();
        expect(tier, equals(ModelTier.medium));
      });
    });

    group('getStats()', () {
      test('should return null for unknown operation', () {
        final stats = monitor.getStats('unknown');

        expect(stats, isNull);
      });

      test('should return OperationStats with correct values', () {
        monitor
          ..recordTiming('test', const Duration(milliseconds: 100))
          ..recordTiming('test', const Duration(milliseconds: 200))
          ..recordTiming('test', const Duration(milliseconds: 300));

        final stats = monitor.getStats('test');

        expect(stats, isNotNull);
        expect(stats!.count, equals(3));
        expect(stats.minimum, equals(const Duration(milliseconds: 100)));
        expect(stats.maximum, equals(const Duration(milliseconds: 300)));
        expect(stats.average, equals(const Duration(milliseconds: 200)));
      });
    });

    group('operations', () {
      test('should return empty list when no timings recorded', () {
        expect(monitor.operations, isEmpty);
      });

      test('should return list of all recorded operation names', () {
        monitor
          ..recordTiming('op1', const Duration(milliseconds: 100))
          ..recordTiming('op2', const Duration(milliseconds: 200))
          ..recordTiming('op3', const Duration(milliseconds: 300));

        final ops = monitor.operations;

        expect(ops, hasLength(3));
        expect(ops, contains('op1'));
        expect(ops, contains('op2'));
        expect(ops, contains('op3'));
      });
    });

    group('startTiming()', () {
      test('should record timing when stop function called', () async {
        final stop = monitor.startTiming('async_operation');

        // Simulate some work
        await Future<void>.delayed(const Duration(milliseconds: 50));

        stop();

        final average = monitor.getAverageTiming('async_operation');
        expect(average, isNotNull);
        expect(average!.inMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    group('timeAsync()', () {
      test('should record timing for async operation', () async {
        await monitor.timeAsync('async_test', () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final average = monitor.getAverageTiming('async_test');
        expect(average, isNotNull);
        expect(average!.inMilliseconds, greaterThanOrEqualTo(40));
      });

      test('should return result from async operation', () async {
        final result = await monitor.timeAsync('async_result', () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 42;
        });

        expect(result, equals(42));
      });

      test('should record timing even if operation throws', () async {
        try {
          await monitor.timeAsync('async_error', () async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            throw Exception('Test error');
          });
        } catch (_) {
          // Expected
        }

        final average = monitor.getAverageTiming('async_error');
        expect(average, isNotNull);
      });
    });

    group('getSummary()', () {
      test('should return summary with recommended tier', () {
        final summary = monitor.getSummary();

        expect(summary, containsPair('recommendedTier', isNotNull));
      });

      test('should include all operations in summary', () {
        monitor
          ..recordTiming('op1', const Duration(milliseconds: 100))
          ..recordTiming('op2', const Duration(milliseconds: 200));

        final summary = monitor.getSummary();
        final operations = summary['operations'] as Map<String, dynamic>;

        expect(operations.containsKey('op1'), isTrue);
        expect(operations.containsKey('op2'), isTrue);
      });
    });

    group('OperationStats', () {
      test('should calculate percentiles correctly', () {
        // Record 100 timings from 1ms to 100ms
        for (var i = 1; i <= 100; i++) {
          monitor.recordTiming('percentile_test', Duration(milliseconds: i));
        }

        final stats = monitor.getStats('percentile_test')!;

        // P50 should be around 50ms
        expect(stats.p50.inMilliseconds, closeTo(50, 2));

        // P95 should be around 95ms
        expect(stats.p95.inMilliseconds, closeTo(95, 2));

        // P99 should be around 99ms
        expect(stats.p99.inMilliseconds, closeTo(99, 2));
      });

      test('should clear recordings', () {
        monitor.recordTiming('clear_test', const Duration(milliseconds: 100));
        final stats = monitor.getStats('clear_test')!;

        expect(stats.count, equals(1));

        stats.clear();

        expect(stats.count, equals(0));
        expect(stats.average, equals(Duration.zero));
      });
    });
  });

  group('ModelTier enum', () {
    test('should have expected values', () {
      expect(ModelTier.values, hasLength(3));
      expect(ModelTier.values, contains(ModelTier.low));
      expect(ModelTier.values, contains(ModelTier.medium));
      expect(ModelTier.values, contains(ModelTier.high));
    });

    test('should have correct ordering', () {
      expect(ModelTier.low.index, lessThan(ModelTier.medium.index));
      expect(ModelTier.medium.index, lessThan(ModelTier.high.index));
    });
  });
}
