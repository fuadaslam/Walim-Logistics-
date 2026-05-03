import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/it_dev/presentation/system_health_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';

class ITDevDashboard extends ConsumerWidget {
  final bool showScaffold;
  const ITDevDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref, layout),
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
        _buildContent(context, ref, layout),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardLayout layout) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: layout.sections.map((section) => _buildSection(context, ref, section)).toList(),
      );
    }

    // Desktop 2-column layout
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, ref, section);
      
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

  Widget _buildSection(BuildContext context, WidgetRef ref, DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection();
      case DashboardSection.actions:
        return _buildActionsSection(context);
      case DashboardSection.intelligence:
        return _buildIntelligenceSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('System Performance'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Server Uptime',
              value: '99.99%',
              icon: Icons.dns_outlined,
              color: Colors.green,
              trend: 'All systems operational',
              sparklineData: [99.98, 99.99, 99.99, 99.99, 99.99, 99.99],
            ),
            DashboardStatCard(
              label: 'API Latency',
              value: '42ms',
              icon: Icons.speed_outlined,
              color: Colors.blue,
              trend: 'Optimized',
              sparklineData: [50, 48, 45, 43, 42, 42],
            ),
            DashboardStatCard(
              label: 'Database Health',
              value: '100%',
              icon: Icons.storage_outlined,
              color: Colors.teal,
              trend: 'Clean state',
            ),
            DashboardStatCard(
              label: 'Active Errors',
              value: '0',
              icon: Icons.bug_report_outlined,
              color: AppColors.error,
              trend: 'No critical alerts',
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

  Widget _buildIntelligenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('API Integrations'),
        const SizedBox(height: 24),
        _buildAPIStatusItem('Amazon Logistics Bridge', true),
        const SizedBox(height: 12),
        _buildAPIStatusItem('Noon Partner API', true),
        const SizedBox(height: 12),
        _buildAPIStatusItem('Keeta (Meituan) SDK', true),
        const SizedBox(height: 12),
        _buildAPIStatusItem('Tookan Task Bridge', false), // Simulated offline/alert
      ],
    );
  }

  Widget _buildAPIStatusItem(String name, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Text(
            isOnline ? 'ONLINE' : 'LATENCY',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
