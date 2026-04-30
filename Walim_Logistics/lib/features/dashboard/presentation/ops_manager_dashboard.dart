import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/matching_data_screen.dart';

class OpsManagerDashboard extends ConsumerWidget {
  final bool showScaffold;
  const OpsManagerDashboard({super.key, this.showScaffold = true});

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
      title: 'OPERATIONS STRATEGY',
      subtitle: 'Fleet allocation, SLA monitoring, and capacity planning',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Core Strategy Metrics
        _buildSectionHeader('Operational Performance'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Overall SLA',
              value: '98.5%',
              icon: Icons.assignment_turned_in_outlined,
              color: Colors.green,
              trend: 'Target: 97%',
              sparklineData: [95, 96, 94, 98, 97, 98.5],
            ),
            DashboardStatCard(
              label: 'Fleet Utilization',
              value: '94%',
              icon: Icons.local_shipping_outlined,
              color: Colors.blue,
              trend: 'All zones active',
              sparklineData: [85, 88, 90, 92, 94, 94],
            ),
            DashboardStatCard(
              label: 'Active Clusters',
              value: '14',
              icon: Icons.grid_view_outlined,
              color: Colors.orange,
              trend: 'Riyadh & Jeddah',
            ),
            DashboardStatCard(
              label: 'Peak Capacity',
              value: '1.2k',
              icon: Icons.trending_up_outlined,
              color: Colors.teal,
              trend: 'Ramadan Ready',
            ),
          ],
        ),

        const SizedBox(height: 48),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Strategic Tools
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Fleet & Capacity Management'),
                  const SizedBox(height: 24),
                  ResponsiveGrid(
                    mobileCrossAxisCount: 1,
                    tabletCrossAxisCount: 2,
                    desktopCrossAxisCount: 2,
                    childAspectRatio: 2.2,
                    children: [
                      DashboardActionCard(
                        title: 'Fleet Mix Allocation',
                        subtitle: 'Balance Vans (Amazon) vs Bikes (Keeta)',
                        icon: Icons.swap_horiz_outlined,
                        color: Colors.indigo,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'SLA Monitoring Hub',
                        subtitle: 'Real-time agreement status per platform',
                        icon: Icons.speed_outlined,
                        color: Colors.green,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Capacity Planning',
                        subtitle: 'Peak season forecasting (White Friday)',
                        icon: Icons.calendar_today_outlined,
                        color: Colors.orange,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Cluster Shift Manager',
                        subtitle: 'Assign teams to specific city zones',
                        icon: Icons.map_outlined,
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Matching Data Center',
                        subtitle: 'Daily platform report reconciliation',
                        icon: Icons.analytics_outlined,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchingDataScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Global Asset View',
                        subtitle: 'Accountability for all fleet equipment',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.teal,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Side: SLA & Heatmaps
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Platform SLA Status'),
                  const SizedBox(height: 24),
                  _buildSLACard('Amazon Logistics', 0.99, Colors.blue),
                  const SizedBox(height: 12),
                  _buildSLACard('Keeta (Meituan)', 0.97, Colors.orange),
                  const SizedBox(height: 12),
                  _buildSLACard('Noon Food', 0.96, Colors.amber),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Capacity Forecast'),
                  const SizedBox(height: 24),
                  _buildForecastChart(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSLACard(String platform, double score, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(platform, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text('${(score * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Peak Season Forecast: +25% Demand',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Recommended Hiring: 42 Riders',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
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
