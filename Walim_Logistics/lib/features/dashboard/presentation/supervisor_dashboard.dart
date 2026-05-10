import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_approval_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/office_request_alert.dart';
import 'package:walim_logistics/features/supervisor/presentation/daily_shift_control_screen.dart';
import 'package:walim_logistics/features/supervisor/presentation/supervisor_group_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/tracking/screens/rider_tracking_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/admin_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/leaderboard_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/my_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/performance_calculation_screen.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/staff_management_screen.dart';
import 'package:walim_logistics/features/inspections/presentation/inspection_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/attendance_reports_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/vehicle_allocation_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/supervisor/presentation/shift_cluster_manager_screen.dart';

class SupervisorDashboard extends ConsumerWidget {
  final bool showScaffold;
  const SupervisorDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final layout = ref.watch(dashboardLayoutProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final isOpsOrAdmin = profile?.role == 'Admin' || profile?.role == 'Operations Manager';

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
                _buildContent(context, ref, layout, dashboardData, isOpsOrAdmin),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: isOpsOrAdmin ? 'FLEET PERFORMANCE HUB' : 'SUPERVISOR COMMAND CENTER',
      subtitle: isOpsOrAdmin 
          ? 'Global operational metrics and platform reconciliation'
          : 'Manage your group, assets, and performance',
      showBackButton: true,
      children: [
        _buildContent(context, ref, layout, dashboardData, isOpsOrAdmin),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardLayout layout, DashboardData data, bool isOpsOrAdmin) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: [
          if (ref.watch(authProvider).profile != null)
            OfficeRequestAlert(profileId: ref.watch(authProvider).profile!.id),
          DashboardRefreshBar(
            lastUpdated: data.lastUpdated,
            isLoading: data.isLoading,
            onRefresh: () => ref.read(dashboardDataProvider.notifier).refresh(),
          ),
          const SizedBox(height: 8),
          ...layout.sections.map((section) => _buildSection(context, ref, section, data, isOpsOrAdmin)),
        ],
      );
    }

    // Desktop 2-column layout
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, ref, section, data, isOpsOrAdmin);
      
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
              DashboardRefreshBar(
                lastUpdated: data.lastUpdated,
                isLoading: data.isLoading,
                onRefresh: () => ref.read(dashboardDataProvider.notifier).refresh(),
              ),
              const SizedBox(height: 8),
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

  Widget _buildSection(BuildContext context, WidgetRef ref, DashboardSection section, DashboardData data, bool isOpsOrAdmin) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection(context, ref, data, isOpsOrAdmin);
      case DashboardSection.actions:
        return _buildActionsSection(context, ref, isOpsOrAdmin);
      case DashboardSection.activity:
        return _buildActivitySection(data);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(BuildContext context, WidgetRef ref, DashboardData data, bool isOpsOrAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary action cards (Hero)
        if (isOpsOrAdmin)
          _buildOpsHero(context, ref)
        else ...[
          _buildDailyShiftHero(context),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMyGroupHero(context)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context, 
                  'Team Performance', 
                  'Detailed group analytics', 
                  Icons.analytics_rounded, 
                  Colors.indigo, 
                  () => ref.read(navigationProvider.notifier).setTab(DashboardTab.attendance),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),

        _buildSectionHeader('Fleet & Operational Metrics'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          tabletCrossAxisCount: 4,
          spacing: 16,
          children: [
            DashboardStatCard(
              label: 'SOS Today',
              value: data.checkedInToday.toString(),
              icon: Icons.login_rounded,
              color: AppColors.accent,
              trend: 'Start of Shift',
              isPositive: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AttendanceReportsScreen(initialStatus: 'SOS_SUBMITTED'),
              )),
            ),
            DashboardStatCard(
              label: 'EOS Today',
              value: data.checkedOutToday.toString(),
              icon: Icons.logout_rounded,
              color: Colors.green,
              trend: 'End of Shift',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AttendanceReportsScreen(initialStatus: 'EOS_SUBMITTED'),
              )),
            ),
            DashboardStatCard(
              label: 'Live Incidents',
              value: data.activeIncidents.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              trend: data.activeIncidents > 0 ? 'Action Required' : 'All Clear',
              isPositive: data.activeIncidents == 0,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const InspectionManagementScreen(initialTabIndex: 1),
              )),
            ),
            DashboardStatCard(
              label: 'Active Riders',
              value: data.activeRiders.toString(),
              icon: Icons.motorcycle_rounded,
              color: Colors.blue,
              trend: 'Across all zones',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const StaffManagementScreen(initialRole: 'Rider', initialStatus: 'Active_Completed'),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, bool isOpsOrAdmin) {
    if (isOpsOrAdmin) {
       return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Strategic Operations & Intelligence'),
          const SizedBox(height: 24),
          ResponsiveGrid(
            mobileCrossAxisCount: 1,
            tabletCrossAxisCount: 2,
            desktopCrossAxisCount: 4,
            spacing: 16,
            childAspectRatio: 1.8,
            children: [
              DashboardActionCard(
                title: 'Incident Approvals',
                subtitle: 'Approve delay & accident justifications',
                icon: Icons.fact_check_outlined,
                color: Colors.red,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IncidentApprovalScreen())),
              ),
              DashboardActionCard(
                title: 'Shift Cluster Manager',
                subtitle: 'Assign riders to high-demand zones',
                icon: Icons.grid_view_rounded,
                color: Colors.blue,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShiftClusterManagerScreen())),
              ),
              DashboardActionCard(
                title: 'Leaderboard',
                subtitle: 'Top riders and supervisors this month',
                icon: Icons.leaderboard_rounded,
                color: Colors.amber,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              ),
              DashboardActionCard(
                title: 'Scoring Configuration',
                subtitle: 'Design how performance scores are calculated',
                icon: Icons.settings_suggest_rounded,
                color: Colors.deepPurple,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerformanceCalculationScreen())),
              ),
            ],
          ),
        ],
      );
    }

    // Specialized Supervisor Actions
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Group & Rider Management'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 3,
          spacing: 16,
          childAspectRatio: 2.2,
          children: [
            DashboardActionCard(
              title: 'My Group',
              subtitle: 'Manage your assigned team',
              icon: Icons.groups_rounded,
              color: Colors.teal,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupervisorGroupScreen())),
            ),
            DashboardActionCard(
              title: 'Add New Rider',
              subtitle: 'Onboard a new member to fleet',
              icon: Icons.person_add_rounded,
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StaffManagementScreen(initialRole: 'Rider'))),
            ),
            DashboardActionCard(
              title: 'Live Rider Tracking',
              subtitle: 'Monitor your group in real-time',
              icon: Icons.my_location_rounded,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderTrackingScreen())),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Fleet & Asset Control'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 1,
          spacing: 16,
          childAspectRatio: 2.5,
          children: [
            DashboardActionCard(
              title: 'Vehicle Allocation',
              subtitle: 'Assign, change or unassign vehicles',
              icon: Icons.swap_horiz_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleAllocationScreen())),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Performance & Leadership'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          spacing: 16,
          childAspectRatio: 2.2,
          children: [
             DashboardActionCard(
              title: 'Leaderboard',
              subtitle: 'Top riders and rankings',
              icon: Icons.leaderboard_rounded,
              color: Colors.amber,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
            DashboardActionCard(
              title: 'My Performance',
              subtitle: 'Your score and targets',
              icon: Icons.bar_chart_rounded,
              color: Colors.teal,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPerformanceScreen())),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Operational Approvals'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          spacing: 16,
          childAspectRatio: 2.2,
          children: [
            DashboardActionCard(
              title: 'Incident Approvals',
              subtitle: 'Approve delay justifications',
              icon: Icons.fact_check_outlined,
              color: Colors.red,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IncidentApprovalScreen())),
            ),
            DashboardActionCard(
              title: 'Shift Cluster Manager',
              subtitle: 'Demand-based positioning',
              icon: Icons.grid_view_rounded,
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShiftClusterManagerScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpsHero(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AttendanceReportsScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.analytics_rounded,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Shift & Attendance Monitor',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitor all supervisor reports, shift validations, and real-time attendance across the entire fleet.',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOpsQuickAction(
                context,
                'Platform Reports',
                'Daily/Weekly/Monthly submissions',
                Icons.assessment_rounded,
                Colors.indigo,
                () => ref.read(navigationProvider.notifier).setTab(DashboardTab.reports),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOpsQuickAction(
                context,
                'Rider Monitoring',
                'Status, vehicle, and iqama',
                Icons.motorcycle_rounded,
                Colors.teal,
                () => ref.read(navigationProvider.notifier).setTab(DashboardTab.riders),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOpsQuickAction(
                context,
                'Platform Monitoring',
                'Shifts and allocations',
                Icons.business_rounded,
                Colors.indigo,
                () => ref.read(navigationProvider.notifier).setTab(DashboardTab.platforms),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpsQuickAction(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: color.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(sub, style: GoogleFonts.outfit(fontSize: 10, color: color.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
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



  Widget _buildMyGroupHero(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SupervisorGroupScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.groups_rounded,
                  size: 20, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Group',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    'Manage riders & shifts',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.teal.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.teal, size: 14),
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
              AppColors.primary.withValues(alpha:0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.35),
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
                color: Colors.white.withValues(alpha:0.15),
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
                      color: Colors.white.withValues(alpha:0.8),
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
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}
