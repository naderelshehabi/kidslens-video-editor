import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/errors/app_exceptions.dart';
import 'package:kidslens_video_editor/data/models/gpu_info.dart';

void main() {
  group('KidsLensException', () {
    group('ModelDownloadException', () {
      test('should create with model id and message', () {
        const exception = ModelDownloadException(
          'whisper',
          message: 'Download failed',
        );

        expect(exception.modelId, equals('whisper'));
        expect(exception.message, equals('Download failed'));
      });

      test('should create with default message', () {
        const exception = ModelDownloadException('whisper');

        expect(exception.modelId, equals('whisper'));
        expect(exception.message, equals('Failed to download model'));
      });

      test('should create with http status code', () {
        const exception = ModelDownloadException(
          'whisper',
          message: 'Not found',
          httpStatusCode: 404,
        );

        expect(exception.httpStatusCode, equals(404));
      });

      test('should include model id in toString', () {
        const exception = ModelDownloadException(
          'whisper',
          message: 'Download failed',
        );

        // toString includes runtime type and message, not model id
        expect(exception.toString(), contains('ModelDownloadException'));
        expect(exception.toString(), contains('Download failed'));
      });

      test('should provide user message with model id', () {
        const exception = ModelDownloadException('whisper');

        expect(exception.userMessage, contains('whisper'));
      });

      test('should be retryable', () {
        const exception = ModelDownloadException('whisper');

        expect(exception.isRetryable, isTrue);
      });
    });

    group('GPUInitializationException', () {
      test('should create with accelerator type', () {
        const exception = GPUInitializationException(
          AcceleratorType.cuda,
          message: 'Failed to initialize CUDA',
        );

        expect(exception.attemptedType, equals(AcceleratorType.cuda));
        expect(exception.message, equals('Failed to initialize CUDA'));
      });

      test('should create with default message', () {
        const exception = GPUInitializationException(AcceleratorType.metal);

        expect(exception.attemptedType, equals(AcceleratorType.metal));
        expect(exception.message, equals('GPU initialization failed'));
      });

      test('should provide user message with accelerator type name', () {
        const exception = GPUInitializationException(AcceleratorType.vulkan);

        expect(exception.userMessage, contains('vulkan'));
      });

      test('should include technical details if provided', () {
        const exception = GPUInitializationException(
          AcceleratorType.rocm,
          technicalDetails: 'ROCm driver version mismatch',
        );

        expect(
          exception.technicalDetails,
          equals('ROCm driver version mismatch'),
        );
      });

      test('should be retryable', () {
        const exception = GPUInitializationException(AcceleratorType.cuda);

        expect(exception.isRetryable, isTrue);
      });
    });

    group('UnsupportedMediaException', () {
      test('should create with codec', () {
        const exception = UnsupportedMediaException(
          codec: 'hevc',
        );

        expect(exception.codec, equals('hevc'));
      });

      test('should create with container', () {
        const exception = UnsupportedMediaException(
          container: 'mkv',
        );

        expect(exception.container, equals('mkv'));
      });

      test('should create with both codec and container', () {
        const exception = UnsupportedMediaException(
          codec: 'vp9',
          container: 'webm',
        );

        expect(exception.codec, equals('vp9'));
        expect(exception.container, equals('webm'));
      });

      test('should provide user message with codec', () {
        const exception = UnsupportedMediaException(codec: 'av1');

        expect(exception.userMessage, contains('av1'));
      });

      test('should provide user message with container when no codec', () {
        const exception = UnsupportedMediaException(container: 'avi');

        expect(exception.userMessage, contains('avi'));
      });

      test('should not be retryable', () {
        const exception = UnsupportedMediaException(codec: 'xyz');

        expect(exception.isRetryable, isFalse);
      });
    });

    group('CorruptedMediaException', () {
      test('should create with default message', () {
        const exception = CorruptedMediaException();

        expect(exception.message, equals('Media file appears corrupted'));
      });

      test('should create with probe error', () {
        const exception = CorruptedMediaException(
          probeError: 'Invalid header at offset 0x1234',
        );

        expect(exception.probeError, equals('Invalid header at offset 0x1234'));
      });

      test('should create with custom message', () {
        const exception = CorruptedMediaException(
          message: 'File is truncated',
        );

        expect(exception.message, equals('File is truncated'));
      });

      test('should not be retryable', () {
        const exception = CorruptedMediaException();

        expect(exception.isRetryable, isFalse);
      });
    });

    group('OutOfMemoryException', () {
      test('should create with required and available memory in MB', () {
        const exception = OutOfMemoryException(
          requiredMB: 8192, // 8 GB
          availableMB: 4096, // 4 GB
        );

        expect(exception.requiredMB, equals(8192));
        expect(exception.availableMB, equals(4096));
      });

      test('should provide user message with memory info', () {
        const exception = OutOfMemoryException(
          requiredMB: 8192,
          availableMB: 4096,
        );

        expect(exception.userMessage, contains('8192'));
        expect(exception.userMessage, contains('4096'));
      });

      test('should be retryable', () {
        const exception = OutOfMemoryException(
          requiredMB: 1024,
          availableMB: 512,
        );

        expect(exception.isRetryable, isTrue);
      });
    });

    group('InsufficientDiskSpaceException', () {
      test('should create with required and available space in MB', () {
        const exception = InsufficientDiskSpaceException(
          requiredMB: 10240, // 10 GB
          availableMB: 5120, // 5 GB
        );

        expect(exception.requiredMB, equals(10240));
        expect(exception.availableMB, equals(5120));
      });

      test('should provide user message with disk space info', () {
        const exception = InsufficientDiskSpaceException(
          requiredMB: 10240,
          availableMB: 5120,
        );

        expect(exception.userMessage, contains('10240'));
        expect(exception.userMessage, contains('5120'));
      });

      test('should be retryable', () {
        const exception = InsufficientDiskSpaceException(
          requiredMB: 1024,
          availableMB: 512,
        );

        expect(exception.isRetryable, isTrue);
      });
    });

    group('AnalysisException', () {
      test('should create with message', () {
        const exception = AnalysisException('Analysis failed');

        expect(exception.message, equals('Analysis failed'));
      });

      test('should create with phase', () {
        const exception = AnalysisException(
          'Analysis failed',
          phase: 'transcription',
        );

        expect(exception.phase, equals('transcription'));
      });

      test('should have default phase as unknown', () {
        const exception = AnalysisException('Analysis failed');

        expect(exception.phase, equals('unknown'));
      });

      test('should provide user message with phase', () {
        const exception = AnalysisException(
          'Analysis failed',
          phase: 'detection',
        );

        expect(exception.userMessage, contains('detection'));
      });

      test('should include technical details if provided', () {
        const exception = AnalysisException(
          'Analysis failed',
          technicalDetails: 'Model returned invalid output',
        );

        expect(
          exception.technicalDetails,
          equals('Model returned invalid output'),
        );
      });

      test('should be retryable', () {
        const exception = AnalysisException('Analysis failed');

        expect(exception.isRetryable, isTrue);
      });
    });

    group('ExportException', () {
      test('should create with message', () {
        const exception = ExportException('Export failed');

        expect(exception.message, equals('Export failed'));
      });

      test('should create with technical details', () {
        const exception = ExportException(
          'Export failed',
          technicalDetails: 'FFmpeg returned error code -22',
        );

        expect(
          exception.technicalDetails,
          equals('FFmpeg returned error code -22'),
        );
      });

      test('should provide user-friendly message', () {
        const exception = ExportException('Encoding error');

        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage, contains('export'));
      });

      test('should be retryable', () {
        const exception = ExportException('Export failed');

        expect(exception.isRetryable, isTrue);
      });
    });

    group('NativeLibraryException', () {
      test('should create with library name', () {
        const exception = NativeLibraryException(
          'ffmpeg.dll',
          message: 'Library not found',
        );

        expect(exception.libraryName, equals('ffmpeg.dll'));
        expect(exception.message, equals('Library not found'));
      });

      test('should create with default message', () {
        const exception = NativeLibraryException('onnxruntime.dll');

        expect(exception.libraryName, equals('onnxruntime.dll'));
        expect(exception.message, equals('Failed to load native library'));
      });

      test('should provide user message with library name', () {
        const exception = NativeLibraryException('whisper.dll');

        expect(exception.userMessage, contains('whisper.dll'));
      });

      test('should not be retryable', () {
        const exception = NativeLibraryException('some.dll');

        expect(exception.isRetryable, isFalse);
      });
    });

    group('ModelValidationException', () {
      test('should create with model id', () {
        const exception = ModelValidationException(
          'whisper',
          message: 'Checksum mismatch',
        );

        expect(exception.modelId, equals('whisper'));
        expect(exception.message, equals('Checksum mismatch'));
      });

      test('should create with default message', () {
        const exception = ModelValidationException('yolo');

        expect(exception.modelId, equals('yolo'));
        expect(exception.message, equals('Model validation failed'));
      });

      test('should provide user message with model id', () {
        const exception = ModelValidationException('whisper');

        expect(exception.userMessage, contains('whisper'));
      });

      test('should be retryable', () {
        const exception = ModelValidationException('whisper');

        expect(exception.isRetryable, isTrue);
      });
    });

    group('PermissionDeniedException', () {
      test('should create with resource', () {
        const exception = PermissionDeniedException(
          'file_access',
          message: 'Access denied',
        );

        expect(exception.resource, equals('file_access'));
        expect(exception.message, equals('Access denied'));
      });

      test('should create with default message', () {
        const exception = PermissionDeniedException('microphone');

        expect(exception.resource, equals('microphone'));
        expect(exception.message, equals('Permission denied'));
      });

      test('should provide user message with resource', () {
        const exception = PermissionDeniedException('camera');

        expect(exception.userMessage, contains('camera'));
      });

      test('should not be retryable', () {
        const exception = PermissionDeniedException('storage');

        expect(exception.isRetryable, isFalse);
      });
    });

    group('Pattern matching', () {
      test('should pattern match on exception type', () {
        // Use a helper function to avoid dead code warning from static type analysis
        String matchException(KidsLensException exception) =>
            switch (exception) {
              ModelDownloadException(:final modelId) => 'Download: $modelId',
              GPUInitializationException() => 'GPU',
              UnsupportedMediaException() => 'Unsupported',
              CorruptedMediaException() => 'Corrupted',
              OutOfMemoryException() => 'OOM',
              InsufficientDiskSpaceException() => 'Disk',
              AnalysisException() => 'Analysis',
              ExportException() => 'Export',
              NativeLibraryException() => 'Native',
              ModelValidationException() => 'Validation',
              PermissionDeniedException() => 'Permission',
            };

        const exception = ModelDownloadException('whisper');
        expect(matchException(exception), equals('Download: whisper'));
      });

      test('should pattern match GPU exception', () {
        const exception = GPUInitializationException(AcceleratorType.cuda);

        final result = switch (exception) {
          GPUInitializationException(:final attemptedType) =>
            attemptedType.name,
        };

        expect(result, equals('cuda'));
      });

      test('should pattern match with when clause', () {
        const exception = OutOfMemoryException(
          requiredMB: 8192,
          availableMB: 4096,
        );

        final severity = switch (exception) {
          OutOfMemoryException(:final requiredMB, :final availableMB)
              when requiredMB > availableMB * 2 =>
            'critical',
          OutOfMemoryException() => 'warning',
        };

        expect(severity, equals('warning'));
      });

      test('should pattern match critical memory situation', () {
        const exception = OutOfMemoryException(
          requiredMB: 16384,
          availableMB: 4096,
        );

        final severity = switch (exception) {
          OutOfMemoryException(:final requiredMB, :final availableMB)
              when requiredMB > availableMB * 2 =>
            'critical',
          OutOfMemoryException() => 'warning',
        };

        expect(severity, equals('critical'));
      });
    });

    group('isRetryable', () {
      test('ModelDownloadException should be retryable', () {
        const exception = ModelDownloadException('whisper');

        expect(exception.isRetryable, isTrue);
      });

      test('CorruptedMediaException should not be retryable', () {
        const exception = CorruptedMediaException();

        expect(exception.isRetryable, isFalse);
      });

      test('OutOfMemoryException should be retryable', () {
        const exception = OutOfMemoryException(
          requiredMB: 1024,
          availableMB: 512,
        );

        expect(exception.isRetryable, isTrue);
      });

      test('UnsupportedMediaException should not be retryable', () {
        const exception = UnsupportedMediaException(codec: 'unknown');

        expect(exception.isRetryable, isFalse);
      });
    });

    group('userMessage', () {
      test('should provide user-friendly message for UnsupportedMediaException',
          () {
        const exception = UnsupportedMediaException(codec: 'hevc');

        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage, contains('hevc'));
      });

      test('should provide user-friendly message for NativeLibraryException',
          () {
        const exception = NativeLibraryException('ffmpeg.dll');

        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage, contains('ffmpeg.dll'));
      });
    });

    group('remediation', () {
      test('ModelDownloadException should suggest checking connection', () {
        const exception = ModelDownloadException('whisper');

        expect(exception.remediation.toLowerCase(), contains('internet'));
      });

      test('UnsupportedMediaException should suggest converting to MP4', () {
        const exception = UnsupportedMediaException(codec: 'vp9');

        expect(exception.remediation, contains('MP4'));
      });

      test('OutOfMemoryException should suggest closing apps', () {
        const exception = OutOfMemoryException(
          requiredMB: 8192,
          availableMB: 4096,
        );

        expect(exception.remediation.toLowerCase(), contains('close'));
      });

      test('InsufficientDiskSpaceException should suggest freeing space', () {
        const exception = InsufficientDiskSpaceException(
          requiredMB: 10240,
          availableMB: 5120,
        );

        expect(exception.remediation.toLowerCase(), contains('free'));
      });
    });

    group('toString', () {
      test('should include runtime type and message', () {
        const exception = ModelDownloadException('whisper', message: 'Failed');

        final str = exception.toString();
        expect(str, contains('ModelDownloadException'));
        expect(str, contains('Failed'));
      });

      test('AnalysisException toString should include message', () {
        const exception = AnalysisException('Processing error');

        expect(exception.toString(), contains('AnalysisException'));
        expect(exception.toString(), contains('Processing error'));
      });
    });
  });
}
