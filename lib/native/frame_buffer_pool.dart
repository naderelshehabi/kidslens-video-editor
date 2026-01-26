import 'dart:async';
import 'dart:collection';

import '../services/media_service.dart';

/// Memory-bounded frame buffer for video analysis
class FrameBufferPool {
  static const int maxFrames4K = 30; // ~750MB for 4K
  static const int maxFramesHD = 60; // ~120MB for 1080p
  static const int maxFramesSD = 120; // ~30MB for 480p

  final Queue<PooledFrame> _available = Queue();
  final Set<PooledFrame> _inUse = {};
  final Queue<Completer<PooledFrame>> _waiters = Queue();
  final int _maxFrames;
  final int _frameSize;

  int _allocatedCount = 0;

  FrameBufferPool({
    required Resolution resolution,
  })  : _maxFrames = _calculateMaxFrames(resolution),
        _frameSize = resolution.width * resolution.height * 3;

  static int _calculateMaxFrames(Resolution res) {
    final pixels = res.width * res.height;
    if (pixels > 3840 * 2160) return maxFrames4K; // 4K+
    if (pixels > 1920 * 1080) return maxFramesHD; // 1080p+
    return maxFramesSD; // SD
  }

  /// Get the maximum number of frames in the pool
  int get maxFrames => _maxFrames;

  /// Get the current number of allocated frames
  int get allocatedFrames => _allocatedCount;

  /// Get the number of available frames
  int get availableFrames => _available.length;

  /// Get the number of frames in use
  int get inUseFrames => _inUse.length;

  /// Acquire a frame buffer, waiting if pool is exhausted (backpressure)
  Future<PooledFrame> acquire({Duration? timeout}) async {
    // Try to get an available frame
    if (_available.isNotEmpty) {
      final frame = _available.removeFirst();
      _inUse.add(frame);
      return frame;
    }

    // Try to allocate a new frame if under limit
    if (_allocatedCount < _maxFrames) {
      final frame = PooledFrame(
        id: _allocatedCount,
        data: List.filled(_frameSize, 0),
        pool: this,
      );
      _allocatedCount++;
      _inUse.add(frame);
      return frame;
    }

    // Wait for a frame to be released (backpressure)
    final completer = Completer<PooledFrame>();
    _waiters.add(completer);

    if (timeout != null) {
      return completer.future.timeout(
        timeout,
        onTimeout: () {
          _waiters.remove(completer);
          throw FrameBufferTimeoutException(
            'Timeout waiting for frame buffer after $timeout',
          );
        },
      );
    }

    return completer.future;
  }

  /// Release a frame back to the pool
  void release(PooledFrame frame) {
    if (!_inUse.remove(frame)) return;

    // If someone is waiting, give them the frame directly
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeFirst();
      _inUse.add(frame);
      waiter.complete(frame);
      return;
    }

    // Otherwise, add to available pool
    _available.add(frame);
  }

  /// Memory pressure handler - shrink pool
  Future<void> handleMemoryPressure() async {
    // Release half of available frames
    final toRelease = _available.length ~/ 2;
    for (var i = 0; i < toRelease; i++) {
      if (_available.isNotEmpty) {
        _available.removeFirst();
        _allocatedCount--;
      }
    }
  }

  /// Clear all frames from the pool
  void clear() {
    _available.clear();
    _inUse.clear();
    _allocatedCount = 0;

    // Cancel all waiters
    while (_waiters.isNotEmpty) {
      final waiter = _waiters.removeFirst();
      waiter.completeError(
        FrameBufferDisposedException('Frame buffer pool was disposed'),
      );
    }
  }
}

/// A pooled frame buffer
class PooledFrame {
  final int id;
  final List<int> data;
  final FrameBufferPool pool;

  int width = 0;
  int height = 0;
  int frameNumber = 0;
  Duration timestamp = Duration.zero;

  PooledFrame({
    required this.id,
    required this.data,
    required this.pool,
  });

  /// Release this frame back to the pool
  void release() {
    pool.release(this);
  }
}

/// Exception thrown when frame buffer acquisition times out
class FrameBufferTimeoutException implements Exception {
  final String message;
  FrameBufferTimeoutException(this.message);

  @override
  String toString() => 'FrameBufferTimeoutException: $message';
}

/// Exception thrown when frame buffer pool is disposed
class FrameBufferDisposedException implements Exception {
  final String message;
  FrameBufferDisposedException(this.message);

  @override
  String toString() => 'FrameBufferDisposedException: $message';
}
