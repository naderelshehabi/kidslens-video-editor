import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/core/constants/supported_formats.dart';
import 'package:kidslens_video_editor/presentation/screens/home_screen.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';

class KidsLensApp extends StatelessWidget {
  const KidsLensApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KidsLens Video Editor',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const _HomeScreen(),
      );

  ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Family-friendly green
          brightness: Brightness.light,
          secondary: const Color(0xFF2196F3), // Calming blue
          error: const Color(0xFFE57373), // Softer red for errors
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
          seedColor: const Color(0xFF4CAF50), // Family-friendly green
          brightness: Brightness.dark,
          secondary:
              const Color(0xFF42A5F5), // Calming blue (lighter for dark theme)
          error: const Color(0xFFEF9A9A), // Softer red for errors
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

class _HomeScreen extends ConsumerStatefulWidget {
  const _HomeScreen();

  @override
  ConsumerState<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<_HomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaState = ref.watch(mediaNotifierProvider);

    // If media is loaded, navigate to the main home screen
    if (mediaState.currentMedia != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const HomeScreen(),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KidsLens Video Editor'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_rounded,
              size: 96,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to KidsLens',
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
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              FilledButton.icon(
                onPressed: () => _pickVideoFile(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Project'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _pickVideoFile(context),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Open Project'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideoFile(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...SupportedFormats.videoContainers,
          ...SupportedFormats.audioFormats,
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await ref
              .read(mediaNotifierProvider.notifier)
              .importMedia(file.path!);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
