import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/fleet/presentation/shift_assignment_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/group_management_screen.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_report_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';

class LeaderDashboard extends ConsumerWidget {
  final bool showScaffold;
  const LeaderDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'LEADER PORTAL',
      subtitle: 'Manage your team and inventory flow',
      children: [
        _buildContent(context, ref),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Stats
        _buildSectionHeader('Group Readiness'),
        const SizedBox(height: 24),
        if (data.isLoading && data.activeRiders == 0)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
        else
        ResponsiveGrid(
          children: [
            DashboardStatCard(
              label: 'Active Riders',
              value: data.activeRiders.toString(),
              icon: Icons.people_rounded,
              color: AppColors.primary,
              trend: 'SOS: ${data.checkedInToday}',
            ),
            DashboardStatCard(
              label: 'Fleet Health',
              value: '${data.assetHealth}%',
              icon: Icons.motorcycle_rounded,
              color: Colors.green,
              trend: 'Vehicles operational',
            ),
            DashboardStatCard(
              label: 'Pending Inspections',
              value: data.pendingInspections.toString(),
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.orange,
              trend: 'Today',
            ),
            DashboardStatCard(
              label: 'Active Incidents',
              value: data.activeIncidents.toString(),
              icon: Icons.report_problem_outlined,
              color: AppColors.error,
              trend: data.activeIncidents == 0 ? 'All clear' : 'Action needed',
            ),
          ],
        ),

        const SizedBox(height: 48),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Team & Field Operations'),
                  const SizedBox(height: 24),
                  ResponsiveGrid(
                    mobileCrossAxisCount: 1,
                    tabletCrossAxisCount: 2,
                    desktopCrossAxisCount: 2,
                    childAspectRatio: 2.2,
                    children: [
                      DashboardActionCard(
                        title: 'Group Management',
                        subtitle: 'Manage your team members',
                        icon: Icons.groups_outlined,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupManagementScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Asset Registry',
                        subtitle: 'Manage fleet assets and insurance',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.purple,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
                          },
                      ),
                      DashboardActionCard(
                        title: 'Vehicle Status',
                        subtitle: 'Monitor conditions & report issues',
                        icon: Icons.minor_crash_outlined,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IncidentReportScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Shift Assignments',
                        subtitle: 'Assign riders to specific clusters',
                        icon: Icons.grid_view_rounded,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShiftAssignmentScreen()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Recent Activity'),
                  const SizedBox(height: 24),
                  ActivityFeed(
                    items: data.recentActivity.map((a) {
                      final type = a['type'] as String? ?? '';
                      IconData icon;
                      Color color;
                      switch (type) {
                        case 'incident':
                          icon = Icons.warning_rounded;
                          color = Colors.red;
                          break;
                        case 'leave':
                          icon = Icons.person_off_outlined;
                          color = Colors.orange;
                          break;
                        case 'inspection':
                          icon = Icons.checklist_rounded;
                          color = Colors.green;
                          break;
                        default:
                          icon = Icons.info_outline;
                          color = Colors.blue;
                      }
                      return ActivityItem(
                        title: a['title'] as String? ?? '',
                        subtitle: a['subtitle'] as String? ?? '',
                        time: a['time'] as String? ?? '',
                        icon: icon,
                        color: color,
                      );
                    }).toList(),
                  ),
                ],
              ),
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
