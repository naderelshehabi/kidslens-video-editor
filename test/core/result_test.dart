import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success with value', () {
        final result = Success<int, String>(42);

        expect(result.value, equals(42));
      });

      test('should identify as success', () {
        final result = Success<int, String>(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('should return value from getOrNull', () {
        final result = Success<int, String>(42);

        expect(result.getOrNull(), equals(42));
      });

      test('should return value from getOrElse', () {
        final result = Success<int, String>(42);

        expect(result.getOrElse(() => 0), equals(42));
      });

      test('should return value from getOrThrow', () {
        final result = Success<int, String>(42);

        expect(result.getOrThrow(), equals(42));
      });

      test('should return null from errorOrNull', () {
        final result = Success<int, String>(42);

        expect(result.errorOrNull(), isNull);
      });

      test('should support equality', () {
        final r1 = Success<int, String>(42);
        final r2 = Success<int, String>(42);

        expect(r1, equals(r2));
      });

      test('should not equal different values', () {
        final r1 = Success<int, String>(42);
        final r2 = Success<int, String>(24);

        expect(r1, isNot(equals(r2)));
      });
    });

    group('Failure', () {
      test('should create failure with error', () {
        final result = Failure<int, String>('Error occurred');

        expect(result.error, equals('Error occurred'));
      });

      test('should identify as failure', () {
        final result = Failure<int, String>('Error');

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('should return null from getOrNull', () {
        final result = Failure<int, String>('Error');

        expect(result.getOrNull(), isNull);
      });

      test('should return default from getOrElse', () {
        final result = Failure<int, String>('Error');

        expect(result.getOrElse(() => 0), equals(0));
      });

      test('should throw from getOrThrow', () {
        final result = Failure<int, String>('Error');

        expect(() => result.getOrThrow(), throwsA(equals('Error')));
      });

      test('should return error from errorOrNull', () {
        final result = Failure<int, String>('Error');

        expect(result.errorOrNull(), equals('Error'));
      });

      test('should support equality', () {
        final r1 = Failure<int, String>('Error');
        final r2 = Failure<int, String>('Error');

        expect(r1, equals(r2));
      });

      test('should not equal different errors', () {
        final r1 = Failure<int, String>('Error 1');
        final r2 = Failure<int, String>('Error 2');

        expect(r1, isNot(equals(r2)));
      });
    });

    group('map', () {
      test('should transform success value', () {
        final result = Success<int, String>(42);
        final mapped = result.map((v) => v * 2);

        expect(mapped.getOrNull(), equals(84));
      });

      test('should preserve failure', () {
        final result = Failure<int, String>('Error');
        final mapped = result.map((v) => v * 2);

        expect(mapped.errorOrNull(), equals('Error'));
      });

      test('should change value type', () {
        final result = Success<int, String>(42);
        final mapped = result.map((v) => v.toString());

        expect(mapped.getOrNull(), equals('42'));
      });
    });

    group('mapError', () {
      test('should transform failure error', () {
        final result = Failure<int, String>('Error');
        final mapped = result.mapError((e) => 'Wrapped: $e');

        expect(mapped.errorOrNull(), equals('Wrapped: Error'));
      });

      test('should preserve success', () {
        final result = Success<int, String>(42);
        final mapped = result.mapError((e) => 'Wrapped: $e');

        expect(mapped.getOrNull(), equals(42));
      });

      test('should change error type', () {
        final result = Failure<int, String>('Error');
        final mapped = result.mapError((e) => Exception(e));

        expect(mapped.errorOrNull(), isA<Exception>());
      });
    });

    group('flatMap', () {
      test('should chain successful operations', () {
        final result = Success<int, String>(42);
        final chained = result.flatMap((v) => Success(v * 2));

        expect(chained.getOrNull(), equals(84));
      });

      test('should short-circuit on initial failure', () {
        final result = Failure<int, String>('Initial error');
        final chained = result.flatMap((v) => Success(v * 2));

        expect(chained.errorOrNull(), equals('Initial error'));
      });

      test('should propagate failure from chain', () {
        final result = Success<int, String>(42);
        final chained = result.flatMap<int>((v) => Failure('Chain error'));

        expect(chained.errorOrNull(), equals('Chain error'));
      });

      test('should support multiple chain operations', () {
        final result = Success<int, String>(10);
        final chained = result
            .flatMap((v) => Success(v + 5))
            .flatMap((v) => Success(v * 2));

        expect(chained.getOrNull(), equals(30));
      });
    });

    group('fold', () {
      test('should call onSuccess for success', () {
        final result = Success<int, String>(42);
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );

        expect(folded, equals('Value: 42'));
      });

      test('should call onFailure for failure', () {
        final result = Failure<int, String>('Error');
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );

        expect(folded, equals('Error: Error'));
      });

      test('should return same type from both branches', () {
        final successResult = Success<int, String>(42);
        final failureResult = Failure<int, String>('Error');

        final foldedSuccess = successResult.fold(
          onSuccess: (v) => v * 2,
          onFailure: (_) => 0,
        );

        final foldedFailure = failureResult.fold(
          onSuccess: (v) => v * 2,
          onFailure: (_) => 0,
        );

        expect(foldedSuccess, equals(84));
        expect(foldedFailure, equals(0));
      });
    });

    group('when', () {
      test('should execute success callback', () {
        var successCalled = false;
        var failureCalled = false;

        final result = Success<int, String>(42);
        result.when(
          success: (v) => successCalled = true,
          failure: (e) => failureCalled = true,
        );

        expect(successCalled, isTrue);
        expect(failureCalled, isFalse);
      });

      test('should execute failure callback', () {
        var successCalled = false;
        var failureCalled = false;

        final result = Failure<int, String>('Error');
        result.when(
          success: (v) => successCalled = true,
          failure: (e) => failureCalled = true,
        );

        expect(successCalled, isFalse);
        expect(failureCalled, isTrue);
      });
    });

    group('whenOrNull', () {
      test('should execute only matching callback', () {
        final result = Success<int, String>(42);
        var value = 0;

        result.whenOrNull(
          success: (v) => value = v,
        );

        expect(value, equals(42));
      });

      test('should not execute unmatched callback', () {
        final result = Failure<int, String>('Error');
        var value = 0;

        result.whenOrNull(
          success: (v) => value = v,
        );

        expect(value, equals(0));
      });
    });

    group('recover', () {
      test('should recover from failure', () {
        final result = Failure<int, String>('Error');
        final recovered = result.recover((e) => 0);

        expect(recovered.getOrNull(), equals(0));
        expect(recovered.isSuccess, isTrue);
      });

      test('should preserve success', () {
        final result = Success<int, String>(42);
        final recovered = result.recover((e) => 0);

        expect(recovered.getOrNull(), equals(42));
      });
    });

    group('recoverWith', () {
      test('should recover with new Result', () {
        final result = Failure<int, String>('Error');
        final recovered = result.recoverWith((e) => Success(0));

        expect(recovered.getOrNull(), equals(0));
      });

      test('should chain recovery failures', () {
        final result = Failure<int, String>('Error');
        final recovered = result.recoverWith((e) => Failure('Still failed'));

        expect(recovered.errorOrNull(), equals('Still failed'));
      });
    });

    group('combine', () {
      test('should combine two successes', () {
        final r1 = Success<int, String>(10);
        final r2 = Success<int, String>(20);

        final combined = r1.combine(r2, (a, b) => a + b);

        expect(combined.getOrNull(), equals(30));
      });

      test('should fail if first fails', () {
        final r1 = Failure<int, String>('First error');
        final r2 = Success<int, String>(20);

        final combined = r1.combine(r2, (a, b) => a + b);

        expect(combined.errorOrNull(), equals('First error'));
      });

      test('should fail if second fails', () {
        final r1 = Success<int, String>(10);
        final r2 = Failure<int, String>('Second error');

        final combined = r1.combine(r2, (a, b) => a + b);

        expect(combined.errorOrNull(), equals('Second error'));
      });
    });

    group('Pattern matching', () {
      test('should pattern match on Success', () {
        final result = Success<int, String>(42);

        final value = switch (result) {
          Success(:final value) => value,
          Failure(:final error) => throw error,
        };

        expect(value, equals(42));
      });

      test('should pattern match on Failure', () {
        final result = Failure<int, String>('Error');

        final message = switch (result) {
          Success(:final value) => 'Success: $value',
          Failure(:final error) => 'Failure: $error',
        };

        expect(message, equals('Failure: Error'));
      });

      test('should pattern match with when clause', () {
        final result = Success<int, String>(42);

        final category = switch (result) {
          Success(value: final v) when v > 50 => 'large',
          Success(value: final v) when v > 0 => 'positive',
          Success() => 'zero or negative',
          Failure() => 'error',
        };

        expect(category, equals('positive'));
      });
    });

    group('Factory constructors', () {
      test('Result.success should create Success', () {
        final result = Result<int, String>.success(42);

        expect(result, isA<Success<int, String>>());
        expect(result.getOrNull(), equals(42));
      });

      test('Result.failure should create Failure', () {
        final result = Result<int, String>.failure('Error');

        expect(result, isA<Failure<int, String>>());
        expect(result.errorOrNull(), equals('Error'));
      });

      test('Result.guard should catch exceptions', () {
        final result = Result.guard<int, Exception>(
          () => throw Exception('Test error'),
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull(), isA<Exception>());
      });

      test('Result.guard should return success on no exception', () {
        final result = Result.guard<int, Exception>(() => 42);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42));
      });
    });

    group('async extensions', () {
      test('mapAsync should transform success asynchronously', () async {
        final result = Success<int, String>(42);
        final mapped = await result.mapAsync((v) async => v * 2);

        expect(mapped.getOrNull(), equals(84));
      });

      test('mapAsync should preserve failure', () async {
        final result = Failure<int, String>('Error');
        final mapped = await result.mapAsync((v) async => v * 2);

        expect(mapped.errorOrNull(), equals('Error'));
      });

      test('flatMapAsync should chain async operations', () async {
        final result = Success<int, String>(42);
        final chained = await result.flatMapAsync((v) async => Success(v * 2));

        expect(chained.getOrNull(), equals(84));
      });
    });

    group('List extensions', () {
      test('sequence should combine list of successes', () {
        final results = [
          Success<int, String>(1),
          Success<int, String>(2),
          Success<int, String>(3),
        ];

        final sequenced = results.sequence();

        expect(sequenced.isSuccess, isTrue);
        expect(sequenced.getOrNull(), equals([1, 2, 3]));
      });

      test('sequence should fail on first failure', () {
        final results = [
          Success<int, String>(1),
          Failure<int, String>('Error'),
          Success<int, String>(3),
        ];

        final sequenced = results.sequence();

        expect(sequenced.isFailure, isTrue);
        expect(sequenced.errorOrNull(), equals('Error'));
      });

      test('partition should separate successes and failures', () {
        final results = [
          Success<int, String>(1),
          Failure<int, String>('Error 1'),
          Success<int, String>(2),
          Failure<int, String>('Error 2'),
        ];

        final (successes, failures) = results.partition();

        expect(successes, equals([1, 2]));
        expect(failures, equals(['Error 1', 'Error 2']));
      });
    });

    group('Edge cases', () {
      test('should handle null success value', () {
        final result = Success<int?, String>(null);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('should handle complex types', () {
        final result = Success<List<Map<String, int>>, Exception>([
          {'a': 1},
          {'b': 2},
        ]);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), hasLength(2));
      });

      test('should handle void success', () {
        final result = Success<void, String>(null);

        expect(result.isSuccess, isTrue);
      });
    });
  });
}
