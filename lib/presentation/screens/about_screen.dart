import 'package:flutter/material.dart';

/// About screen with app info and licenses
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';
  static const String _buildNumber = '1';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('About'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAppInfo(context),
            const SizedBox(height: 24),
            _buildFeatures(context),
            const SizedBox(height: 24),
            _buildCredits(context),
            const SizedBox(height: 24),
            _buildLegalSection(context),
          ],
        ),
      );

  Widget _buildAppInfo(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.visibility,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KidsLens',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Video Content Safety Editor',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $_version (Build $_buildNumber)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

  Widget _buildFeatures(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const _FeatureItem(
              icon: Icons.mic_off,
              title: 'Profanity Detection',
              description: 'AI-powered audio analysis to detect profane language',
            ),
            const _FeatureItem(
              icon: Icons.visibility_off,
              title: 'Visual Content Analysis',
              description: 'Detect nudity, violence, and other sensitive content',
            ),
            const _FeatureItem(
              icon: Icons.edit,
              title: 'Smart Editing',
              description: 'Automatic muting, blurring, or cutting of detected content',
            ),
            const _FeatureItem(
              icon: Icons.language,
              title: 'Multi-Language Support',
              description: 'English, Spanish, Arabic and more languages',
            ),
            const _FeatureItem(
              icon: Icons.computer,
              title: '100% Offline Processing',
              description: 'All AI processing happens locally on your device',
            ),
          ],
        ),
      ),
    );

  Widget _buildCredits(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open Source Credits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const _CreditItem(
              name: 'whisper.cpp',
              description: 'Speech recognition',
              license: 'MIT License',
            ),
            const _CreditItem(
              name: 'FFmpeg',
              description: 'Media processing',
              license: 'LGPL/GPL License',
            ),
            const _CreditItem(
              name: 'ONNX Runtime',
              description: 'AI model inference',
              license: 'MIT License',
            ),
            const _CreditItem(
              name: 'Meta MMS',
              description: 'Language identification',
              license: 'CC-BY-NC 4.0',
            ),
          ],
        ),
      ),
    );

  Widget _buildLegalSection(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Open Source Licenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLicenses(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyPolicy(context),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '© 2024 KidsLens. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'KidsLens',
      applicationVersion: _version,
      applicationLegalese: '© 2024 KidsLens. All rights reserved.',
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'KidsLens processes all media files locally on your device. '
            'No data is sent to external servers.\n\n'
            'We do not collect, store, or transmit any personal information '
            'or media content.\n\n'
            'AI models are downloaded from official sources and stored locally. '
            'Model download requires an internet connection, but all processing '
            'is performed offline.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
}

class _CreditItem extends StatelessWidget {
  const _CreditItem({
    required this.name,
    required this.description,
    required this.license,
  });

  final String name;
  final String description;
  final String license;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              license,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
}
