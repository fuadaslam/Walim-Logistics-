import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class LayoutSettingsScreen extends ConsumerWidget {
  const LayoutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);

    return DashboardScaffold(
      title: 'DASHBOARD SETTINGS',
      subtitle: 'Customize your dashboard layout and priorities',
      showBackButton: true,
      activeItem: 'Settings',
      body: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Active Sections', 'Drag to reorder your dashboard sections'),
            const SizedBox(height: 16),
            _buildReorderableList(context, ref, layout.sections, true),
            const SizedBox(height: 48),
            _buildSectionHeader('Hidden Sections', 'Toggle to show these sections on your dashboard'),
            const SizedBox(height: 16),
            _buildInactiveList(context, ref, layout.hiddenSections),
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(dashboardLayoutProvider.notifier).resetToDefault(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset to Default Layout'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableList(BuildContext context, WidgetRef ref, List<DashboardSection> sections, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha:0.5)),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(dashboardLayoutProvider.notifier).reorderSections(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSectionTile(context, ref, section, index, true);
        },
      ),
    );
  }

  Widget _buildInactiveList(BuildContext context, WidgetRef ref, List<DashboardSection> sections) {
    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha:0.3), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('No hidden sections', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha:0.5)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSectionTile(context, ref, section, index, false);
        },
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, WidgetRef ref, DashboardSection section, int index, bool isActive) {
    return ListTile(
      key: ValueKey(section),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getSectionColor(section).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_getSectionIcon(section), color: _getSectionColor(section), size: 20),
      ),
      title: Text(
        _getSectionTitle(section),
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        _getSectionDescription(section),
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: isActive,
            activeColor: AppColors.primary,
            onChanged: (value) => ref.read(dashboardLayoutProvider.notifier).toggleSection(section),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            const Icon(Icons.drag_indicator_rounded, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }

  String _getSectionTitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics: return 'Core Metrics';
      case DashboardSection.actions: return 'Management Console';
      case DashboardSection.activity: return 'Live Activity Feed';

      case DashboardSection.compliance: return 'Compliance Watch';
      case DashboardSection.performance: return 'Performance Analysis';
    }
  }

  String _getSectionDescription(DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics: return 'Key performance indicators and status overview';
      case DashboardSection.actions: return 'Quick access to management tools and modules';
      case DashboardSection.activity: return 'Real-time log of recent platform events';

      case DashboardSection.compliance: return 'Regulatory status and document expiration alerts';
      case DashboardSection.performance: return 'Detailed revenue and margin analysis';
    }
  }

  IconData _getSectionIcon(DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics: return Icons.analytics_rounded;
      case DashboardSection.actions: return Icons.grid_view_rounded;
      case DashboardSection.activity: return Icons.notifications_active_rounded;

      case DashboardSection.compliance: return Icons.verified_user_rounded;
      case DashboardSection.performance: return Icons.trending_up_rounded;
    }
  }

  Color _getSectionColor(DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics: return Colors.blue;
      case DashboardSection.actions: return Colors.indigo;
      case DashboardSection.activity: return Colors.orange;

      case DashboardSection.compliance: return Colors.red;
      case DashboardSection.performance: return Colors.green;
    }
  }
}
