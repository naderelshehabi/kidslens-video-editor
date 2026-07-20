import 'package:flutter/material.dart';

/// Playhead indicator for the timeline
class Playhead extends StatelessWidget {
  const Playhead({
    required this.currentPosition,
    required this.totalDuration,
    required this.height,
    super.key,
    this.onSeek,
  });

  final Duration currentPosition;
  final Duration totalDuration;
  final double height;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final progress = totalDuration.inMilliseconds > 0
              ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
              : 0.0;
          final position = constraints.maxWidth * progress;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (onSeek != null) {
                final newProgress =
                    (details.localPosition.dx / constraints.maxWidth)
                        .clamp(0.0, 1.0);
                final newPosition = Duration(
                  milliseconds:
                      (newProgress * totalDuration.inMilliseconds).round(),
                );
                onSeek!(newPosition);
              }
            },
            onTapDown: (details) {
              if (onSeek != null) {
                final newProgress =
                    (details.localPosition.dx / constraints.maxWidth)
                        .clamp(0.0, 1.0);
                final newPosition = Duration(
                  milliseconds:
                      (newProgress * totalDuration.inMilliseconds).round(),
                );
                onSeek!(newPosition);
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Track background
                Container(
                  height: height,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                // Progress
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: position,
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                // Playhead
                Positioned(
                  left: position - 1,
                  top: -8,
                  bottom: -8,
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary,
                    child: Column(
                      children: [
                        // Top handle
                        Transform.translate(
                          offset: const Offset(-5, -6),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                                bottomLeft: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
