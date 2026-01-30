import 'dart:io';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/project.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'project_provider.g.dart';

/// State for project management
class ProjectState {
  const ProjectState({
    this.currentProject,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.recentProjectPaths = const [],
    this.undoStack = const [],
    this.redoStack = const [],
  });

  final Project? currentProject;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final List<String> recentProjectPaths;
  final List<Project> undoStack;
  final List<Project> redoStack;

  ProjectState copyWith({
    Project? currentProject,
    bool clearProject = false,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    List<String>? recentProjectPaths,
    List<Project>? undoStack,
    List<Project>? redoStack,
  }) =>
      ProjectState(
        currentProject:
            clearProject ? null : (currentProject ?? this.currentProject),
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: errorMessage,
        recentProjectPaths: recentProjectPaths ?? this.recentProjectPaths,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
      );

  /// Whether a project is currently open
  bool get hasProject => currentProject != null;

  /// Whether analysis is in progress
  bool get isAnalyzing =>
      currentProject?.analysisProgress != null &&
      !(currentProject?.analysisComplete ?? true);

  /// Whether undo is available
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => redoStack.isNotEmpty;
}

/// Provider for managing project state
@Riverpod(keepAlive: true)
class ProjectNotifier extends _$ProjectNotifier {
  static const _recentProjectsKey = 'recent_project_paths';

  @override
  ProjectState build() {
    // Load recent projects asynchronously
    _loadRecentProjects();
    return const ProjectState();
  }

  /// Load recent projects from SharedPreferences
  Future<void> _loadRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPaths = prefs.getStringList(_recentProjectsKey) ?? [];

    // Filter out paths that no longer exist on disk
    final validPaths = <String>[];
    for (final path in savedPaths) {
      if (File(path).existsSync()) {
        validPaths.add(path);
      }
    }

    // Limit to 10 recent projects
    final limitedPaths = validPaths.take(10).toList();

    // Save filtered list back if paths were removed
    if (limitedPaths.length != savedPaths.length) {
      await prefs.setStringList(_recentProjectsKey, limitedPaths);
    }

    state = state.copyWith(recentProjectPaths: limitedPaths);
  }

  /// Save recent projects to SharedPreferences
  Future<void> _saveRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentProjectsKey, state.recentProjectPaths);
  }

  /// Create a new project
  Future<void> createProject({
    required String name,
    required String directoryPath,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final projectService = ref.read(projectServiceProvider);
      final project = await projectService.createProject(
        name: name,
        directoryPath: directoryPath,
      );

      state = state.copyWith(
        isLoading: false,
        currentProject: project,
        recentProjectPaths: [
          project.projectPath,
          ...state.recentProjectPaths
              .where((p) => p != project.projectPath)
              .take(9),
        ],
      );
      await _saveRecentProjects();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create project: $e',
      );
    }
  }

  /// Create a new project with a specific file path
  Future<void> createProjectWithPath({
    required String name,
    required String projectPath,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final projectService = ref.read(projectServiceProvider);
      final project = await projectService.createProjectWithPath(
        name: name,
        projectPath: projectPath,
      );

      state = state.copyWith(
        isLoading: false,
        currentProject: project,
        recentProjectPaths: [
          project.projectPath,
          ...state.recentProjectPaths
              .where((p) => p != project.projectPath)
              .take(9),
        ],
      );
      await _saveRecentProjects();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create project: $e',
      );
    }
  }

  /// Open an existing project
  Future<void> openProject(String projectPath) async {
    state = state.copyWith(isLoading: true);
    try {
      final projectService = ref.read(projectServiceProvider);
      final project = await projectService.loadProject(projectPath);

      state = state.copyWith(
        isLoading: false,
        currentProject: project,
        recentProjectPaths: [
          project.projectPath,
          ...state.recentProjectPaths
              .where((p) => p != project.projectPath)
              .take(9),
        ],
      );
      await _saveRecentProjects();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to open project: $e',
      );
    }
  }

  /// Save the current project
  Future<void> saveProject() async {
    if (state.currentProject == null) return;

    state = state.copyWith(isSaving: true);
    try {
      final projectService = ref.read(projectServiceProvider);
      await projectService.saveProject(state.currentProject!);
      // Clear dirty flag after successful save
      state = state.copyWith(
        isSaving: false,
        currentProject: state.currentProject!.copyWith(isDirty: false),
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save project: $e',
      );
    }
  }

  /// Close the current project
  Future<void> closeProject() async {
    // Don't auto-save on close - let the UI handle asking user
    state = state.copyWith(
      clearProject: true,
      undoStack: [],
      redoStack: [],
    );
  }

  /// Clear all recent projects
  Future<void> clearRecentProjects() async {
    state = state.copyWith(recentProjectPaths: []);
    await _saveRecentProjects();
  }

  /// Push current state to undo stack
  void _pushUndo() {
    if (state.currentProject == null) return;

    // Limit undo stack size to 50 items
    final newStack = [...state.undoStack, state.currentProject!];
    if (newStack.length > 50) {
      newStack.removeAt(0);
    }

    state = state.copyWith(
      undoStack: newStack,
      redoStack: [], // Clear redo stack on new action
    );
  }

  /// Undo last action
  void undo() {
    if (!state.canUndo || state.currentProject == null) return;

    final newUndoStack = [...state.undoStack];
    final previousState = newUndoStack.removeLast();

    state = state.copyWith(
      undoStack: newUndoStack,
      redoStack: [...state.redoStack, state.currentProject!],
      currentProject: previousState.copyWith(isDirty: true),
    );
  }

  /// Redo last undone action
  void redo() {
    if (!state.canRedo || state.currentProject == null) return;

    final newRedoStack = [...state.redoStack];
    final nextState = newRedoStack.removeLast();

    state = state.copyWith(
      redoStack: newRedoStack,
      undoStack: [...state.undoStack, state.currentProject!],
      currentProject: nextState.copyWith(isDirty: true),
    );
  }

  /// Import a media file into the project
  Future<void> importMedia(MediaFile media) async {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      mediaFiles: [...state.currentProject!.mediaFiles, media],
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
    await saveProject();
  }

  /// Remove a media file from the project
  Future<void> removeMedia(String mediaId) async {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      mediaFiles: state.currentProject!.mediaFiles
          .where((m) => m.id != mediaId)
          .toList(),
      detections: state.currentProject!.detections
          .where((d) => d.mediaId != mediaId)
          .toList(),
      editActions: state.currentProject!.editActions
          .where((e) => e.mediaId != mediaId)
          .toList(),
      selectedMediaId: state.currentProject!.selectedMediaId == mediaId
          ? null
          : state.currentProject!.selectedMediaId,
      modifiedAt: DateTime.now(),
    );

    state = state.copyWith(currentProject: updatedProject);
    await saveProject();
  }

  /// Select a media file for editing
  void selectMedia(String? mediaId) {
    if (state.currentProject == null) return;

    final updatedProject = state.currentProject!.copyWith(
      selectedMediaId: mediaId,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Add a detection to the project
  void addDetection(Detection detection) {
    if (state.currentProject == null) return;

    final updatedProject = state.currentProject!.copyWith(
      detections: [...state.currentProject!.detections, detection],
      modifiedAt: DateTime.now(),
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Add multiple detections to the project
  void addDetections(List<Detection> detections) {
    if (state.currentProject == null) return;

    final updatedProject = state.currentProject!.copyWith(
      detections: [...state.currentProject!.detections, ...detections],
      modifiedAt: DateTime.now(),
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Update a detection
  void updateDetection(Detection detection) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      detections: state.currentProject!.detections
          .map((d) => d.id == detection.id ? detection : d)
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Remove a detection (Note: we keep rejected detections, don't delete)
  void removeDetection(String detectionId) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      detections: state.currentProject!.detections
          .where((d) => d.id != detectionId)
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Remove multiple detections
  void removeDetections(List<String> detectionIds) {
    if (state.currentProject == null) return;

    _pushUndo();
    final idsSet = detectionIds.toSet();
    final updatedProject = state.currentProject!.copyWith(
      detections: state.currentProject!.detections
          .where((d) => !idsSet.contains(d.id))
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Remove all detections for a media file
  void removeAllDetections(String mediaId) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      detections: state.currentProject!.detections
          .where((d) => d.mediaId != mediaId)
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Add an edit action
  void addEditAction(
    String mediaId,
    Duration startTime,
    Duration endTime,
    EditActionType type, {
    BoundingBox? boundingBox,
    String? detectionId,
  }) {
    if (state.currentProject == null) return;

    _pushUndo();
    final action = EditAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mediaId: mediaId,
      type: type,
      startTime: startTime,
      endTime: endTime,
      boundingBox: boundingBox,
      detectionId: detectionId,
    );

    final updatedProject = state.currentProject!.copyWith(
      editActions: [...state.currentProject!.editActions, action],
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Add an edit action object directly
  void addEditActionDirect(EditAction action) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      editActions: [...state.currentProject!.editActions, action],
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Update an edit action
  void updateEditAction(EditAction action) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      editActions: state.currentProject!.editActions
          .map((e) => e.id == action.id ? action : e)
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Remove an edit action
  void removeEditAction(String actionId) {
    if (state.currentProject == null) return;

    _pushUndo();
    final updatedProject = state.currentProject!.copyWith(
      editActions: state.currentProject!.editActions
          .where((e) => e.id != actionId)
          .toList(),
      modifiedAt: DateTime.now(),
      isDirty: true,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Update analysis progress
  void updateAnalysisProgress(double progress) {
    if (state.currentProject == null) return;

    final updatedProject = state.currentProject!.copyWith(
      analysisProgress: progress,
      analysisComplete: progress >= 1.0,
    );

    state = state.copyWith(currentProject: updatedProject);
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith();
  }
}
