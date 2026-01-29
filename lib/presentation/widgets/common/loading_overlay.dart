import 'package:flutter/material.dart';

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.message,
    this.progress,
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final double? progress;

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        child,
        if (isLoading)
          ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (progress != null)
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(value: progress),
                        )
                      else
                        const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${(progress! * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
}
