import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/it_dev/presentation/system_health_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';

class ITDevDashboard extends ConsumerWidget {
  final bool showScaffold;
  const ITDevDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);
    final dashboardData = ref.watch(dashboardDataProvider);

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref, layout, dashboardData),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'SYSTEM BACKBONE',
      subtitle: 'API status, system health, and deployments',
      children: [
        _buildContent(context, ref, layout, dashboardData),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardLayout layout, DashboardData data) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: layout.sections.map((section) => _buildSection(context, ref, section, data)).toList(),
      );
    }

    // Desktop 2-column layout
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, ref, section, data);
      
      if (section == DashboardSection.metrics || section == DashboardSection.actions) {
        leftColumn.add(sectionWidget);
        leftColumn.add(const SizedBox(height: 48));
      } else {
        rightColumn.add(sectionWidget);
        rightColumn.add(const SizedBox(height: 48));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn,
          ),
        ),
        if (rightColumn.isNotEmpty) ...[
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rightColumn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(BuildContext context, WidgetRef ref, DashboardSection section, DashboardData data) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection(data);
      case DashboardSection.actions:
        return _buildActionsSection(context);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('System & Fleet Overview'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          tabletCrossAxisCount: 4,
          children: [
            DashboardStatCard(
              label: 'Active Riders',
              value: data.activeRiders.toString(),
              icon: Icons.motorcycle_rounded,
              color: Colors.green,
              trend: 'Using the platform',
            ),
            DashboardStatCard(
              label: 'Active Groups',
              value: data.activeGroups.toString(),
              icon: Icons.groups_rounded,
              color: Colors.blue,
              trend: 'Operational',
            ),
            DashboardStatCard(
              label: 'Fleet Health',
              value: '${data.assetHealth}%',
              icon: Icons.storage_outlined,
              color: Colors.teal,
              trend: 'Vehicles operational',
            ),
            DashboardStatCard(
              label: 'Active Incidents',
              value: data.activeIncidents.toString(),
              icon: Icons.bug_report_outlined,
              color: AppColors.error,
              trend: data.activeIncidents > 0 ? 'Action required' : 'No critical alerts',
              isPositive: data.activeIncidents == 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Developer & API Console'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 2,
          childAspectRatio: 2.2,
          children: [
            DashboardActionCard(
              title: 'API Bridge Monitor',
              subtitle: 'Noon, Amazon, and Keeta API health',
              icon: Icons.api_outlined,
              color: Colors.indigo,
              onTap: () {},
            ),
            DashboardActionCard(
              title: 'System Health Screen',
              subtitle: 'Detailed uptime and security logs',
              icon: Icons.health_and_safety_outlined,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SystemHealthScreen()));
              },
            ),
            DashboardActionCard(
              title: 'Deployment Hub',
              subtitle: 'Manage production and staging pushes',
              icon: Icons.system_update_alt_outlined,
              color: Colors.blueGrey,
              onTap: () {},
            ),
            DashboardActionCard(
              title: 'Database Admin',
              subtitle: 'Direct Supabase & storage access',
              icon: Icons.table_chart_outlined,
              color: Colors.orange,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
