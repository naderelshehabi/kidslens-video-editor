import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/presentation/screens/about_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/analysis_settings_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/editor_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/services/project_service.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsLensApp extends ConsumerStatefulWidget {
  const KidsLensApp({super.key});

  @override
  ConsumerState<KidsLensApp> createState() => _KidsLensAppState();

  /// Navigate to analysis settings
  static void navigateToAnalysisSettings(BuildContext context) {
    Navigator.pushNamed(context, '/analysis-settings');
  }

  /// Navigate to settings
  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  /// Navigate to about screen
  static void navigateToAbout(BuildContext context) {
    Navigator.pushNamed(context, '/about');
  }

  /// Navigate to editor screen
  static void navigateToEditor(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/editor');
  }
}

class _KidsLensAppState extends ConsumerState<KidsLensApp> {
  @override
  void initState() {
    super.initState();
    // Load persisted settings first so model cache path is applied, then
    // validate downloaded models against disk at startup.
    Future<void>(() async {
      await ref.read(settingsNotifierProvider.notifier).loadSettings();
      await ref.read(modelNotifierProvider.notifier).loadAvailableModels();
      await ref.read(llamaServerManagerProvider).cleanupStaleChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      title: 'KidsLens Video Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const _OnboardingWrapper(),
      routes: {
        '/analysis-settings': (context) => const AnalysisSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes that require arguments
        switch (settings.name) {
          case '/editor':
            return MaterialPageRoute<void>(
              builder: (context) => const EditorScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}

/// Wrapper to check if onboarding should be shown
class _OnboardingWrapper extends StatefulWidget {
  const _OnboardingWrapper();

  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  static const _onboardingCompleteKey = 'onboarding_complete';
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    setState(() => _showOnboarding = !onboardingComplete);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding!) {
      return _OnboardingScreen(onComplete: _completeOnboarding);
    }

    return const _WelcomeScreen();
  }
}

/// Onboarding screen for first-time users
class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.movie_filter_rounded,
      title: 'Welcome to KidsLens',
      description:
          'Make your videos safe for all audiences by detecting and removing inappropriate content.',
    ),
    _OnboardingPage(
      icon: Icons.smart_toy,
      title: 'AI-Powered Analysis',
      description:
          'Our advanced AI models detect profanity, nudity, violence, and other sensitive content automatically.',
    ),
    _OnboardingPage(
      icon: Icons.computer,
      title: '100% Private',
      description:
          'All processing happens locally on your device. Your videos never leave your computer.',
    ),
    _OnboardingPage(
      icon: Icons.auto_fix_high,
      title: 'Smart Editing',
      description:
          'Automatically mute, blur, or cut detected content. Review and customize before exporting.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _pages[index],
                ),
              ),
              _buildIndicators(),
              _buildButtons(),
            ],
          ),
        ),
      );

  Widget _buildIndicators() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );

  Widget _buildButtons() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _controller.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            )
          else
            TextButton(
              onPressed: widget.onComplete,
              child: const Text('Skip'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: isLastPage
                ? widget.onComplete
                : () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
            child: Text(isLastPage ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
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
      body: DecoratedBox(
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
        child: Stack(
          children: [
            // Background logo watermark
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 350,
                    height: 350,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Gracefully handle missing logo
                      debugPrint('Logo not found: $error');
                      return Icon(
                        Icons.movie_filter_rounded,
                        size: 350,
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
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

                        // Loading indicator for buttons only
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

                        // Recent projects section - always visible when there are projects
                        if (projectState.recentProjectPaths.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Projects',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(projectNotifierProvider.notifier)
                                    .clearRecentProjects(),
                                icon: Icon(
                                  Icons.clear_all_rounded,
                                  size: 18,
                                  color: colorScheme.outline,
                                ),
                                label: Text(
                                  'Clear Recent',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...projectState.recentProjectPaths.take(5).map(
                            (path) {
                              final fileName =
                                  path.split(RegExp(r'[\\/]')).last;
                              final projectName = fileName.endsWith('.kidslens')
                                  ? fileName.substring(0, fileName.length - 9)
                                  : fileName;
                              // Get directory path for preview
                              final pathParts = path.split(RegExp(r'[\\/]'));
                              final dirPreview = pathParts.length > 2
                                  ? '.../${pathParts.sublist(pathParts.length - 2, pathParts.length - 1).join('/')}'
                                  : path;

                              return Card(
                                elevation: 0,
                                color: colorScheme.surfaceContainerLow,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.movie_outlined,
                                      color: colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    projectName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    dirPreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: colorScheme.outline,
                                  ),
                                  onTap: () => ref
                                      .read(projectNotifierProvider.notifier)
                                      .openProject(path),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewProjectDialog(BuildContext context) async {
    setState(() => _isLoading = true);

    // Capture context-dependent values before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

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
      final initialTitle = fileName
              .endsWith('.${ProjectService.projectExtension}')
          ? fileName.substring(
              0,
              fileName.length - '.${ProjectService.projectExtension}'.length,
            )
          : fileName;

      // Show dialog to allow editing the title
      _projectNameController.text = initialTitle;

      if (!mounted) return;

      // Schedule the dialog to run in the next frame to avoid BuildContext async gap
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
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
                  onSubmitted: (_) => Navigator.of(dialogCtx).pop(true),
                ),
                const SizedBox(height: 8),
                Text(
                  'File: $fileName',
                  style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(dialogCtx).colorScheme.outline,
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Create'),
              ),
            ],
          ),
        );

        if ((confirmed ?? false) && _projectNameController.text.isNotEmpty) {
          await _createProject(
            name: _projectNameController.text,
            filePath: result,
          );
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: errorColor,
        ),
      );
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
