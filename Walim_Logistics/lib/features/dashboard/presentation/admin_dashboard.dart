import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/admin/presentation/admin_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:walim_logistics/features/tracking/theme/app_theme.dart' as tracking_theme;
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/it_dev_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:walim_logistics/features/admin/presentation/rbac_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/audit_logs_screen.dart';
import 'package:walim_logistics/features/hr/presentation/staff_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/group_setup_screen.dart';
import 'package:walim_logistics/features/admin/presentation/shift_planner_screen.dart';
import 'package:walim_logistics/features/admin/presentation/supervisor_schedule_screen.dart';

class AdminDashboard extends ConsumerWidget {
  final bool showScaffold;
  const AdminDashboard({super.key, this.showScaffold = true});

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
      title: 'CONTROL TOWER',
      subtitle: 'Real-time metrics across all zones and platforms',
      actions: [],
      children: [
        _buildContent(context, ref),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting & Status Section
        _buildGreeting(context, ref),
        const SizedBox(height: 32),

        // KPI Section
        if (stats.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ResponsiveGrid(
            children: [
              DashboardStatCard(
                label: 'Active Riders',
                value: stats.activeRiders.toString(),
                icon: Icons.motorcycle,
                color: Colors.blue,
                trend: 'Live',
                isPositive: true,
                sparklineData: const [10, 15, 8, 20, 12, 25, 22],
              ),
              DashboardStatCard(
                label: 'On Duty Now',
                value: stats.liveOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
                trend: 'Open shifts',
                isPositive: true,
                sparklineData: const [50, 45, 60, 55, 70, 65, 80],
              ),
              DashboardStatCard(
                label: 'Fleet Health',
                value: '${stats.fleetHealth}%',
                icon: Icons.verified_user_outlined,
                color: Colors.green,
                trend: 'Operational',
                isPositive: stats.fleetHealth >= 90,
                sparklineData: const [98, 97, 96, 95, 94, 95, 94],
              ),
              DashboardStatCard(
                label: 'Pending COD',
                value: stats.pendingCod > 0
                    ? '\u{FDFC} ${(stats.pendingCod / 1000).toStringAsFixed(1)}k'
                    : '\u{FDFC} 0',
                icon: Icons.payments_outlined,
                color: Colors.purple,
                trend: 'Unreconciled',
                isPositive: false,
                sparklineData: const [5, 8, 6, 10, 12, 11, 12.4],
              ),
            ],
          ),
        
        const SizedBox(height: 40),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Management Tools
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Management Tools'),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 2.4,
                        children: [
                          DashboardActionCard(
                            title: 'Live Operations Map',
                            subtitle: 'Monitor all active riders and deliveries',
                            icon: Icons.map_outlined,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => Theme(
                                data: tracking_theme.AppTheme.theme,
                                child: const walim_tracking.HomeScreen(),
                              ),
                            )),
                          ),
                          DashboardActionCard(
                            title: 'Financial Reconciliation',
                            subtitle: 'Audit COD collections and platform reports',
                            icon: Icons.account_balance_wallet_outlined,
                            color: Colors.green,
                            onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.finance),
                          ),
                          DashboardActionCard(
                            title: 'Inventory & Assets',
                            subtitle: 'Manage uniforms, bags, and fuel cards',
                            icon: Icons.inventory_2_outlined,
                            color: Colors.orange,
                            onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.assets),
                          ),
                          DashboardActionCard(
                            title: 'Performance Analytics',
                            subtitle: 'View detailed fleet and rider reports',
                            icon: Icons.analytics_outlined,
                            color: Colors.indigo,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorDashboard())),
                          ),
                          DashboardActionCard(
                            title: 'HR Management',
                            subtitle: 'Qiwa, Absher, and housing management',
                            icon: Icons.people_outline,
                            color: Colors.teal,
                            onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.hr),
                          ),
                          DashboardActionCard(
                            title: 'Staff Monitoring',
                            subtitle: 'Monitor all roles: Riders, Managers, etc.',
                            icon: Icons.people_outline_rounded,
                            color: Colors.purple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Group Management',
                            subtitle: 'Create groups and assign riders to supervisors',
                            icon: Icons.groups_rounded,
                            color: Colors.teal,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSetupScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Shift Planner',
                            subtitle: 'Generate rider shift plans by group and date',
                            icon: Icons.event_note_rounded,
                            color: Colors.indigo,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftPlannerScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Supervisor Schedule',
                            subtitle: 'Assign supervisors to groups and shifts',
                            icon: Icons.assignment_ind_rounded,
                            color: Colors.orange,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorScheduleScreen())),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Column: Live Activity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'System Overview'),
                  const SizedBox(height: 20),
                  ActivityFeed(
                    items: [
                      ActivityItem(
                        title: 'New Rider Registered',
                        subtitle: 'Ahmed Ali joined the Jeddah team',
                        time: '2m ago',
                        icon: Icons.person_add_rounded,
                        color: Colors.blue,
                      ),
                      ActivityItem(
                        title: 'Order Spike Detected',
                        subtitle: '15% increase in Riyadh North',
                        time: '15m ago',
                        icon: Icons.trending_up_rounded,
                        color: Colors.orange,
                      ),
                      ActivityItem(
                        title: 'Asset Alert',
                        subtitle: 'Vehicle #422 requires maintenance',
                        time: '1h ago',
                        icon: Icons.warning_rounded,
                        color: Colors.red,
                      ),
                      ActivityItem(
                        title: 'SLA Milestone',
                        subtitle: '99% delivery rate achieved today',
                        time: '3h ago',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAdminTools(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final displayName = profile?.fullName ?? 'Admin';
    final role = profile?.role ?? 'Admin';

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, $displayName',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your $role dashboard is operating at 94% efficiency today.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.headlineMedium?.color,
      ),
    );
  }

  Widget _buildAdminTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administration',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminToolItem(
            context,
            'Audit Logs',
            Icons.history_rounded,
            Colors.blueGrey,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminToolItem(
            context,
            'Access Control (RBAC)',
            Icons.admin_panel_settings_outlined,
            AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RBACManagementScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminToolItem(
            context,
            'IT & API Management',
            Icons.terminal,
            Colors.blueGrey,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevDashboard())),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color, size: 16),
          ],
        ),
      ),
    );
  }
}


