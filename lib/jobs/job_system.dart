import 'dart:async';
import 'dart:collection';

import 'cancellation_token.dart';

/// Job state machine for long-running operations
enum JobState {
  queued,
  running,
  paused,
  cancelled,
  failed,
  completed,
}

/// Base class for jobs
abstract class Job<T> {
  final String id;
  final CancellationToken cancellationToken;
  final StreamController<JobProgress> _progressController =
      StreamController<JobProgress>.broadcast();

  JobState _state = JobState.queued;
  String? _errorMessage;
  T? _result;

  Job({
    required this.id,
    CancellationToken? cancellationToken,
  }) : cancellationToken = cancellationToken ?? CancellationToken();

  /// Current state of the job
  JobState get state => _state;

  /// Progress stream for the job
  Stream<JobProgress> get progress => _progressController.stream;

  /// Error message if job failed
  String? get errorMessage => _errorMessage;

  /// Result if job completed
  T? get result => _result;

  /// Run the job
  Future<T> run() async {
    if (_state != JobState.queued) {
      throw StateError('Job already started');
    }

    _state = JobState.running;
    _reportProgress(0.0, 'Starting');

    try {
      _result = await execute();
      _state = JobState.completed;
      _reportProgress(1.0, 'Completed');
      return _result as T;
    } on CancelledException {
      _state = JobState.cancelled;
      _reportProgress(0.0, 'Cancelled');
      rethrow;
    } catch (e) {
      _state = JobState.failed;
      _errorMessage = e.toString();
      _reportProgress(0.0, 'Failed: $e');
      rethrow;
    } finally {
      await _progressController.close();
    }
  }

  /// Execute the job logic
  Future<T> execute();

  /// Pause the job
  void pause() {
    if (_state == JobState.running) {
      _state = JobState.paused;
      cancellationToken.pause();
      _reportProgress(null, 'Paused');
    }
  }

  /// Resume the job
  void resume() {
    if (_state == JobState.paused) {
      _state = JobState.running;
      cancellationToken.resume();
      _reportProgress(null, 'Resumed');
    }
  }

  /// Cancel the job
  void cancel() {
    cancellationToken.cancel();
    _state = JobState.cancelled;
    _reportProgress(0.0, 'Cancelled');
  }

  /// Report progress
  void _reportProgress(double? progress, String message) {
    if (!_progressController.isClosed) {
      _progressController.add(JobProgress(
        jobId: id,
        state: _state,
        progress: progress,
        message: message,
      ));
    }
  }

  /// Report progress from subclass
  void reportProgress(double progress, String message) {
    _reportProgress(progress, message);
  }
}

/// Progress information for a job
class JobProgress {
  final String jobId;
  final JobState state;
  final double? progress;
  final String message;
  final DateTime timestamp;

  JobProgress({
    required this.jobId,
    required this.state,
    this.progress,
    required this.message,
  }) : timestamp = DateTime.now();
}

/// Queue for managing multiple jobs
class JobQueue {
  final Queue<Job<dynamic>> _queue = Queue();
  final Set<Job<dynamic>> _running = {};
  final int maxConcurrent;

  JobQueue({this.maxConcurrent = 1});

  /// Add a job to the queue
  void enqueue(Job<dynamic> job) {
    _queue.add(job);
    _processQueue();
  }

  /// Get all jobs in the queue
  List<Job<dynamic>> get pendingJobs => _queue.toList();

  /// Get all running jobs
  List<Job<dynamic>> get runningJobs => _running.toList();

  /// Cancel all jobs
  void cancelAll() {
    for (final job in _running) {
      job.cancel();
    }
    for (final job in _queue) {
      job.cancel();
    }
    _queue.clear();
  }

  void _processQueue() {
    while (_running.length < maxConcurrent && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _running.add(job);
      _runJob(job);
    }
  }

  Future<void> _runJob(Job<dynamic> job) async {
    try {
      await job.run();
    } catch (_) {
      // Error handling is done in the job
    } finally {
      _running.remove(job);
      _processQueue();
    }
  }
}
