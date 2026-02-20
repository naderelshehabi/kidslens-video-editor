import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/subtitle_track.dart';

/// Overlays the current subtitle segment text on the video preview.
///
/// Positioned at the bottom of the video area, shows the subtitle text
/// for the current playback position with a semi-transparent background.
class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({
    required this.subtitleTrack,
    required this.currentPosition,
    super.key,
    this.fontSize = 16,
    this.backgroundColor = const Color(0xCC000000),
    this.textColor = Colors.white,
  });

  final SubtitleTrack? subtitleTrack;
  final Duration currentPosition;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (subtitleTrack == null) return const SizedBox.shrink();

    final segment = subtitleTrack!.getSegmentAt(currentPosition);
    if (segment == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            segment.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              shadows: const [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
