import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/matching_data_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/capacity_planning_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/hr/presentation/staff_management_screen.dart';
import 'package:walim_logistics/features/inspections/presentation/inspection_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/group_setup_screen.dart';
import 'package:walim_logistics/features/admin/presentation/shift_planner_screen.dart';
import 'package:walim_logistics/features/admin/presentation/supervisor_schedule_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';

class OpsManagerDashboard extends ConsumerWidget {
  final bool showScaffold;
  const OpsManagerDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final layout = ref.watch(dashboardLayoutProvider);

    if (dashboardData.isLoading && dashboardData.activeRiders == 0) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, dashboardData, layout),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'OPERATIONS CONTROL',
      subtitle: 'Real-time fleet intelligence and strategic allocation',
      children: [
        _buildHeader(context, dashboardData),
        const SizedBox(height: 32),
        _buildContent(context, dashboardData, layout),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Operations Manager',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Your fleet is operating at 94% efficiency today. ${data.activeIncidents} incidents require your attention.',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, DashboardData data, DashboardLayout layout) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: layout.sections.map((section) => _buildSection(context, data, section)).toList(),
      );
    }

    // Desktop 2-column layout
    // We try to maintain the 2-column feel but respect the order
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, data, section);
      
      // Heuristic: metrics and actions go to left, activity and intelligence to right
      if (section == DashboardSection.metrics || section == DashboardSection.actions) {
        leftColumn.add(sectionWidget);
        leftColumn.add(const SizedBox(height: 32));
      } else {
        rightColumn.add(sectionWidget);
        rightColumn.add(const SizedBox(height: 32));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn,
          ),
        ),
        if (rightColumn.isNotEmpty) ...[
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rightColumn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(BuildContext context, DashboardData data, DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection(context, data);
      case DashboardSection.actions:
        return _buildActionsSection(context, data);
      case DashboardSection.activity:
        return _buildActivitySection(context, data);
      case DashboardSection.intelligence:
        return _buildIntelligenceSection(context, data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Core Performance Metrics'),
        const SizedBox(height: 20),
        ResponsiveGrid(
          desktopCrossAxisCount: 4,
          tabletCrossAxisCount: 4,
          mobileCrossAxisCount: 2,
          spacing: 12,
          childAspectRatio: 2.1,
          children: [
            DashboardStatCard(
              label: 'Overall SLA',
              value: '98.5%',
              icon: Icons.assignment_turned_in_outlined,
              color: Colors.green,
              trend: 'Target: 97%',
              sparklineData: [95, 96, 94, 98, 97, 98.5],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorDashboard())),
            ),
            DashboardStatCard(
              label: 'Fleet Utilization',
              value: '94%',
              icon: Icons.local_shipping_outlined,
              color: Colors.blue,
              trend: 'All zones active',
              sparklineData: [85, 88, 90, 92, 94, 94],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapacityPlanningScreen())),
            ),
            DashboardStatCard(
              label: 'Active Incidents',
              value: data.activeIncidents.toString(),
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              trend: '${data.activeIncidents} Critical',
              isPositive: data.activeIncidents == 0,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen())),
            ),
            DashboardStatCard(
              label: 'Peak Capacity',
              value: _formatCount(data.peakCapacity),
              icon: Icons.trending_up_outlined,
              color: Colors.purple,
              trend: 'Theoretical',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapacityPlanningScreen())),
            ),
            DashboardStatCard(
              label: 'Active Riders',
              value: _formatCount(data.activeRiders),
              icon: Icons.motorcycle_rounded,
              color: Colors.teal,
              trend: 'Peak capacity',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
            ),
            DashboardStatCard(
              label: 'Active Groups',
              value: data.activeGroups.toString(),
              icon: Icons.groups_rounded,
              color: Colors.indigo,
              trend: 'All active',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSetupScreen())),
            ),
            DashboardStatCard(
              label: 'Inactive Riders',
              value: data.inactiveRiders.toString(),
              icon: Icons.person_off_outlined,
              color: Colors.redAccent,
              trend: 'Action needed',
              isPositive: data.inactiveRiders == 0,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
            ),
            DashboardStatCard(
              label: 'Asset Health',
              value: '${data.assetHealth}%',
              icon: Icons.health_and_safety_outlined,
              color: Colors.green,
              trend: 'Stable',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Management Console'),
        const SizedBox(height: 20),
        ResponsiveGrid(
          mobileCrossAxisCount: 2,
          tabletCrossAxisCount: 3,
          desktopCrossAxisCount: 3,
          childAspectRatio: 2.2,
          spacing: 16,
          children: [
            DashboardActionCard(
              title: 'Fleet Mix Allocation',
              subtitle: 'Balance Vans vs Bikes',
              icon: Icons.swap_horiz_outlined,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapacityPlanningScreen())),
            ),
            DashboardActionCard(
              title: 'SLA Monitoring Hub',
              subtitle: 'Real-time agreement status',
              icon: Icons.speed_outlined,
              color: Colors.green,
              badge: 'LIVE',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorDashboard())),
            ),
            DashboardActionCard(
              title: 'Capacity Planning',
              subtitle: 'Peak season forecasting',
              icon: Icons.calendar_today_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapacityPlanningScreen())),
            ),
            DashboardActionCard(
              title: 'Group Management',
              subtitle: 'Create groups and assign riders',
              icon: Icons.groups_rounded,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSetupScreen())),
            ),
            DashboardActionCard(
              title: 'Shift Planner',
              subtitle: 'Generate rider shift plans',
              icon: Icons.event_note_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftPlannerScreen())),
            ),
            DashboardActionCard(
              title: 'Supervisor Schedule',
              subtitle: 'Assign supervisors to groups',
              icon: Icons.assignment_ind_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorScheduleScreen())),
            ),
            DashboardActionCard(
              title: 'Matching Data Center',
              subtitle: 'Platform report reconciliation',
              icon: Icons.analytics_outlined,
              color: Colors.purple,
              badge: 'NEW',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchingDataScreen())),
            ),
            DashboardActionCard(
              title: 'Global Asset View',
              subtitle: 'Accountability for all equipment',
              icon: Icons.inventory_2_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen())),
            ),
            DashboardActionCard(
              title: 'Staff Monitoring',
              subtitle: 'Manage all organization roles',
              icon: Icons.people_outline_rounded,
              color: Colors.blueGrey,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
            ),
            DashboardActionCard(
              title: 'Safety & Inspections',
              subtitle: 'Daily vehicle safety checks',
              icon: Icons.security_rounded,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Live Activity'),
        const SizedBox(height: 20),
        ActivityFeed(
          onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen())),
          items: data.recentActivity.isEmpty 
            ? [
                ActivityItem(
                  title: 'No recent activity',
                  subtitle: 'All systems operational',
                  time: 'Now',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                )
              ]
            : data.recentActivity.map((item) => ActivityItem(
                title: item['title'],
                subtitle: item['subtitle'],
                time: item['time'],
                icon: item['type'] == 'incident' ? Icons.warning_rounded : Icons.event_note_rounded,
                color: item['type'] == 'incident' ? Colors.red : Colors.blue,
                onTap: () {
                  if (item['type'] == 'incident') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen()));
                  } else {
                    // Navigate to leave requests or other relevant screens
                  }
                },
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildIntelligenceSection(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Intelligence Hub'),
        const SizedBox(height: 20),
        Text(
          'PLATFORM SLA',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (data.platforms.isEmpty)
          Text('No platforms registered', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
        else
          ...data.platforms.map((p) => Column(
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorDashboard())),
                child: _buildSLACard(p['name'], 0.98, _getPlatformColor(p['name'])),
              ),
              const SizedBox(height: 12),
            ],
          )),
        const SizedBox(height: 32),
        Text(
          'CAPACITY FORECAST',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildForecastChart(data),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Color _getPlatformColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('amazon')) return Colors.blue;
    if (lowerName.contains('keeta')) return Colors.orange;
    if (lowerName.contains('noon')) return Colors.amber;
    return Colors.teal;
  }

  Widget _buildSLACard(String platform, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                platform, 
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(score * 100).toInt()}%', 
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900, 
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    height: 8,
                    width: constraints.maxWidth * score,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Target: 97%',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Hiring',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${(data.peakCapacity * 0.15).toInt()} Riders Needed',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.trending_up, color: AppColors.primary, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('${data.activeRiders}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('${data.peakCapacity}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buffer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('15%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
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
