import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/fleet/presentation/live_tracking_screen.dart';
import 'package:last_mile_fleet/features/incidents/presentation/incident_approval_screen.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/matching_data_screen.dart';

class SupervisorDashboard extends ConsumerWidget {
  final bool showScaffold;
  const SupervisorDashboard({super.key, this.showScaffold = true});

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
      title: 'PERFORMANCE HUB',
      subtitle: 'Oversee operations and resolve blockers',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Stats
        _buildSectionHeader('Fleet Performance Metrics'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Avg. Time/Deliv',
              value: '18.4m',
              icon: Icons.timer_outlined,
              color: AppColors.accent,
              trend: '-2.1m (Improving)',
              isPositive: true,
              sparklineData: [22, 21, 20, 19, 18.5, 18.4],
            ),
            DashboardStatCard(
              label: 'Delivery Success',
              value: '98.2%',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              trend: 'Above benchmark',
              sparklineData: [95, 96, 97, 97.5, 98, 98.2],
            ),
            DashboardStatCard(
              label: 'Live Incidents',
              value: '4',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              trend: 'Action Required',
              isPositive: false,
            ),
            DashboardStatCard(
              label: 'Active Riders',
              value: '142',
              icon: Icons.motorcycle_rounded,
              color: Colors.blue,
              trend: 'Across all zones',
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
                  _buildSectionHeader('Operations & Incident Hub'),
                  const SizedBox(height: 24),
                  ResponsiveGrid(
                    mobileCrossAxisCount: 1,
                    tabletCrossAxisCount: 2,
                    desktopCrossAxisCount: 2,
                    childAspectRatio: 2.2,
                    children: [
                      DashboardActionCard(
                        title: 'Live Heatmaps',
                        subtitle: 'Rider concentration vs Demand',
                        icon: Icons.layers_outlined,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveTrackingScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Incident Approvals',
                        subtitle: 'Approve delay & accident justifications',
                        icon: Icons.fact_check_outlined,
                        color: Colors.red,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IncidentApprovalScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Matching Data reports',
                        subtitle: 'Daily/Weekly platform reconciliation',
                        icon: Icons.analytics_outlined,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MatchingDataScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Shift Cluster Manager',
                        subtitle: 'Assign riders to high-demand zones',
                        icon: Icons.grid_view_rounded,
                        color: Colors.blue,
                        onTap: () {},
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
                  _buildSectionHeader('Platform Distribution'),
                  const SizedBox(height: 24),
                  _buildPlatformShare('Noon Food', 0.45, Colors.amber),
                  const SizedBox(height: 12),
                  _buildPlatformShare('Keeta (Meituan)', 0.35, Colors.teal),
                  const SizedBox(height: 12),
                  _buildPlatformShare('Amazon SA', 0.20, Colors.orange),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Open Incidents'),
                  const SizedBox(height: 24),
                  _buildSmallIncidentItem('Khalid M.', 'Delay justification', '10m ago'),
                  const Divider(height: 24),
                  _buildSmallIncidentItem('Youssef A.', 'Accident report', '1h ago'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformShare(String name, double share, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('${(share * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSmallIncidentItem(String rider, String type, String time) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rider, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
