import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/presentation/screens/about_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/model_selection_screen.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Analysis Settings',
            [
              _buildSliderTile(
                context,
                'NSFW Threshold',
                'Sensitivity for detecting NSFW content',
                settings.analysisSettings.nsfwThreshold,
                (value) => _updateThreshold(ref, 'nsfw', value),
              ),
              _buildSliderTile(
                context,
                'Violence Threshold',
                'Sensitivity for detecting violence',
                settings.analysisSettings.violenceThreshold,
                (value) => _updateThreshold(ref, 'violence', value),
              ),
              _buildSliderTile(
                context,
                'Blood Threshold',
                'Sensitivity for detecting blood and gore',
                settings.analysisSettings.bloodThreshold,
                (value) => _updateThreshold(ref, 'blood', value),
              ),
              _buildSliderTile(
                context,
                'Weapons Threshold',
                'Sensitivity for detecting weapons',
                settings.analysisSettings.weaponsThreshold,
                (value) => _updateThreshold(ref, 'weapons', value),
              ),
            ],
          ),
          _buildSection(
            context,
            'Detection Options',
            [
              SwitchListTile(
                title: const Text('Detect Profanity'),
                subtitle: const Text('Analyze audio for profane language'),
                value: settings.analysisSettings.enableProfanity,
                onChanged: (value) => _updateDetection(ref, 'profanity', value),
              ),
              SwitchListTile(
                title: const Text('Detect NSFW'),
                subtitle: const Text('Analyze video for NSFW content'),
                value: settings.analysisSettings.enableNsfw,
                onChanged: (value) => _updateDetection(ref, 'nsfw', value),
              ),
              SwitchListTile(
                title: const Text('Detect Violence'),
                subtitle: const Text('Analyze video for violent content'),
                value: settings.analysisSettings.enableViolence,
                onChanged: (value) => _updateDetection(ref, 'violence', value),
              ),
              SwitchListTile(
                title: const Text('Detect Blood'),
                subtitle: const Text('Analyze video for blood and gore'),
                value: settings.analysisSettings.enableBlood,
                onChanged: (value) => _updateDetection(ref, 'blood', value),
              ),
              SwitchListTile(
                title: const Text('Detect Weapons'),
                subtitle: const Text('Analyze video for weapons'),
                value: settings.analysisSettings.enableWeapons,
                onChanged: (value) => _updateDetection(ref, 'weapons', value),
              ),
            ],
          ),
          _buildSection(
            context,
            'AI Models',
            [
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Manage Models'),
                subtitle: const Text('Download and configure AI models'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openModelSelection(context),
              ),
            ],
          ),
          _buildSection(
            context,
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Theme'),
                subtitle: const Text('Use dark color scheme'),
                value: settings.useDarkTheme,
                onChanged: (value) {
                  ref.read(settingsNotifierProvider.notifier).setDarkTheme(useDark: value);
                },
              ),
            ],
          ),
          _buildSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About KidsLens'),
                subtitle: const Text('Version, licenses, and attributions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openAbout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    String subtitle,
    double value,
    ValueChanged<double> onChanged,
  ) => ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Slider(
            value: value,
            min: 0.1,
            divisions: 9,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );

  void _updateThreshold(WidgetRef ref, String type, double value) {
    final current = ref.read(settingsNotifierProvider).analysisSettings;
    final updated = switch (type) {
      'nsfw' => current.copyWith(nsfwThreshold: value),
      'violence' => current.copyWith(violenceThreshold: value),
      'blood' => current.copyWith(bloodThreshold: value),
      'weapons' => current.copyWith(weaponsThreshold: value),
      _ => current,
    };
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _updateDetection(WidgetRef ref, String type, bool value) {
    final current = ref.read(settingsNotifierProvider).analysisSettings;
    final updated = switch (type) {
      'profanity' => current.copyWith(enableProfanity: value),
      'nsfw' => current.copyWith(enableNsfw: value),
      'violence' => current.copyWith(enableViolence: value),
      'blood' => current.copyWith(enableBlood: value),
      'weapons' => current.copyWith(enableWeapons: value),
      _ => current,
    };
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _openModelSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ModelSelectionScreen(),
      ),
    );
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AboutScreen(),
      ),
    );
  }
}
