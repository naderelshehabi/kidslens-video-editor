import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/core/errors/error_handler.dart';

/// Widget for displaying errors
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    this.error,
    this.onRetry,
    this.onDismiss,
  });

  final ErrorResult? error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!.userMessage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error!.remediation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            if (error!.isRetryable && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show error as a snackbar
  static void showSnackBar(BuildContext context, ErrorResult error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: error.isRetryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {
                  // Retry action should be passed
                },
              )
            : null,
      ),
    );
  }
}
