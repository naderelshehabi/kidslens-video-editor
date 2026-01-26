import 'package:kidslens_video_editor/data/models/gpu_info.dart';

/// Base class for all KidsLens exceptions
sealed class KidsLensException implements Exception {
  final String message;
  final String? technicalDetails;
  final bool isRetryable;

  const KidsLensException(
    this.message, {
    this.technicalDetails,
    this.isRetryable = false,
  });

  /// User-friendly error message
  String get userMessage;

  /// Suggested remediation steps
  String get remediation;

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception for model download failures
class ModelDownloadException extends KidsLensException {
  final String modelId;
  final int? httpStatusCode;

  const ModelDownloadException(
    this.modelId, {
    String message = 'Failed to download model',
    String? technicalDetails,
    this.httpStatusCode,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: true);

  @override
  String get userMessage => 'Could not download the $modelId model.';

  @override
  String get remediation => 'Check your internet connection and try again.';
}

/// Exception for GPU initialization failures
class GPUInitializationException extends KidsLensException {
  final AcceleratorType attemptedType;

  const GPUInitializationException(
    this.attemptedType, {
    String message = 'GPU initialization failed',
    String? technicalDetails,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: true);

  @override
  String get userMessage =>
      'Could not initialize ${attemptedType.name} acceleration.';

  @override
  String get remediation =>
      'The app will use CPU processing instead. This may be slower.';
}

/// Exception for unsupported media formats
class UnsupportedMediaException extends KidsLensException {
  final String? codec;
  final String? container;

  const UnsupportedMediaException({
    this.codec,
    this.container,
    String message = 'Unsupported media format',
  }) : super(message, isRetryable: false);

  @override
  String get userMessage =>
      'This media format is not supported: ${codec ?? container ?? "unknown"}';

  @override
  String get remediation =>
      'Try converting the file to MP4 (H.264) format first.';
}

/// Exception for corrupted media files
class CorruptedMediaException extends KidsLensException {
  final String? probeError;

  const CorruptedMediaException({
    this.probeError,
    String message = 'Media file appears corrupted',
  }) : super(message, isRetryable: false);

  @override
  String get userMessage => 'The media file could not be read properly.';

  @override
  String get remediation =>
      'The file may be corrupted or incomplete. Try re-downloading it.';
}

/// Exception for out of memory conditions
class OutOfMemoryException extends KidsLensException {
  final int requiredMB;
  final int availableMB;

  const OutOfMemoryException({
    required this.requiredMB,
    required this.availableMB,
    String message = 'Not enough memory',
  }) : super(message, isRetryable: true);

  @override
  String get userMessage =>
      'Not enough memory available (need ${requiredMB}MB, have ${availableMB}MB).';

  @override
  String get remediation =>
      'Close other applications or try with a smaller model.';
}

/// Exception for insufficient disk space
class InsufficientDiskSpaceException extends KidsLensException {
  final int requiredMB;
  final int availableMB;

  const InsufficientDiskSpaceException({
    required this.requiredMB,
    required this.availableMB,
    String message = 'Not enough disk space',
  }) : super(message, isRetryable: true);

  @override
  String get userMessage =>
      'Not enough disk space (need ${requiredMB}MB, have ${availableMB}MB).';

  @override
  String get remediation => 'Free up disk space and try again.';
}

/// Exception for analysis failures
class AnalysisException extends KidsLensException {
  final String phase;

  const AnalysisException(
    String message, {
    this.phase = 'unknown',
    String? technicalDetails,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: true);

  @override
  String get userMessage => 'Analysis failed during $phase phase.';

  @override
  String get remediation =>
      'Try again. If the problem persists, try a smaller file.';
}

/// Exception for export failures
class ExportException extends KidsLensException {
  const ExportException(
    String message, {
    String? technicalDetails,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: true);

  @override
  String get userMessage => 'Failed to export the modified video.';

  @override
  String get remediation =>
      'Make sure you have enough disk space and try again.';
}

/// Exception for native library initialization
class NativeLibraryException extends KidsLensException {
  final String libraryName;

  const NativeLibraryException(
    this.libraryName, {
    String message = 'Failed to load native library',
    String? technicalDetails,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: false);

  @override
  String get userMessage => 'Could not load $libraryName.';

  @override
  String get remediation =>
      'Please reinstall the application or check system requirements.';
}

/// Exception for model validation failures
class ModelValidationException extends KidsLensException {
  final String modelId;

  const ModelValidationException(
    this.modelId, {
    String message = 'Model validation failed',
    String? technicalDetails,
  }) : super(message, technicalDetails: technicalDetails, isRetryable: true);

  @override
  String get userMessage => 'The model $modelId appears to be corrupted.';

  @override
  String get remediation => 'Try re-downloading the model.';
}

/// Exception for permission denied
class PermissionDeniedException extends KidsLensException {
  final String resource;

  const PermissionDeniedException(
    this.resource, {
    String message = 'Permission denied',
  }) : super(message, isRetryable: false);

  @override
  String get userMessage => 'Cannot access $resource.';

  @override
  String get remediation =>
      'Please grant the necessary permissions in system settings.';
}
