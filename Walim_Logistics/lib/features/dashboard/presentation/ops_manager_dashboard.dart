import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/capacity_planning_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/vehicle_allocation_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/hr/presentation/staff_management_screen.dart';
import 'package:walim_logistics/features/inspections/presentation/inspection_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/group_setup_screen.dart';
import 'package:walim_logistics/features/admin/presentation/shift_planner_screen.dart';
import 'package:walim_logistics/features/admin/presentation/supervisor_schedule_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/tracking/screens/rider_tracking_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/admin_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/leaderboard_screen.dart';
import 'package:walim_logistics/features/admin/presentation/attendance_reports_screen.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';

class OpsManagerDashboard extends ConsumerWidget {
  final bool showScaffold;
  const OpsManagerDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final layout = ref.watch(dashboardLayoutProvider);
    final l10n = AppLocalizations.of(context)!;

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
                _buildContent(context, ref, dashboardData, layout, l10n),
              ]),
            ),
          ),
        ],
      );
    }

    final profile = ref.watch(authProvider).profile;
    final displayName = profile?.fullName ?? 'Operations Manager';

    return DashboardScaffold(
      title: l10n.opsControl.toUpperCase(),
      subtitle: l10n.opsSubtitle,
      children: [
        _buildHeader(context, dashboardData, displayName),
        const SizedBox(height: 32),
        _buildContent(context, ref, dashboardData, layout, l10n),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DashboardData data, String displayName) {
    final efficiencyMsg = data.assetHealth > 0
        ? 'Fleet is operating at ${data.assetHealth}% efficiency today.'
        : 'Loading fleet metrics...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $displayName',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        Text(
          '$efficiencyMsg ${data.activeIncidents > 0 ? '${data.activeIncidents} incident(s) require your attention.' : 'No active incidents.'}',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardData data, DashboardLayout layout, AppLocalizations l10n) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: [
          _buildRefreshBar(ref, data),
          const SizedBox(height: 8),
          ...layout.sections.map((section) => _buildSection(context, ref, data, section, l10n)),
        ],
      );
    }

    // Desktop 2-column layout
    // We try to maintain the 2-column feel but respect the order
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, ref, data, section, l10n);
      
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
            children: [
              _buildRefreshBar(ref, data),
              const SizedBox(height: 8),
              ...leftColumn,
            ],
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

  Widget _buildRefreshBar(WidgetRef ref, DashboardData data) {
    return DashboardRefreshBar(
      lastUpdated: data.lastUpdated,
      isLoading: data.isLoading,
      onRefresh: () => ref.read(dashboardDataProvider.notifier).refresh(),
    );
  }

  Widget _buildSection(BuildContext context, WidgetRef ref, DashboardData data, DashboardSection section, AppLocalizations l10n) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection(context, data, l10n);
      case DashboardSection.actions:
        return _buildActionsSection(context, ref, data, l10n);
      case DashboardSection.activity:
        return _buildActivitySection(context, data, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(BuildContext context, DashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.corePerformanceMetrics),
        const SizedBox(height: 20),
        ResponsiveGrid(
          desktopCrossAxisCount: 3,
          tabletCrossAxisCount: 3,
          mobileCrossAxisCount: 2,
          spacing: 12,
          childAspectRatio: 2.1,
          children: [
            DashboardStatCard(
              label: l10n.activeRiders,
              value: _formatCount(data.activeRiders),
              icon: Icons.motorcycle_rounded,
              color: Colors.teal,
              trend: 'On duty',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const StaffManagementScreen(initialRole: 'Rider', initialStatus: 'Active_Completed'),
              )),
            ),
            DashboardStatCard(
              label: l10n.ridersOnLeave,
              value: data.ridersOnLeave.toString(),
              icon: Icons.person_off_outlined,
              color: Colors.orange,
              trend: 'Scheduled absence',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const StaffManagementScreen(initialRole: 'Rider', initialStatus: 'on leave'),
              )),
            ),
            DashboardStatCard(
              label: l10n.activeIncidents,
              value: data.activeIncidents.toString(),
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              trend: '${data.activeIncidents} Critical',
              isPositive: data.activeIncidents == 0,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const InspectionManagementScreen(initialTabIndex: 1),
              )),
            ),
            DashboardStatCard(
              label: l10n.supervisors,
              value: data.supervisorsCount.toString(),
              icon: Icons.admin_panel_settings_rounded,
              color: Colors.indigo,
              trend: 'Field management',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const StaffManagementScreen(initialRole: 'Supervisor'),
              )),
            ),
            DashboardStatCard(
              label: l10n.sos,
              value: data.checkedInToday.toString(),
              icon: Icons.login_rounded,
              color: Colors.green,
              trend: 'Start of Shift',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AttendanceReportsScreen(initialStatus: 'SOS_SUBMITTED'),
              )),
            ),
            DashboardStatCard(
              label: l10n.eos,
              value: data.checkedOutToday.toString(),
              icon: Icons.logout_rounded,
              color: Colors.blueGrey,
              trend: 'End of Shift',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AttendanceReportsScreen(initialStatus: 'EOS_SUBMITTED'),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, DashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.managementConsole),
        const SizedBox(height: 20),
        ResponsiveGrid(
          mobileCrossAxisCount: 2,
          tabletCrossAxisCount: 3,
          desktopCrossAxisCount: 3,
          childAspectRatio: 2.2,
          spacing: 16,
          children: [
            DashboardActionCard(
              title: l10n.vehicleAllocation,
              subtitle: 'Balance Vans vs Bikes',
              icon: Icons.swap_horiz_outlined,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleAllocationScreen())),
            ),
            DashboardActionCard(
              title: l10n.liveRiderTracking,
              subtitle: 'Monitor all active riders',
              icon: Icons.my_location_rounded,
              color: Colors.green,
              badge: 'LIVE',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderTrackingScreen())),
            ),
            DashboardActionCard(
              title: l10n.capacityPlanning,
              subtitle: 'Peak season forecasting',
              icon: Icons.calendar_today_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapacityPlanningScreen())),
            ),
            DashboardActionCard(
              title: l10n.groupManagement,
              subtitle: 'Create groups and assign riders',
              icon: Icons.groups_rounded,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSetupScreen())),
            ),
            DashboardActionCard(
              title: l10n.shiftPlanner,
              subtitle: 'Generate rider shift plans',
              icon: Icons.event_note_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftPlannerScreen())),
            ),
            DashboardActionCard(
              title: l10n.supervisorSchedule,
              subtitle: 'Assign supervisors to groups',
              icon: Icons.assignment_ind_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorScheduleScreen())),
            ),
            DashboardActionCard(
              title: 'Platform Reports',
              subtitle: 'Daily/Weekly/Monthly submissions',
              icon: Icons.assessment_rounded,
              color: Colors.purple,
              badge: 'NEW',
              onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.reports),
            ),
            DashboardActionCard(
              title: l10n.globalAssetView,
              subtitle: 'Accountability for all equipment',
              icon: Icons.inventory_2_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen())),
            ),
            DashboardActionCard(
              title: 'Rider Monitoring',
              subtitle: 'Status, vehicle, and iqama details',
              icon: Icons.motorcycle_rounded,
              color: Colors.teal,
              onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.riders),
            ),
            DashboardActionCard(
              title: 'Supervisor Monitoring',
              subtitle: 'Platforms and groups managed',
              icon: Icons.supervisor_account_rounded,
              color: Colors.blue,
              onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.supervisors),
            ),
            DashboardActionCard(
              title: 'Platform Monitoring',
              subtitle: 'Shifts, allocations and supervisors',
              icon: Icons.business_rounded,
              color: Colors.indigo,
              onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.platforms),
            ),
            DashboardActionCard(
              title: l10n.safetyInspections,
              subtitle: 'Daily vehicle safety checks',
              icon: Icons.security_rounded,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen())),
            ),
            DashboardActionCard(
              title: l10n.performanceManagement,
              subtitle: 'Bonuses, penalties, targets & leaderboard',
              icon: Icons.military_tech_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPerformanceScreen())),
            ),
                          DashboardActionCard(
                            title: l10n.leaderboard,
                            subtitle: 'Top performers — riders and supervisors',
                            icon: Icons.leaderboard_rounded,
                            color: Colors.amber,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                          ),
                          DashboardActionCard(
                            title: l10n.sosEosMonitoring,
                            subtitle: 'View daily supervisor shift reports',
                            icon: Icons.assignment_turned_in_rounded,
                            color: Colors.deepPurple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportsScreen())),
                          ),
                        ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, DashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.liveActivity),
        const SizedBox(height: 20),
        ActivityFeed(
          onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionManagementScreen())),
          items: data.recentActivity.map((item) => ActivityItem(
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



  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
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
