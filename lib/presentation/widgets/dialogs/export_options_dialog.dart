import 'package:flutter/material.dart';

/// Available export formats
enum ExportFormat { mp4H264, mp4H265, webm, mov, audioOnly }

/// Available export quality levels
enum ExportQuality { low, medium, high, lossless }

/// Dialog for configuring export options
class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({
    super.key,
    this.initialFormat = ExportFormat.mp4H264,
    this.initialQuality = ExportQuality.high,
  });

  final ExportFormat initialFormat;
  final ExportQuality initialQuality;

  /// Show the dialog and return export options
  static Future<({ExportFormat format, ExportQuality quality})?> show({
    required BuildContext context,
    ExportFormat initialFormat = ExportFormat.mp4H264,
    ExportQuality initialQuality = ExportQuality.high,
  }) =>
      showDialog<({ExportFormat format, ExportQuality quality})>(
        context: context,
        builder: (context) => ExportOptionsDialog(
          initialFormat: initialFormat,
          initialQuality: initialQuality,
        ),
      );

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late ExportFormat _format;
  late ExportQuality _quality;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    _quality = widget.initialQuality;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Export Options'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              RadioGroup<ExportFormat>(
                groupValue: _format,
                onChanged: (value) {
                  if (value != null) setState(() => _format = value);
                },
                child: Column(
                  children: ExportFormat.values
                      .map(
                        (format) => RadioListTile<ExportFormat>(
                          title: Text(_formatName(format)),
                          subtitle: Text(_formatDescription(format)),
                          value: format,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quality',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              RadioGroup<ExportQuality>(
                groupValue: _quality,
                onChanged: (value) {
                  if (value != null) setState(() => _quality = value);
                },
                child: Column(
                  children: ExportQuality.values
                      .map(
                        (quality) => RadioListTile<ExportQuality>(
                          title: Text(_qualityName(quality)),
                          value: quality,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop((format: _format, quality: _quality));
            },
            child: const Text('Apply'),
          ),
        ],
      );

  String _formatName(ExportFormat format) => switch (format) {
        ExportFormat.mp4H264 => 'MP4 (H.264)',
        ExportFormat.mp4H265 => 'MP4 (H.265)',
        ExportFormat.webm => 'WebM',
        ExportFormat.mov => 'MOV (ProRes)',
        ExportFormat.audioOnly => 'Audio Only',
      };

  String _formatDescription(ExportFormat format) => switch (format) {
        ExportFormat.mp4H264 => 'Most compatible',
        ExportFormat.mp4H265 => 'Smaller file size',
        ExportFormat.webm => 'Web optimized',
        ExportFormat.mov => 'High quality',
        ExportFormat.audioOnly => 'Extract audio',
      };

  String _qualityName(ExportQuality quality) => switch (quality) {
        ExportQuality.low => 'Low (smaller file)',
        ExportQuality.medium => 'Medium (balanced)',
        ExportQuality.high => 'High (recommended)',
        ExportQuality.lossless => 'Lossless (largest)',
      };
}
