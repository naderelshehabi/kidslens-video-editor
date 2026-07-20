import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_provider.g.dart';

/// State for media management
class MediaState {
  const MediaState({
    this.currentMedia,
    this.isLoading = false,
    this.errorMessage,
    this.recentFiles = const [],
  });

  final MediaFile? currentMedia;
  final bool isLoading;
  final String? errorMessage;
  final List<MediaFile> recentFiles;

  MediaState copyWith({
    MediaFile? currentMedia,
    bool? isLoading,
    String? errorMessage,
    List<MediaFile>? recentFiles,
  }) =>
      MediaState(
        currentMedia: currentMedia ?? this.currentMedia,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        recentFiles: recentFiles ?? this.recentFiles,
      );
}

/// Provider for managing media state
@Riverpod(keepAlive: true)
class MediaNotifier extends _$MediaNotifier {
  @override
  MediaState build() => const MediaState();

  Future<void> importMedia(String path) async {
    state = state.copyWith(isLoading: true);
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final mediaFile = await mediaService.importMedia(path);

      final updatedRecent = [
        mediaFile,
        ...state.recentFiles.where((f) => f.id != mediaFile.id).take(9),
      ];

      state = state.copyWith(
        isLoading: false,
        currentMedia: mediaFile,
        recentFiles: updatedRecent,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setCurrentMedia(MediaFile media) {
    final updatedRecent = [
      media,
      ...state.recentFiles.where((f) => f.id != media.id).take(9),
    ];
    state = state.copyWith(
      currentMedia: media,
      recentFiles: updatedRecent,
    );
  }

  void clearMedia() {
    state = state.copyWith();
  }

  void clearError() {
    state = state.copyWith();
  }
}
