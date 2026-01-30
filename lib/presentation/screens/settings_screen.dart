import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings keys for SharedPreferences
class SettingsKeys {
  static const String themeMode = 'settings_theme_mode';
  static const String defaultExportQuality = 'settings_export_quality';
  static const String defaultExportFormat = 'settings_export_format';
  static const String autoSaveInterval = 'settings_auto_save_interval';
  static const String modelCachePath = 'settings_model_cache_path';
}

/// Export quality options
enum ExportQuality {
  low('Low (480p)', 480),
  medium('Medium (720p)', 720),
  high('High (1080p)', 1080),
  ultra('Ultra (4K)', 2160),
  original('Original', 0);

  const ExportQuality(this.label, this.height);
  final String label;
  final int height;
}

/// Export format options
enum ExportFormat {
  mp4('MP4 (H.264)', 'mp4'),
  webm('WebM (VP9)', 'webm'),
  mov('MOV (ProRes)', 'mov');

  const ExportFormat(this.label, this.extension);
  final String label;
  final String extension;
}

/// Application settings screen with preferences for appearance, export, and cache
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Settings values
  ThemeMode _themeMode = ThemeMode.system;
  ExportQuality _exportQuality = ExportQuality.high;
  ExportFormat _exportFormat = ExportFormat.mp4;
  int _autoSaveInterval = 5; // minutes
  String? _modelCachePath;

  // Cache info
  String _cacheSize = 'Calculating...';
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateCacheSize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt(SettingsKeys.themeMode) ?? 0];
      _exportQuality = ExportQuality
          .values[prefs.getInt(SettingsKeys.defaultExportQuality) ?? 2];
      _exportFormat = ExportFormat
          .values[prefs.getInt(SettingsKeys.defaultExportFormat) ?? 0];
      _autoSaveInterval = prefs.getInt(SettingsKeys.autoSaveInterval) ?? 5;
      _modelCachePath = prefs.getString(SettingsKeys.modelCachePath);
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.themeMode, mode.index);
    setState(() => _themeMode = mode);
  }

  Future<void> _saveExportQuality(ExportQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.defaultExportQuality, quality.index);
    setState(() => _exportQuality = quality);
  }

  Future<void> _saveExportFormat(ExportFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.defaultExportFormat, format.index);
    setState(() => _exportFormat = format);
  }

  Future<void> _saveAutoSaveInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.autoSaveInterval, minutes);
    setState(() => _autoSaveInterval = minutes);
  }

  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appCacheDir = Directory('${cacheDir.path}/kidslens_cache');

      if (appCacheDir.existsSync()) {
        var totalSize = 0;
        await for (final entity
            in appCacheDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
        setState(() => _cacheSize = _formatBytes(totalSize));
      } else {
        setState(() => _cacheSize = '0 B');
      }
    } catch (e) {
      setState(() => _cacheSize = 'Unable to calculate');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached thumbnails, model files, and temporary data. '
          'Downloaded AI models will need to be re-downloaded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearingCache = true);

    try {
      final cacheDir = await getTemporaryDirectory();
      final appCacheDir = Directory('${cacheDir.path}/kidslens_cache');

      if (appCacheDir.existsSync()) {
        await appCacheDir.delete(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isClearingCache = false);
      await _calculateCacheSize();
    }
  }

  Future<void> _changeModelsLocation() async {
    final controller = TextEditingController(text: _modelCachePath ?? '');
    
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Models Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose where to store AI models. Leave empty for default location.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Models Directory Path',
                hintText: 'e.g., D:\\AI Models',
                border: OutlineInputBorder(),
                helperText: 'Models will need to be re-downloaded after changing',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Use Default'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newPath == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (newPath.isEmpty) {
        await prefs.remove(SettingsKeys.modelCachePath);
        ref.read(settingsNotifierProvider.notifier).setModelCachePath('');
        setState(() => _modelCachePath = null);
      } else {
        // Validate the path
        final dir = Directory(newPath);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        await prefs.setString(SettingsKeys.modelCachePath, newPath);
        ref.read(settingsNotifierProvider.notifier).setModelCachePath(newPath);
        setState(() => _modelCachePath = newPath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Models location updated. Downloaded models will need to be re-downloaded.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid path: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _SectionHeader(
                  icon: Icons.palette_rounded,
                  title: 'Appearance',
                  color: colorScheme.primary,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_6_rounded),
                        title: const Text('Theme Mode'),
                        subtitle: Text(_themeModeLabel(_themeMode)),
                        trailing: DropdownButton<ThemeMode>(
                          value: _themeMode,
                          underline: const SizedBox.shrink(),
                          onChanged: (mode) {
                            if (mode != null) _saveThemeMode(mode);
                          },
                          items: ThemeMode.values.map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(_themeModeLabel(mode)),
                            ),).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Export Section
                _SectionHeader(
                  icon: Icons.movie_creation_rounded,
                  title: 'Export Defaults',
                  color: colorScheme.secondary,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.high_quality_rounded),
                        title: const Text('Default Quality'),
                        subtitle: Text(_exportQuality.label),
                        trailing: DropdownButton<ExportQuality>(
                          value: _exportQuality,
                          underline: const SizedBox.shrink(),
                          onChanged: (quality) {
                            if (quality != null) _saveExportQuality(quality);
                          },
                          items: ExportQuality.values.map((quality) => DropdownMenuItem(
                              value: quality,
                              child: Text(quality.label),
                            ),).toList(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.video_file_rounded),
                        title: const Text('Default Format'),
                        subtitle: Text(_exportFormat.label),
                        trailing: DropdownButton<ExportFormat>(
                          value: _exportFormat,
                          underline: const SizedBox.shrink(),
                          onChanged: (format) {
                            if (format != null) _saveExportFormat(format);
                          },
                          items: ExportFormat.values.map((format) => DropdownMenuItem(
                              value: format,
                              child: Text(format.label),
                            ),).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Auto-Save Section
                _SectionHeader(
                  icon: Icons.save_rounded,
                  title: 'Auto-Save',
                  color: colorScheme.tertiary,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.timer_rounded),
                        title: const Text('Auto-Save Interval'),
                        subtitle: Text('Every $_autoSaveInterval minutes'),
                        trailing: DropdownButton<int>(
                          value: _autoSaveInterval,
                          underline: const SizedBox.shrink(),
                          onChanged: (value) {
                            if (value != null) _saveAutoSaveInterval(value);
                          },
                          items: [1, 2, 5, 10, 15, 30].map((minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes min'),
                            ),).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cache Section
                const _SectionHeader(
                  icon: Icons.storage_rounded,
                  title: 'Cache & Storage',
                  color: Colors.orange,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.smart_toy_rounded),
                        title: const Text('AI Models Location'),
                        subtitle: Text(
                          _modelCachePath ?? 'Default (App Data)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: TextButton.icon(
                          onPressed: _changeModelsLocation,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Change'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_rounded),
                        title: const Text('Cache Size'),
                        subtitle: Text(_cacheSize),
                        trailing: _isClearingCache
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton.icon(
                                onPressed: _clearCache,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Clear'),
                              ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: const Text('Refresh Cache Info'),
                        onTap: _calculateCacheSize,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reset Section
                _SectionHeader(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset',
                  color: colorScheme.error,
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.restore_rounded,
                      color: colorScheme.error,
                    ),
                    title: const Text('Reset All Settings'),
                    subtitle: const Text('Restore default settings'),
                    trailing: OutlinedButton(
                      onPressed: _resetSettings,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will restore all settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SettingsKeys.themeMode);
    await prefs.remove(SettingsKeys.defaultExportQuality);
    await prefs.remove(SettingsKeys.defaultExportFormat);
    await prefs.remove(SettingsKeys.autoSaveInterval);

    // Reset Riverpod state
    ref.read(settingsNotifierProvider.notifier).resetToDefaults();

    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
