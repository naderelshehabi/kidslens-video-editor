import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/presentation/screens/editor_screen.dart';
import 'package:kidslens_video_editor/services/project_service.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';

class KidsLensApp extends StatelessWidget {
  const KidsLensApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KidsLens Video Editor',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.dark, // Video editors typically use dark theme
        home: const _WelcomeScreen(),
      );

  ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
          secondary: const Color(0xFF2196F3),
          error: const Color(0xFFE57373),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      );

  ThemeData _buildDarkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
          secondary: const Color(0xFF42A5F5),
          error: const Color(0xFFEF9A9A),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      );
}

/// Welcome screen with New/Open Project options
class _WelcomeScreen extends ConsumerStatefulWidget {
  const _WelcomeScreen();

  @override
  ConsumerState<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<_WelcomeScreen> {
  final _projectNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectState = ref.watch(projectNotifierProvider);

    // If a project is open, navigate to the editor
    if (projectState.hasProject) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const EditorScreen(),
          ),
        );
      });
    }

    // Show error if there is one
    if (projectState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectState.errorMessage!),
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(projectNotifierProvider.notifier).clearError();
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and title
                    Icon(
                      Icons.movie_filter_rounded,
                      size: 72,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'KidsLens Video Editor',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create safe media for the whole family',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Loading or buttons
                    if (_isLoading || projectState.isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading...'),
                        ],
                      )
                    else ...[
                      // New Project button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showNewProjectDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Project'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Open Project button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openProject,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Open Project'),
                        ),
                      ),
                    ],
                    
                    // Recent projects section
                    if (projectState.recentProjectPaths.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Recent Projects',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...projectState.recentProjectPaths.take(3).map(
                        (path) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(
                            path.split(RegExp(r'[\\/]')).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => ref
                              .read(projectNotifierProvider.notifier)
                              .openProject(path),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNewProjectDialog(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Open native file save dialog
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Create New Project',
        fileName: 'Untitled.${ProjectService.projectExtension}',
        type: FileType.custom,
        allowedExtensions: [ProjectService.projectExtension],
      );

      if (result == null) {
        // User cancelled
        return;
      }

      // Extract filename without extension as initial title
      final fileName = result.split(RegExp(r'[\\/]')).last;
      final initialTitle = fileName.endsWith('.${ProjectService.projectExtension}')
          ? fileName.substring(0, fileName.length - '.${ProjectService.projectExtension}'.length)
          : fileName;

      // Show dialog to allow editing the title
      _projectNameController.text = initialTitle;
      
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Project Title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  hintText: 'Enter a display name for your project',
                ),
                autofocus: true,
                onSubmitted: (_) => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              Text(
                'File: $fileName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (confirmed == true && _projectNameController.text.isNotEmpty) {
        await _createProject(
          name: _projectNameController.text,
          filePath: result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createProject({
    required String name,
    required String filePath,
  }) async {
    try {
      await ref.read(projectNotifierProvider.notifier).createProjectWithPath(
        name: name,
        projectPath: filePath,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openProject() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [ProjectService.projectExtension],
        allowMultiple: false,
        dialogTitle: 'Open KidsLens Project',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await ref
              .read(projectNotifierProvider.notifier)
              .openProject(file.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
