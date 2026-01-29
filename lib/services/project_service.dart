import 'dart:convert';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/project.dart';
import 'package:path/path.dart' as p;

/// Service for managing KidsLens Editor project files (.kle)
class ProjectService {
  /// File extension for KidsLens Editor project files
  static const String projectExtension = 'kle';

  /// File filter description
  static const String fileFilterDescription = 'KidsLens Project';

  /// Create a new project file
  Future<Project> createProject({
    required String name,
    required String directoryPath,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sanitizedName = _sanitizeFileName(name);
    final projectPath = p.join(directoryPath, '$sanitizedName.$projectExtension');

    final project = Project.create(
      id: id,
      name: name,
      projectPath: projectPath,
    );

    // Save the initial project file
    await saveProject(project);

    return project;
  }

  /// Create a new project file with a specific path
  Future<Project> createProjectWithPath({
    required String name,
    required String projectPath,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Ensure the path has the correct extension
    final normalizedPath = projectPath.endsWith('.$projectExtension')
        ? projectPath
        : '$projectPath.$projectExtension';

    final project = Project.create(
      id: id,
      name: name,
      projectPath: normalizedPath,
    );

    // Save the initial project file
    await saveProject(project);

    return project;
  }

  /// Save a project to its file
  Future<void> saveProject(Project project) async {
    final file = File(project.projectPath);
    
    // Update the modified timestamp
    final updatedProject = project.copyWith(
      modifiedAt: DateTime.now(),
    );

    final jsonString = const JsonEncoder.withIndent('  ').convert(
      updatedProject.toJson(),
    );

    await file.writeAsString(jsonString);
  }

  /// Load a project from a file
  Future<Project> loadProject(String projectPath) async {
    final file = File(projectPath);

    if (!file.existsSync()) {
      throw ProjectNotFoundException(projectPath);
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (e) {
      throw ProjectLoadException(projectPath, e.toString());
    }
  }

  /// Check if a project file exists
  Future<bool> projectExists(String projectPath) async =>
      File(projectPath).existsSync();

  /// Get recent projects from a directory
  Future<List<ProjectInfo>> getRecentProjects(String searchDirectory) async {
    final projects = <ProjectInfo>[];
    final dir = Directory(searchDirectory);

    if (!dir.existsSync()) {
      return projects;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.$projectExtension')) {
        try {
          final project = await loadProject(entity.path);
          projects.add(ProjectInfo(
            name: project.name,
            path: project.projectPath,
            modifiedAt: project.modifiedAt,
            mediaCount: project.mediaFiles.length,
          ),);
        } catch (_) {
          // Skip invalid project files
        }
      }
    }

    // Sort by most recently modified
    projects.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return projects;
  }

  /// Delete a project file
  Future<void> deleteProject(String projectPath) async {
    final file = File(projectPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Export project as a backup
  Future<String> exportProject(Project project, String exportPath) async {
    final file = File(exportPath);
    final jsonString = const JsonEncoder.withIndent('  ').convert(
      project.toJson(),
    );
    await file.writeAsString(jsonString);
    return exportPath;
  }

  /// Sanitize a file name by removing invalid characters
  String _sanitizeFileName(String name) => name
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
}

/// Basic info about a project for listing
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    required this.path,
    required this.modifiedAt,
    required this.mediaCount,
  });

  final String name;
  final String path;
  final DateTime modifiedAt;
  final int mediaCount;
}

/// Exception thrown when a project file is not found
class ProjectNotFoundException implements Exception {
  ProjectNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'Project not found: $path';
}

/// Exception thrown when a project fails to load
class ProjectLoadException implements Exception {
  ProjectLoadException(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'Failed to load project at $path: $reason';
}
