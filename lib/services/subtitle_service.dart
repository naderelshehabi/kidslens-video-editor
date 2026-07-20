import 'dart:io';

import 'package:kidslens_video_editor/data/models/transcript.dart';

/// Subtitle format options
enum SubtitleFormat {
  /// SubRip Text format (.srt)
  srt('srt', 'SRT (SubRip Text)'),

  /// WebVTT format (.vtt)
  vtt('vtt', 'WebVTT'),

  /// Advanced SubStation Alpha (.ass)
  ass('ass', 'ASS (Advanced SubStation)');

  const SubtitleFormat(this.extension, this.displayName);

  final String extension;
  final String displayName;
}

/// Options for subtitle generation
class SubtitleOptions {
  const SubtitleOptions({
    this.maxCharsPerLine = 42,
    this.maxLinesPerCue = 2,
    this.minCueDuration = const Duration(milliseconds: 1000),
    this.maxCueDuration = const Duration(seconds: 7),
    this.gapBetweenCues = const Duration(milliseconds: 100),
    this.includeWordTimings = false,
  });

  /// Maximum characters per subtitle line
  final int maxCharsPerLine;

  /// Maximum lines per subtitle cue
  final int maxLinesPerCue;

  /// Minimum duration for a subtitle cue
  final Duration minCueDuration;

  /// Maximum duration for a subtitle cue
  final Duration maxCueDuration;

  /// Gap between consecutive cues
  final Duration gapBetweenCues;

  /// Include word-level timing (for karaoke effects)
  final bool includeWordTimings;
}

/// Service for generating subtitle files from transcripts
class SubtitleService {
  const SubtitleService();

  /// Generate subtitle file from a transcript
  ///
  /// [transcript] - The transcript to convert
  /// [outputPath] - Where to save the subtitle file
  /// [format] - The subtitle format to use
  /// [options] - Optional formatting options
  Future<File> generateSubtitles(
    Transcript transcript,
    String outputPath,
    SubtitleFormat format, {
    SubtitleOptions options = const SubtitleOptions(),
  }) async {
    final content = switch (format) {
      SubtitleFormat.srt => _generateSrt(transcript, options),
      SubtitleFormat.vtt => _generateVtt(transcript, options),
      SubtitleFormat.ass => _generateAss(transcript, options),
    };

    final file = File(outputPath);
    await file.writeAsString(content);
    return file;
  }

  /// Generate subtitle content as a string
  String generateSubtitleContent(
    Transcript transcript,
    SubtitleFormat format, {
    SubtitleOptions options = const SubtitleOptions(),
  }) =>
      switch (format) {
        SubtitleFormat.srt => _generateSrt(transcript, options),
        SubtitleFormat.vtt => _generateVtt(transcript, options),
        SubtitleFormat.ass => _generateAss(transcript, options),
      };

  /// Generate SRT format subtitles
  String _generateSrt(Transcript transcript, SubtitleOptions options) {
    final cues = _buildCues(transcript, options);
    final buffer = StringBuffer();

    for (var i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer
        ..writeln('${i + 1}')
        ..writeln(
          '${_formatSrtTime(cue.startTime)} --> ${_formatSrtTime(cue.endTime)}',
        )
        ..writeln(cue.text)
        ..writeln();
    }

    return buffer.toString();
  }

  /// Generate WebVTT format subtitles
  String _generateVtt(Transcript transcript, SubtitleOptions options) {
    final cues = _buildCues(transcript, options);
    final buffer = StringBuffer()
      ..writeln('WEBVTT')
      ..writeln('Kind: captions')
      ..writeln('Language: ${transcript.language}')
      ..writeln();

    for (var i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer
        ..writeln('${i + 1}')
        ..writeln(
          '${_formatVttTime(cue.startTime)} --> ${_formatVttTime(cue.endTime)}',
        )
        ..writeln(cue.text)
        ..writeln();
    }

    return buffer.toString();
  }

  /// Generate ASS format subtitles
  String _generateAss(Transcript transcript, SubtitleOptions options) {
    final cues = _buildCues(transcript, options);

    // ASS Header
    final buffer = StringBuffer()
      ..writeln('[Script Info]')
      ..writeln('Title: Generated Subtitles')
      ..writeln('ScriptType: v4.00+')
      ..writeln('PlayResX: 1920')
      ..writeln('PlayResY: 1080')
      ..writeln()
      // Styles
      ..writeln('[V4+ Styles]')
      ..writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding',
      )
      ..writeln(
        'Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,1,2,10,10,30,1',
      )
      ..writeln()
      // Events
      ..writeln('[Events]')
      ..writeln(
        'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text',
      );

    for (final cue in cues) {
      final startStr = _formatAssTime(cue.startTime);
      final endStr = _formatAssTime(cue.endTime);
      // Escape special characters and wrap lines
      final text = cue.text.replaceAll('\n', '\\N');
      buffer.writeln('Dialogue: 0,$startStr,$endStr,Default,,0,0,0,,$text');
    }

    return buffer.toString();
  }

  /// Build subtitle cues from transcript segments
  List<_SubtitleCue> _buildCues(
    Transcript transcript,
    SubtitleOptions options,
  ) {
    final cues = <_SubtitleCue>[];

    for (final segment in transcript.segments) {
      final segmentCues = _splitSegmentIntoCues(segment, options);
      cues.addAll(segmentCues);
    }

    // Adjust timings to ensure gaps
    for (var i = 0; i < cues.length - 1; i++) {
      final current = cues[i];
      final next = cues[i + 1];

      if (current.endTime > next.startTime - options.gapBetweenCues) {
        cues[i] = _SubtitleCue(
          text: current.text,
          startTime: current.startTime,
          endTime: next.startTime - options.gapBetweenCues,
        );
      }
    }

    return cues;
  }

  /// Split a transcript segment into multiple subtitle cues if needed
  List<_SubtitleCue> _splitSegmentIntoCues(
    TranscriptSegment segment,
    SubtitleOptions options,
  ) {
    final cues = <_SubtitleCue>[];
    final words = segment.words;

    if (words.isEmpty) {
      // Use segment text directly if no word timings
      cues.add(
        _SubtitleCue(
          text: _wrapText(segment.text, options),
          startTime: segment.startTime,
          endTime: segment.endTime,
        ),
      );
      return cues;
    }

    // Build cues based on word timings and length constraints
    final buffer = StringBuffer();
    Duration? cueStart;
    Duration? cueEnd;
    var lineCount = 0;
    var lineLength = 0;

    for (final word in words) {
      cueStart ??= word.startTime;

      final wouldExceedLine =
          lineLength + word.word.length + 1 > options.maxCharsPerLine;
      final wouldExceedLines =
          wouldExceedLine && lineCount >= options.maxLinesPerCue - 1;
      final wouldExceedDuration =
          cueEnd != null && word.endTime - cueStart > options.maxCueDuration;

      if (wouldExceedLines || wouldExceedDuration) {
        // Save current cue and start a new one
        if (buffer.isNotEmpty) {
          cues.add(
            _SubtitleCue(
              text: buffer.toString().trim(),
              startTime: cueStart,
              endTime: cueEnd ?? word.startTime,
            ),
          );
        }
        buffer.clear();
        cueStart = word.startTime;
        lineCount = 0;
        lineLength = 0;
      }

      if (wouldExceedLine && !wouldExceedLines) {
        buffer.writeln();
        lineCount++;
        lineLength = 0;
      }

      if (buffer.isNotEmpty && lineLength > 0) {
        buffer.write(' ');
        lineLength++;
      }
      buffer.write(word.word);
      lineLength += word.word.length;
      cueEnd = word.endTime;
    }

    // Add final cue
    if (buffer.isNotEmpty && cueStart != null && cueEnd != null) {
      cues.add(
        _SubtitleCue(
          text: buffer.toString().trim(),
          startTime: cueStart,
          endTime: cueEnd,
        ),
      );
    }

    return cues;
  }

  /// Wrap text to fit within character constraints
  String _wrapText(String text, SubtitleOptions options) {
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = StringBuffer();

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <=
          options.maxCharsPerLine) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
        if (lines.length >= options.maxLinesPerCue) break;
      }
    }

    if (currentLine.isNotEmpty && lines.length < options.maxLinesPerCue) {
      lines.add(currentLine.toString());
    }

    return lines.join('\n');
  }

  /// Format duration for SRT (00:00:00,000)
  String _formatSrtTime(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }

  /// Format duration for VTT (00:00:00.000)
  String _formatVttTime(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Format duration for ASS (0:00:00.00)
  String _formatAssTime(Duration d) {
    final hours = d.inHours;
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final centis =
        ((d.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds.$centis';
  }
}

/// Internal class representing a subtitle cue
class _SubtitleCue {
  const _SubtitleCue({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  final String text;
  final Duration startTime;
  final Duration endTime;
}
