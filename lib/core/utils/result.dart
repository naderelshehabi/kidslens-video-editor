/// A result type that represents either success or failure
sealed class Result<T, E> {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T, E>;

  /// Create a failure result
  factory Result.failure(E error) = Failure<T, E>;

  /// Whether this is a success
  bool get isSuccess => this is Success<T, E>;

  /// Whether this is a failure
  bool get isFailure => this is Failure<T, E>;

  /// Get the value if success, or null
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  /// Get the error if failure, or null
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// Map the success value
  Result<U, E> map<U>(U Function(T) mapper) => switch (this) {
    Success(:final value) => Result.success(mapper(value)),
    Failure(:final error) => Result.failure(error),
  };

  /// Map the error
  Result<T, F> mapError<F>(F Function(E) mapper) => switch (this) {
    Success(:final value) => Result.success(value),
    Failure(:final error) => Result.failure(mapper(error)),
  };

  /// Flat map the success value
  Result<U, E> flatMap<U>(Result<U, E> Function(T) mapper) => switch (this) {
    Success(:final value) => mapper(value),
    Failure(:final error) => Result.failure(error),
  };

  /// Get the value or throw the error
  T getOrThrow() => switch (this) {
    Success(:final value) => value,
    Failure(:final error) => throw error as Object,
  };

  /// Get the value or return a default
  T getOrElse(T Function() defaultValue) => switch (this) {
    Success(:final value) => value,
    Failure() => defaultValue(),
  };

  /// Execute a function based on the result
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error) => onFailure(error),
      };
}

/// Success result
class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      other is Success<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure result
class Failure<T, E> extends Result<T, E> {
  final E error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
