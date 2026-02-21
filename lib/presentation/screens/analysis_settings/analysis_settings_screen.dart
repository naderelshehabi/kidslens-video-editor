import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/content_detection_tab.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/model_config_tab.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/models_management_tab.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/performance_tab.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/thresholds_tab.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Navigation tab items for analysis settings
enum AnalysisSettingsTab {
  modelsManagement('Models Management', Icons.inventory_2),
  contentDetection('Content Detection', Icons.shield),
  thresholds('Thresholds', Icons.tune),
  configuration('Configuration', Icons.settings),
  performance('Performance', Icons.speed);

  const AnalysisSettingsTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Main screen for configuring AI analysis settings
class AnalysisSettingsScreen extends ConsumerStatefulWidget {
  const AnalysisSettingsScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<AnalysisSettingsScreen> createState() =>
      _AnalysisSettingsScreenState();
}

class _AnalysisSettingsScreenState
    extends ConsumerState<AnalysisSettingsScreen> {
  late AnalysisSettingsTab _selectedTab;

  @override
  void initState() {
    super.initState();
    // Set initial tab based on parameter or default to Models Management
    _selectedTab = widget.initialTab != null &&
            widget.initialTab! < AnalysisSettingsTab.values.length
        ? AnalysisSettingsTab.values[widget.initialTab!]
        : AnalysisSettingsTab.modelsManagement;
    // Load available models when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelNotifierProvider.notifier).loadAvailableModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch providers for state changes
    final modelState = ref.watch(modelNotifierProvider);
    final settingsState = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (modelState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(modelNotifierProvider.notifier).loadAvailableModels();
            },
            tooltip: 'Refresh models',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation rail on the left
          NavigationRail(
            selectedIndex: _selectedTab.index,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTab = AnalysisSettingsTab.values[index];
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: colorScheme.surfaceContainerLow,
            destinations: AnalysisSettingsTab.values
                .map(
                  (tab) => NavigationRailDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.icon),
                    label: Text(tab.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content area
          Expanded(
            child: _buildContent(modelState, settingsState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ModelState modelState, SettingsState settingsState) {
    // Show error banner if there's an error
    if (modelState.errorMessage != null) {
      return Column(
        children: [
          MaterialBanner(
            content: Text(modelState.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            contentTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(modelNotifierProvider.notifier).clearError();
                },
                child: const Text('Dismiss'),
              ),
            ],
          ),
          Expanded(child: _buildTabContent(modelState, settingsState)),
        ],
      );
    }

    return _buildTabContent(modelState, settingsState);
  }

  Widget _buildTabContent(ModelState modelState, SettingsState settingsState) {
    switch (_selectedTab) {
      case AnalysisSettingsTab.modelsManagement:
        return const ModelsManagementTab();
      case AnalysisSettingsTab.contentDetection:
        return const ContentDetectionTab();
      case AnalysisSettingsTab.thresholds:
        return const ThresholdsTab();
      case AnalysisSettingsTab.configuration:
        return const ModelConfigTab();
      case AnalysisSettingsTab.performance:
        return const PerformanceTab();
    }
  }
}
