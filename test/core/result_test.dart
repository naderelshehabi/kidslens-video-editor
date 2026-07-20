import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success with value', () {
        const result = Success<int, String>(42);

        expect(result.value, equals(42));
      });

      test('should identify as success', () {
        const result = Success<int, String>(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('should return value from valueOrNull', () {
        const result = Success<int, String>(42);

        expect(result.valueOrNull, equals(42));
      });

      test('should return value from getOrElse', () {
        const result = Success<int, String>(42);

        expect(result.getOrElse(() => 0), equals(42));
      });

      test('should return value from getOrThrow', () {
        const result = Success<int, String>(42);

        expect(result.getOrThrow(), equals(42));
      });

      test('should return null from errorOrNull', () {
        const result = Success<int, String>(42);

        expect(result.errorOrNull, isNull);
      });

      test('should support equality', () {
        const r1 = Success<int, String>(42);
        const r2 = Success<int, String>(42);

        expect(r1, equals(r2));
      });

      test('should not equal different values', () {
        const r1 = Success<int, String>(42);
        const r2 = Success<int, String>(24);

        expect(r1, isNot(equals(r2)));
      });
    });

    group('Failure', () {
      test('should create failure with error', () {
        const result = Failure<int, String>('Error occurred');

        expect(result.error, equals('Error occurred'));
      });

      test('should identify as failure', () {
        const result = Failure<int, String>('Error');

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('should return null from valueOrNull', () {
        const result = Failure<int, String>('Error');

        expect(result.valueOrNull, isNull);
      });

      test('should return default from getOrElse', () {
        const result = Failure<int, String>('Error');

        expect(result.getOrElse(() => 0), equals(0));
      });

      test('should throw from getOrThrow', () {
        const result = Failure<int, String>('Error');

        expect(result.getOrThrow, throwsA(equals('Error')));
      });

      test('should return error from errorOrNull', () {
        const result = Failure<int, String>('Error');

        expect(result.errorOrNull, equals('Error'));
      });

      test('should support equality', () {
        const r1 = Failure<int, String>('Error');
        const r2 = Failure<int, String>('Error');

        expect(r1, equals(r2));
      });

      test('should not equal different errors', () {
        const r1 = Failure<int, String>('Error 1');
        const r2 = Failure<int, String>('Error 2');

        expect(r1, isNot(equals(r2)));
      });
    });

    group('map', () {
      test('should transform success value', () {
        const result = Success<int, String>(42);
        final mapped = result.map((v) => v * 2);

        expect(mapped.valueOrNull, equals(84));
      });

      test('should preserve failure', () {
        const result = Failure<int, String>('Error');
        final mapped = result.map((v) => v * 2);

        expect(mapped.errorOrNull, equals('Error'));
      });

      test('should change value type', () {
        const result = Success<int, String>(42);
        final mapped = result.map((v) => v.toString());

        expect(mapped.valueOrNull, equals('42'));
      });
    });

    group('mapError', () {
      test('should transform failure error', () {
        const result = Failure<int, String>('Error');
        final mapped = result.mapError((e) => 'Wrapped: $e');

        expect(mapped.errorOrNull, equals('Wrapped: Error'));
      });

      test('should preserve success', () {
        const result = Success<int, String>(42);
        final mapped = result.mapError((e) => 'Wrapped: $e');

        expect(mapped.valueOrNull, equals(42));
      });

      test('should change error type', () {
        const result = Failure<int, String>('Error');
        final mapped = result.mapError(Exception.new);

        expect(mapped.errorOrNull, isA<Exception>());
      });
    });

    group('flatMap', () {
      test('should chain successful operations', () {
        const result = Success<int, String>(42);
        final chained = result.flatMap((v) => Success(v * 2));

        expect(chained.valueOrNull, equals(84));
      });

      test('should short-circuit on initial failure', () {
        const result = Failure<int, String>('Initial error');
        final chained = result.flatMap((v) => Success(v * 2));

        expect(chained.errorOrNull, equals('Initial error'));
      });

      test('should propagate failure from chain', () {
        const result = Success<int, String>(42);
        final chained =
            result.flatMap<int>((v) => const Failure('Chain error'));

        expect(chained.errorOrNull, equals('Chain error'));
      });

      test('should support multiple chain operations', () {
        const result = Success<int, String>(10);
        final chained = result
            .flatMap((v) => Success(v + 5))
            .flatMap((v) => Success(v * 2));

        expect(chained.valueOrNull, equals(30));
      });
    });

    group('fold', () {
      test('should call onSuccess for success', () {
        const result = Success<int, String>(42);
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );

        expect(folded, equals('Value: 42'));
      });

      test('should call onFailure for failure', () {
        const result = Failure<int, String>('Error');
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );

        expect(folded, equals('Error: Error'));
      });

      test('should return same type from both branches', () {
        const successResult = Success<int, String>(42);
        const failureResult = Failure<int, String>('Error');

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

    group('Pattern matching', () {
      test('should pattern match on Success', () {
        const result = Success<int, String>(42);

        final value = switch (result) {
          Success(:final value) => value,
        };

        expect(value, equals(42));
      });

      test('should pattern match on Failure', () {
        const result = Failure<int, String>('Error');

        final message = switch (result) {
          Success(:final value) => 'Success: $value',
          Failure(:final error) => 'Failure: $error',
        };

        expect(message, equals('Failure: Error'));
      });

      test('should pattern match with when clause', () {
        // Use a helper to avoid dead code warning from static type analysis
        String categorize(Result<int, String> result) => switch (result) {
              Success(value: final v) when v > 50 => 'large',
              Success(value: final v) when v > 0 => 'positive',
              Success() => 'zero or negative',
              Failure() => 'error',
            };

        const result = Success<int, String>(42);
        expect(categorize(result), equals('positive'));
      });
    });

    group('Factory constructors', () {
      test('Result.success should create Success', () {
        final result = Result<int, String>.success(42);

        expect(result, isA<Success<int, String>>());
        expect(result.valueOrNull, equals(42));
      });

      test('Result.failure should create Failure', () {
        final result = Result<int, String>.failure('Error');

        expect(result, isA<Failure<int, String>>());
        expect(result.errorOrNull, equals('Error'));
      });
    });

    group('Edge cases', () {
      test('should handle null success value', () {
        const result = Success<int?, String>(null);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isNull);
      });

      test('should handle complex types', () {
        const result = Success<List<Map<String, int>>, Exception>([
          {'a': 1},
          {'b': 2},
        ]);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, hasLength(2));
      });

      test('should handle void success', () {
        const result = Success<void, String>(null);

        expect(result.isSuccess, isTrue);
      });
    });
  });
}
