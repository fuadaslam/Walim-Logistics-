import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/fleet/presentation/live_tracking_screen.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_approval_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/matching_data_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/office_request_alert.dart';
import 'package:walim_logistics/features/supervisor/presentation/daily_shift_control_screen.dart';
import 'package:walim_logistics/features/supervisor/presentation/supervisor_group_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/tracking/screens/rider_tracking_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/admin_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/leaderboard_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/my_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/performance_calculation_screen.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';

class SupervisorDashboard extends ConsumerWidget {
  final bool showScaffold;
  const SupervisorDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final layout = ref.watch(dashboardLayoutProvider);

    if (dashboardData.isLoading && dashboardData.activeRiders == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      title: 'PERFORMANCE HUB',
      subtitle: 'Oversee operations and resolve blockers',
      showBackButton: true,
      children: [
        _buildContent(context, ref, layout, dashboardData),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardLayout layout, DashboardData data) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: [
          if (ref.watch(authProvider).profile != null)
            OfficeRequestAlert(profileId: ref.watch(authProvider).profile!.id),
          ...layout.sections.map((section) => _buildSection(context, ref, section, data)).toList(),
        ],
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
            children: [
              if (ref.watch(authProvider).profile != null)
                OfficeRequestAlert(profileId: ref.watch(authProvider).profile!.id),
              ...leftColumn,
            ],
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
        return _buildMetricsSection(context, ref, data);
      case DashboardSection.actions:
        return _buildActionsSection(context, ref);
      case DashboardSection.activity:
        return _buildActivitySection(data);
      case DashboardSection.intelligence:
        return _buildIntelligenceSection(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(BuildContext context, WidgetRef ref, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary action cards (Hero)
        _buildDailyShiftHero(context),
        const SizedBox(height: 12),
        _buildMyGroupHero(context),
        const SizedBox(height: 32),

        _buildSectionHeader('Fleet Performance Metrics'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          tabletCrossAxisCount: 4,
          children: [
            DashboardStatCard(
              label: 'Avg. Time/Deliv',
              value: '18.4m',
              icon: Icons.timer_outlined,
              color: AppColors.accent,
              trend: '-2.1m (Improving)',
              isPositive: true,
              sparklineData: const [22, 21, 20, 19, 18.5, 18.4],
            ),
            DashboardStatCard(
              label: 'Delivery Success',
              value: '98.2%',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              trend: 'Above benchmark',
              sparklineData: const [95, 96, 97, 97.5, 98, 98.2],
            ),
            DashboardStatCard(
              label: 'Live Incidents',
              value: data.activeIncidents.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              trend: data.activeIncidents > 0 ? 'Action Required' : 'All Clear',
              isPositive: data.activeIncidents == 0,
            ),
            DashboardStatCard(
              label: 'Active Riders',
              value: data.activeRiders.toString(),
              icon: Icons.motorcycle_rounded,
              color: Colors.blue,
              trend: 'Across all zones',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref) {
    return Column(
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
              title: 'Live Rider Tracking',
              subtitle: 'Monitor your group in real-time',
              icon: Icons.my_location_rounded,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderTrackingScreen()));
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
            DashboardActionCard(
              title: 'Performance Management',
              subtitle: 'Issue bonuses, penalties & set targets',
              icon: Icons.military_tech_rounded,
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPerformanceScreen()));
              },
            ),
            DashboardActionCard(
              title: 'Leaderboard',
              subtitle: 'Top riders and supervisors this month',
              icon: Icons.leaderboard_rounded,
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              },
            ),
            if (ref.read(authProvider).profile?.role == 'Admin' || 
                ref.read(authProvider).profile?.role == 'Operations Manager')
              DashboardActionCard(
                title: 'Scoring Configuration',
                subtitle: 'Design how performance scores are calculated',
                icon: Icons.settings_suggest_rounded,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerformanceCalculationScreen()));
                },
              ),
            if (ref.read(authProvider).profile?.role != 'Admin' && 
                ref.read(authProvider).profile?.role != 'Operations Manager')
              DashboardActionCard(
                title: 'My Performance',
                subtitle: 'Your score, targets and adjustments',
                icon: Icons.bar_chart_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPerformanceScreen()));
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Live Operational Feed'),
        const SizedBox(height: 24),
        if (data.recentActivity.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.notifications_none_rounded,
            title: 'No recent activity',
            subtitle: 'All systems operational. New updates will appear here in real-time.',
          )
        else
          ...data.recentActivity.map((activity) => Column(
            children: [
              _buildSmallIncidentItem(
                activity['title'] ?? 'Unknown',
                activity['subtitle'] ?? '',
                activity['time'] ?? '',
                type: activity['type'] ?? 'other',
              ),
              const Divider(height: 24),
            ],
          )),
      ],
    );
  }

  Widget _buildIntelligenceSection(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Platform Distribution'),
        const SizedBox(height: 24),
        if (data.platformShare.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No data available',
            subtitle: 'Waiting for platform distribution data to be processed.',
            color: Colors.indigo,
          )
        else
          ...data.platformShare.map((p) => Column(
            children: [
              _buildPlatformShare(p['name'], p['share'], p['color']),
              const SizedBox(height: 12),
            ],
          )),
      ],
    );
  }

  Widget _buildMyGroupHero(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SupervisorGroupScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded,
                  size: 26, color: Colors.teal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Group',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    'View riders, today\'s attendance status and shift details',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.teal.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.teal, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyShiftHero(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const DailyShiftControlScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.assignment_turned_in_rounded,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Shift Control',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SOS · EOS · Attendance · Platform Report · Validation',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
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

  Widget _buildSmallIncidentItem(String title, String subtitle, String time, {String type = 'incident'}) {
    IconData icon;
    Color color;

    switch (type) {
      case 'incident':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'leave':
        icon = Icons.event_busy_rounded;
        color = Colors.orange;
        break;
      case 'inspection':
        icon = Icons.fact_check_outlined;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = AppColors.textSecondary;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
