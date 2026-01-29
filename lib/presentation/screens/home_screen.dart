import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_result.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/presentation/screens/detection_review_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/import_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:kidslens_video_editor/presentation/widgets/common/progress_card.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';

/// Main home screen of the application
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaNotifierProvider);
    final analysisState = ref.watch(analysisNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            const Text('KidsLens'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _buildBody(context, ref, mediaState, analysisState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importMedia(context),
        icon: const Icon(Icons.add),
        label: const Text('Import Media'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState,
    AnalysisState analysisState,
  ) {
    // Show loading if importing media
    if (mediaState.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading media...'),
          ],
        ),
      );
    }

    // Show error if any
    if (mediaState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              mediaState.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(mediaNotifierProvider.notifier).clearError(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    // Show empty state if no media
    if (mediaState.currentMedia == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 200,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.video_library_outlined, size: 120),
            ),
            const SizedBox(height: 24),
            Text(
              'No Media Loaded',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Import a video or audio file to start analyzing content.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show analysis progress if running
    if (analysisState.status == AnalysisStatus.running ||
        analysisState.isPaused) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MediaInfoCard(media: mediaState.currentMedia!),
            const SizedBox(height: 16),
            ProgressCard(
              title: 'Analyzing Content',
              subtitle: mediaState.currentMedia!.name,
              progress: analysisState.progress,
              status: analysisState.currentStep,
              icon: Icons.analytics_outlined,
              isPaused: analysisState.isPaused,
              estimatedTimeRemaining: analysisState.estimatedSecondsRemaining != null
                  ? Duration(seconds: analysisState.estimatedSecondsRemaining!)
                  : null,
              onPause: () => ref.read(analysisNotifierProvider.notifier).pause(),
              onResume: () => ref.read(analysisNotifierProvider.notifier).resume(),
              onCancel: () => ref.read(analysisNotifierProvider.notifier).cancel(),
            ),
          ],
        ),
      );
    }

    // Show media info and action buttons
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MediaInfoCard(media: mediaState.currentMedia!),
          const SizedBox(height: 24),
          if (analysisState.status == AnalysisStatus.completed) ...[
            _buildCompletedActions(context, ref),
          ] else ...[
            _buildStartAnalysisButton(context, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildStartAnalysisButton(BuildContext context, WidgetRef ref) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan for profanity, nudity, violence, and other inappropriate content.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _startAnalysis(ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Analysis'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _startSampleAnalysis(ref),
                  child: const Text('Preview (5s)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildCompletedActions(BuildContext context, WidgetRef ref) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openReview(context),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Review Detections'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.read(analysisNotifierProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-analyze'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  void _importMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ImportScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DetectionReviewScreen(),
      ),
    );
  }

  void _startAnalysis(WidgetRef ref) {
    final media = ref.read(mediaNotifierProvider).currentMedia;
    if (media != null) {
      ref.read(analysisNotifierProvider.notifier).startAnalysis(
            mediaPath: media.path,
            mediaId: media.id,
            settings: AnalysisSettings.defaults(),
            mediaDuration: media.duration,
          );
    }
  }

  void _startSampleAnalysis(WidgetRef ref) {
    // TODO: Implement sample analysis
    _startAnalysis(ref);
  }
}

class _MediaInfoCard extends StatelessWidget {
  const _MediaInfoCard({required this.media});

  final MediaFile media;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(media.isVideo ? Icons.video_file : Icons.audio_file, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(media.duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
