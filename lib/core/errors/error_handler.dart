import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kidslens_video_editor/core/errors/app_exceptions.dart';

/// Error handler with retry logic and logging
class ErrorHandler {
  ErrorHandler({
    this.onLog,
    this.onError,
  });

  static const int defaultMaxRetries = 3;
  static const Duration defaultRetryDelay = Duration(seconds: 2);

  final void Function(String message, {Object? error, StackTrace? stackTrace})?
      onLog;
  final void Function(KidsLensException exception)? onError;

  /// Execute an operation with retry logic
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration retryDelay = defaultRetryDelay,
    bool Function(Exception)? shouldRetry,
  }) async {
    var attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;
        attempt++;

        final canRetry = shouldRetry?.call(e) ??
            (e is KidsLensException && e.isRetryable);

        if (!canRetry || attempt >= maxRetries) {
          _logError('Operation failed after $attempt attempts', e);
          rethrow;
        }

        _log('Retrying operation (attempt ${attempt + 1}/$maxRetries)');
        await Future<void>.delayed(retryDelay * attempt);
      }
    }

    throw lastException!;
  }

  /// Handle an exception and return a user-friendly result
  ErrorResult handleException(Object error, [StackTrace? stackTrace]) {
    _logError('Handling exception', error, stackTrace);

    if (error is KidsLensException) {
      onError?.call(error);
      return ErrorResult(
        userMessage: error.userMessage,
        remediation: error.remediation,
        isRetryable: error.isRetryable,
        originalError: error,
      );
    }

    // Handle other common exceptions
    if (error is TimeoutException) {
      return ErrorResult(
        userMessage: 'The operation timed out.',
        remediation: 'Please try again.',
        isRetryable: true,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return ErrorResult(
        userMessage: 'Invalid data format.',
        remediation: 'The file may be corrupted.',
        isRetryable: false,
        originalError: error,
      );
    }

    // Generic error
    return ErrorResult(
      userMessage: 'An unexpected error occurred.',
      remediation: 'Please try again or restart the application.',
      isRetryable: true,
      originalError: error,
    );
  }

  /// Run a guarded operation with error handling
  Future<T?> guard<T>(
    Future<T> Function() operation, {
    T? fallback,
    void Function(ErrorResult)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      final result = handleException(e, st);
      onError?.call(result);
      return fallback;
    }
  }

  void _log(String message) {
    if (onLog != null) {
      onLog!(message);
    } else if (kDebugMode) {
      debugPrint('[KidsLens] $message');
    }
  }

  void _logError(String message, Object error, [StackTrace? stackTrace]) {
    if (onLog != null) {
      onLog!(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      debugPrint('[KidsLens ERROR] $message: $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}

/// Result of error handling
class ErrorResult {
  const ErrorResult({
    required this.userMessage,
    required this.remediation,
    required this.isRetryable,
    required this.originalError,
  });

  final String userMessage;
  final String remediation;
  final bool isRetryable;
  final Object originalError;
}

/// Global error handler instance
final errorHandler = ErrorHandler();
