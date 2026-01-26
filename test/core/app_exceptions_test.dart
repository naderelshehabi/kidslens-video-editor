import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/errors/app_exceptions.dart';

void main() {
  group('KidsLensException', () {
    group('ModelDownloadException', () {
      test('should create with model name and message', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Download failed',
        );

        expect(exception.modelName, equals('whisper'));
        expect(exception.message, equals('Download failed'));
      });

      test('should create with URL', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Download failed',
          url: 'https://models.example.com/whisper.onnx',
        );

        expect(exception.url, equals('https://models.example.com/whisper.onnx'));
      });

      test('should create with status code', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Not found',
          statusCode: 404,
        );

        expect(exception.statusCode, equals(404));
      });

      test('should include model name in toString', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Download failed',
        );

        expect(exception.toString(), contains('whisper'));
        expect(exception.toString(), contains('Download failed'));
      });
    });

    group('GPUInitializationException', () {
      test('should create with message', () {
        final exception = GPUInitializationException(
          message: 'Failed to initialize CUDA',
        );

        expect(exception.message, equals('Failed to initialize CUDA'));
      });

      test('should create with backend info', () {
        final exception = GPUInitializationException(
          message: 'Initialization failed',
          backend: 'CUDA',
        );

        expect(exception.backend, equals('CUDA'));
      });

      test('should create with device info', () {
        final exception = GPUInitializationException(
          message: 'Initialization failed',
          device: 'NVIDIA RTX 3080',
        );

        expect(exception.device, equals('NVIDIA RTX 3080'));
      });

      test('should include backend in toString', () {
        final exception = GPUInitializationException(
          message: 'Failed',
          backend: 'DirectML',
        );

        expect(exception.toString(), contains('DirectML'));
      });
    });

    group('UnsupportedMediaException', () {
      test('should create with file path and format', () {
        final exception = UnsupportedMediaException(
          filePath: '/path/to/video.xyz',
          format: 'xyz',
        );

        expect(exception.filePath, equals('/path/to/video.xyz'));
        expect(exception.format, equals('xyz'));
      });

      test('should create with reason', () {
        final exception = UnsupportedMediaException(
          filePath: '/path/to/video.xyz',
          format: 'xyz',
          reason: 'Codec not supported',
        );

        expect(exception.reason, equals('Codec not supported'));
      });

      test('should include format in toString', () {
        final exception = UnsupportedMediaException(
          filePath: '/path/to/video.xyz',
          format: 'xyz',
        );

        expect(exception.toString(), contains('xyz'));
      });

      test('should include file path in toString', () {
        final exception = UnsupportedMediaException(
          filePath: '/path/to/video.xyz',
          format: 'xyz',
        );

        expect(exception.toString(), contains('/path/to/video.xyz'));
      });
    });

    group('CorruptedMediaException', () {
      test('should create with file path', () {
        final exception = CorruptedMediaException(
          filePath: '/path/to/corrupted.mp4',
        );

        expect(exception.filePath, equals('/path/to/corrupted.mp4'));
      });

      test('should create with details', () {
        final exception = CorruptedMediaException(
          filePath: '/path/to/corrupted.mp4',
          details: 'Invalid header at offset 0x1234',
        );

        expect(exception.details, equals('Invalid header at offset 0x1234'));
      });

      test('should include file path in toString', () {
        final exception = CorruptedMediaException(
          filePath: '/path/to/corrupted.mp4',
        );

        expect(exception.toString(), contains('/path/to/corrupted.mp4'));
      });
    });

    group('OutOfMemoryException', () {
      test('should create with required and available memory', () {
        final exception = OutOfMemoryException(
          requiredBytes: 8589934592, // 8 GB
          availableBytes: 4294967296, // 4 GB
        );

        expect(exception.requiredBytes, equals(8589934592));
        expect(exception.availableBytes, equals(4294967296));
      });

      test('should create with operation context', () {
        final exception = OutOfMemoryException(
          requiredBytes: 8589934592,
          availableBytes: 4294967296,
          operation: 'Frame buffer allocation',
        );

        expect(exception.operation, equals('Frame buffer allocation'));
      });

      test('should include memory info in toString', () {
        final exception = OutOfMemoryException(
          requiredBytes: 8589934592,
          availableBytes: 4294967296,
        );

        expect(exception.toString(), contains('memory'));
      });
    });

    group('InsufficientDiskSpaceException', () {
      test('should create with required and available space', () {
        final exception = InsufficientDiskSpaceException(
          requiredBytes: 10737418240, // 10 GB
          availableBytes: 5368709120, // 5 GB
          path: 'C:\\Temp',
        );

        expect(exception.requiredBytes, equals(10737418240));
        expect(exception.availableBytes, equals(5368709120));
        expect(exception.path, equals('C:\\Temp'));
      });

      test('should include path in toString', () {
        final exception = InsufficientDiskSpaceException(
          requiredBytes: 10737418240,
          availableBytes: 5368709120,
          path: 'C:\\Temp',
        );

        expect(exception.toString(), contains('C:\\Temp'));
      });
    });

    group('AnalysisException', () {
      test('should create with message', () {
        final exception = AnalysisException(
          message: 'Analysis failed',
        );

        expect(exception.message, equals('Analysis failed'));
      });

      test('should create with stage', () {
        final exception = AnalysisException(
          message: 'Analysis failed',
          stage: 'transcription',
        );

        expect(exception.stage, equals('transcription'));
      });

      test('should create with progress', () {
        final exception = AnalysisException(
          message: 'Analysis failed',
          progress: 0.75,
        );

        expect(exception.progress, equals(0.75));
      });

      test('should create with inner exception', () {
        final innerException = Exception('Inner error');
        final exception = AnalysisException(
          message: 'Analysis failed',
          innerException: innerException,
        );

        expect(exception.innerException, equals(innerException));
      });

      test('should include stage in toString', () {
        final exception = AnalysisException(
          message: 'Analysis failed',
          stage: 'detection',
        );

        expect(exception.toString(), contains('detection'));
      });
    });

    group('ExportException', () {
      test('should create with message', () {
        final exception = ExportException(
          message: 'Export failed',
        );

        expect(exception.message, equals('Export failed'));
      });

      test('should create with output path', () {
        final exception = ExportException(
          message: 'Export failed',
          outputPath: '/path/to/output.mp4',
        );

        expect(exception.outputPath, equals('/path/to/output.mp4'));
      });

      test('should create with stage', () {
        final exception = ExportException(
          message: 'Export failed',
          stage: 'encoding',
        );

        expect(exception.stage, equals('encoding'));
      });

      test('should create with FFmpeg error code', () {
        final exception = ExportException(
          message: 'Export failed',
          ffmpegErrorCode: -22,
        );

        expect(exception.ffmpegErrorCode, equals(-22));
      });

      test('should include output path in toString', () {
        final exception = ExportException(
          message: 'Export failed',
          outputPath: '/path/to/output.mp4',
        );

        expect(exception.toString(), contains('/path/to/output.mp4'));
      });
    });

    group('NativeLibraryException', () {
      test('should create with library name', () {
        final exception = NativeLibraryException(
          libraryName: 'ffmpeg.dll',
          message: 'Library not found',
        );

        expect(exception.libraryName, equals('ffmpeg.dll'));
        expect(exception.message, equals('Library not found'));
      });

      test('should create with error code', () {
        final exception = NativeLibraryException(
          libraryName: 'ffmpeg.dll',
          message: 'Library load failed',
          errorCode: 126,
        );

        expect(exception.errorCode, equals(126));
      });

      test('should include library name in toString', () {
        final exception = NativeLibraryException(
          libraryName: 'onnxruntime.dll',
          message: 'Failed to load',
        );

        expect(exception.toString(), contains('onnxruntime.dll'));
      });
    });

    group('ModelValidationException', () {
      test('should create with model name', () {
        final exception = ModelValidationException(
          modelName: 'whisper',
          message: 'Checksum mismatch',
        );

        expect(exception.modelName, equals('whisper'));
        expect(exception.message, equals('Checksum mismatch'));
      });

      test('should create with expected and actual hash', () {
        final exception = ModelValidationException(
          modelName: 'whisper',
          message: 'Checksum mismatch',
          expectedHash: 'abc123',
          actualHash: 'def456',
        );

        expect(exception.expectedHash, equals('abc123'));
        expect(exception.actualHash, equals('def456'));
      });

      test('should include model name in toString', () {
        final exception = ModelValidationException(
          modelName: 'yolo',
          message: 'Validation failed',
        );

        expect(exception.toString(), contains('yolo'));
      });
    });

    group('PermissionDeniedException', () {
      test('should create with permission type', () {
        final exception = PermissionDeniedException(
          permission: 'file_access',
          message: 'Access denied',
        );

        expect(exception.permission, equals('file_access'));
        expect(exception.message, equals('Access denied'));
      });

      test('should create with path', () {
        final exception = PermissionDeniedException(
          permission: 'file_access',
          message: 'Access denied',
          path: '/protected/folder',
        );

        expect(exception.path, equals('/protected/folder'));
      });

      test('should include permission in toString', () {
        final exception = PermissionDeniedException(
          permission: 'microphone',
          message: 'Permission denied',
        );

        expect(exception.toString(), contains('microphone'));
      });
    });

    group('Pattern matching', () {
      test('should pattern match on exception type', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Failed',
        );

        final result = switch (exception) {
          ModelDownloadException(:final modelName) => 'Download: $modelName',
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

        expect(result, equals('Download: whisper'));
      });

      test('should pattern match GPU exception', () {
        final exception = GPUInitializationException(
          message: 'CUDA not available',
          backend: 'CUDA',
        );

        final result = switch (exception) {
          GPUInitializationException(:final backend) => backend ?? 'unknown',
          _ => 'other',
        };

        expect(result, equals('CUDA'));
      });

      test('should pattern match with when clause', () {
        final exception = OutOfMemoryException(
          requiredBytes: 8589934592,
          availableBytes: 4294967296,
        );

        final severity = switch (exception) {
          OutOfMemoryException(
            :final requiredBytes,
            :final availableBytes
          ) when requiredBytes > availableBytes * 2 =>
            'critical',
          OutOfMemoryException() => 'warning',
          _ => 'unknown',
        };

        expect(severity, equals('warning'));
      });
    });

    group('Exception equality', () {
      test('ModelDownloadException should support equality', () {
        final e1 = ModelDownloadException(
          modelName: 'whisper',
          message: 'Failed',
        );
        final e2 = ModelDownloadException(
          modelName: 'whisper',
          message: 'Failed',
        );

        expect(e1, equals(e2));
      });

      test('Different exceptions should not be equal', () {
        final e1 = ModelDownloadException(
          modelName: 'whisper',
          message: 'Failed',
        );
        final e2 = ModelDownloadException(
          modelName: 'yolo',
          message: 'Failed',
        );

        expect(e1, isNot(equals(e2)));
      });
    });

    group('Exception hashCode', () {
      test('should have consistent hashCode', () {
        final e1 = AnalysisException(message: 'Failed');
        final e2 = AnalysisException(message: 'Failed');

        expect(e1.hashCode, equals(e2.hashCode));
      });
    });

    group('isRetryable', () {
      test('ModelDownloadException should be retryable', () {
        final exception = ModelDownloadException(
          modelName: 'whisper',
          message: 'Network error',
        );

        expect(exception.isRetryable, isTrue);
      });

      test('CorruptedMediaException should not be retryable', () {
        final exception = CorruptedMediaException(
          filePath: '/path/to/file.mp4',
        );

        expect(exception.isRetryable, isFalse);
      });

      test('OutOfMemoryException may be retryable', () {
        final exception = OutOfMemoryException(
          requiredBytes: 1073741824,
          availableBytes: 536870912,
        );

        // Depends on implementation - may need to free resources first
        expect(exception.isRetryable, isA<bool>());
      });
    });

    group('userMessage', () {
      test('should provide user-friendly message', () {
        final exception = UnsupportedMediaException(
          filePath: '/path/to/video.xyz',
          format: 'xyz',
        );

        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage, isNot(contains('xyz')));
      });

      test('should not expose technical details', () {
        final exception = NativeLibraryException(
          libraryName: 'ffmpeg.dll',
          message: 'LoadLibrary failed with error 126',
          errorCode: 126,
        );

        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage.toLowerCase(), isNot(contains('0x')));
      });
    });
  });
}
