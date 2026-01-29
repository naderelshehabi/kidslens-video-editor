import 'dart:async';

/// Cooperative cancellation token for long-running operations
class CancellationToken {
  bool _isCancelled = false;
  bool _isPaused = false;
  final Completer<void> _cancelledCompleter = Completer<void>();
  final List<void Function()> _callbacks = [];
  final List<void Function()> _pauseCallbacks = [];
  final List<void Function()> _resumeCallbacks = [];

  /// Whether the token has been cancelled
  bool get isCancelled => _isCancelled;

  /// Whether the token is paused
  bool get isPaused => _isPaused;

  /// Future that completes when the token is cancelled
  Future<void> get cancelled => _cancelledCompleter.future;

  /// Cancel the operation
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _cancelledCompleter.complete();
    for (final callback in _callbacks) {
      callback();
    }
    _callbacks.clear();
  }

  /// Pause the operation
  void pause() {
    if (_isPaused || _isCancelled) return;
    _isPaused = true;
    for (final callback in _pauseCallbacks) {
      callback();
    }
  }

  /// Resume the operation
  void resume() {
    if (!_isPaused || _isCancelled) return;
    _isPaused = false;
    for (final callback in _resumeCallbacks) {
      callback();
    }
  }

  /// Register a callback to be called when cancelled
  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
      return;
    }
    _callbacks.add(callback);
  }

  /// Register a callback to be called when paused
  void onPause(void Function() callback) {
    _pauseCallbacks.add(callback);
  }

  /// Register a callback to be called when resumed
  void onResume(void Function() callback) {
    _resumeCallbacks.add(callback);
  }

  /// Throw if cancelled
  void throwIfCancelled() {
    if (_isCancelled) throw CancelledException();
  }

  /// Wait while paused, throw if cancelled
  Future<void> waitWhilePaused() async {
    while (_isPaused && !_isCancelled) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throwIfCancelled();
  }

  /// Check cancellation and pause state
  Future<void> checkState() async {
    throwIfCancelled();
    await waitWhilePaused();
  }
}

/// Exception thrown when an operation is cancelled
class CancelledException implements Exception {
  CancelledException([this.message = 'Operation was cancelled']);

  final String message;

  @override
  String toString() => 'CancelledException: $message';
}
