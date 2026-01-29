import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/core/constants/supported_formats.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';

/// Screen for importing media files
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Import Media'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildDropZone(context),
            ),
            const SizedBox(height: 24),
            _buildSupportedFormats(context),
          ],
        ),
      ),
    );

  Widget _buildDropZone(BuildContext context) => DragTarget<String>(
      onAcceptWithDetails: (details) {
        _importFile(details.data);
      },
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragging = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
      },
      builder: (context, candidateData, rejectedData) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: _isDragging ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: _isDragging
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: InkWell(
            onTap: _selectFile,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: _isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drop a video or audio file here',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'or click to browse',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse Files'),
                  ),
                ],
              ),
            ),
          ),
        ),
    );

  Widget _buildSupportedFormats(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Formats',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...SupportedFormats.videoContainers.map(
                  (format) => Chip(
                    label: Text(format.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...SupportedFormats.audioFormats.map(
                  (format) => Chip(
                    label: Text(format.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...SupportedFormats.videoContainers,
          ...SupportedFormats.audioFormats,
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          _importFile(file.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _importFile(String path) {
    ref.read(mediaNotifierProvider.notifier).importMedia(path);
    Navigator.of(context).pop();
  }
}
