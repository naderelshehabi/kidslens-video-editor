import 'package:flutter/material.dart';

/// Onboarding screen for first-time users
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    const _OnboardingPage(
      icon: Icons.visibility,
      title: 'Welcome to KidsLens',
      description:
          'Make your videos safe for all audiences by detecting and removing inappropriate content.',
    ),
    const _OnboardingPage(
      icon: Icons.smart_toy,
      title: 'AI-Powered Analysis',
      description:
          'Our advanced AI models detect profanity, nudity, violence, and other sensitive content automatically.',
    ),
    const _OnboardingPage(
      icon: Icons.computer,
      title: '100% Private',
      description:
          'All processing happens locally on your device. Your videos never leave your computer.',
    ),
    const _OnboardingPage(
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            _buildIndicators(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pages.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

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
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}
