import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen with app information, legal disclaimers, and attributions
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appName = 'KidsLens Video Editor';
  static const String _appVersion = '1.0.0';
  static const String _appLegalese = '© 2024 KidsLens. All rights reserved.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo and Title
                _AppHeaderCard(
                  appName: _appName,
                  appVersion: _appVersion,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),

                // Legal Disclaimer
                _SectionCard(
                  title: 'Important Notice',
                  icon: Icons.warning_amber_rounded,
                  iconColor: colorScheme.error,
                  child: const _LegalDisclaimerContent(),
                ),
                const SizedBox(height: 16),

                // Model Attributions
                _SectionCard(
                  title: 'AI Model Attributions',
                  icon: Icons.smart_toy_rounded,
                  iconColor: colorScheme.primary,
                  child: const _ModelAttributionsContent(),
                ),
                const SizedBox(height: 16),

                // Privacy Statement
                _SectionCard(
                  title: 'Privacy',
                  icon: Icons.privacy_tip_rounded,
                  iconColor: colorScheme.secondary,
                  child: const _PrivacyStatementContent(),
                ),
                const SizedBox(height: 16),

                // Documentation Links
                _SectionCard(
                  title: 'Documentation',
                  icon: Icons.menu_book_rounded,
                  iconColor: colorScheme.tertiary,
                  child: const _DocumentationLinksContent(),
                ),
                const SizedBox(height: 16),

                // Licenses Button
                const _LicensesCard(
                  appName: _appName,
                  appVersion: _appVersion,
                  appLegalese: _appLegalese,
                ),
                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Text(
                    _appLegalese,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeaderCard extends StatelessWidget {
  const _AppHeaderCard({
    required this.appName,
    required this.appVersion,
    required this.colorScheme,
  });

  final String appName;
  final String appVersion;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.movie_filter_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $appVersion',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI-powered video content moderation for family-friendly content',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegalDisclaimerContent extends StatelessWidget {
  const _LegalDisclaimerContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Detection Limitations',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'KidsLens uses artificial intelligence to detect potentially inappropriate content '
          'in videos. While our AI models are trained to identify profanity, nudity, violence, '
          'and other sensitive content, no automated system is perfect.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Always manually review AI detections before publishing content. '
                  'False positives and missed detections may occur. '
                  'The developers are not responsible for content that passes through undetected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelAttributionsContent extends StatelessWidget {
  const _ModelAttributionsContent();

  @override
  Widget build(BuildContext context) => const Column(
      children: [
        _AttributionTile(
          name: 'Whisper',
          organization: 'OpenAI',
          description: 'Automatic speech recognition for audio transcription',
          licenseType: 'MIT License',
        ),
        Divider(height: 16),
        _AttributionTile(
          name: 'ONNX Runtime',
          organization: 'Microsoft',
          description: 'Cross-platform machine learning inference',
          licenseType: 'MIT License',
        ),
        Divider(height: 16),
        _AttributionTile(
          name: 'FFmpeg',
          organization: 'FFmpeg Team',
          description: 'Video and audio processing',
          licenseType: 'LGPL v2.1+',
        ),
      ],
    );
}

class _AttributionTile extends StatelessWidget {
  const _AttributionTile({
    required this.name,
    required this.organization,
    required this.description,
    required this.licenseType,
  });

  final String name;
  final String organization;
  final String description;
  final String licenseType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.extension_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'by $organization',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  licenseType,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyStatementContent extends StatelessWidget {
  const _PrivacyStatementContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PrivacyFeatureRow(
          icon: Icons.computer,
          title: '100% Local Processing',
          description:
              'All video analysis runs entirely on your device. Your videos never leave your computer.',
        ),
        const SizedBox(height: 12),
        const _PrivacyFeatureRow(
          icon: Icons.cloud_off,
          title: 'No Cloud Upload',
          description:
              'We do not upload, transmit, or store any of your video content on external servers.',
        ),
        const SizedBox(height: 12),
        const _PrivacyFeatureRow(
          icon: Icons.visibility_off,
          title: 'No Tracking',
          description:
              'KidsLens does not collect analytics, usage data, or personal information.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your privacy is our priority. Edit with confidence.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyFeatureRow extends StatelessWidget {
  const _PrivacyFeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentationLinksContent extends StatelessWidget {
  const _DocumentationLinksContent();

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
      children: [
        _DocumentationLinkTile(
          icon: Icons.play_circle_outline,
          title: 'Getting Started',
          subtitle: 'Learn the basics of using KidsLens',
          onTap: () => _launchUrl('https://kidslens.app/docs/getting-started'),
        ),
        _DocumentationLinkTile(
          icon: Icons.architecture,
          title: 'Architecture',
          subtitle: 'Technical overview of the application',
          onTap: () => _launchUrl('https://kidslens.app/docs/architecture'),
        ),
        _DocumentationLinkTile(
          icon: Icons.api,
          title: 'API Reference',
          subtitle: 'Detailed API documentation',
          onTap: () => _launchUrl('https://kidslens.app/docs/api'),
        ),
        _DocumentationLinkTile(
          icon: Icons.bug_report,
          title: 'Report an Issue',
          subtitle: 'Found a bug? Let us know',
          onTap: () =>
              _launchUrl('https://github.com/kidslens/video-editor/issues'),
        ),
      ],
    );
}

class _DocumentationLinkTile extends StatelessWidget {
  const _DocumentationLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.open_in_new,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _LicensesCard extends StatelessWidget {
  const _LicensesCard({
    required this.appName,
    required this.appVersion,
    required this.appLegalese,
  });

  final String appName;
  final String appVersion;
  final String appLegalese;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          Icons.description_rounded,
          color: colorScheme.primary,
        ),
        title: const Text('Open Source Licenses'),
        subtitle: const Text('View licenses for all third-party packages'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showLicensePage(
          context: context,
          applicationName: appName,
          applicationVersion: appVersion,
          applicationLegalese: appLegalese,
          applicationIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.movie_filter_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
