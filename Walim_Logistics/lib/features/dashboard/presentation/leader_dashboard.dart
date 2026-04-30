import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/fleet/presentation/shift_assignment_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/group_management_screen.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_report_screen.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

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
                _buildContent(context),
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
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Stats
        _buildSectionHeader('Group Readiness'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Active Team',
              value: '12 Riders',
              icon: Icons.people_rounded,
              color: AppColors.primary,
              trend: 'All Checked-in',
            ),
            DashboardStatCard(
              label: 'Fleet Readiness',
              value: '10/12',
              icon: Icons.motorcycle_rounded,
              color: Colors.green,
              trend: '2 in maintenance',
            ),
            DashboardStatCard(
              label: 'Pending Handovers',
              value: '3 Items',
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.orange,
              trend: 'Bags & Uniforms',
            ),
            DashboardStatCard(
              label: 'Reported Issues',
              value: '1',
              icon: Icons.report_problem_outlined,
              color: AppColors.error,
              trend: 'Action needed',
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
                        subtitle: 'Manage 12 team members',
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
                  _buildSectionHeader('Team Status'),
                  const SizedBox(height: 24),
                  _buildRiderStatusItem(context, 'Ahmed Khan', 'On Duty', true),
                  const SizedBox(height: 12),
                  _buildRiderStatusItem(context, 'Mohammed S.', 'Break', false),
                  const SizedBox(height: 12),
                  _buildRiderStatusItem(context, 'Zaid Ali', 'On Duty', true),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Urgent Alerts'),
                  const SizedBox(height: 24),
                  _buildAlertCard('Vehicle #422 reported stolen', Colors.red),
                  const SizedBox(height: 12),
                  _buildAlertCard('Safety Gear check required for New Joiner', Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiderStatusItem(BuildContext context, String name, String status, bool isActive) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDetailScreen()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              decoration: BoxDecoration(color: isActive ? Colors.green : Colors.orange, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(status, style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
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
