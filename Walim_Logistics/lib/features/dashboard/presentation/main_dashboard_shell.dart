import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';

// Import dashboards
import 'package:walim_logistics/features/dashboard/presentation/admin_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/hr_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/finance_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/ops_manager_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/it_dev_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/leader_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/rider_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/biz_dev_dashboard.dart';

// Import other screens
import 'package:walim_logistics/features/dashboard/presentation/settings_screen.dart';
import 'package:walim_logistics/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';
import 'package:walim_logistics/features/tracking/theme/app_theme.dart' as tracking_theme;
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/hr/presentation/asset_management_screen.dart';
import 'package:walim_logistics/features/support/presentation/support_tickets_screen.dart';
import 'package:walim_logistics/features/hr/presentation/document_vault_screen.dart';
import 'package:walim_logistics/features/requests/presentation/leave_request_screen.dart' as rider_requests;
import 'package:walim_logistics/features/tracking/presentation/widgets/live_rider_map.dart';
import 'package:walim_logistics/features/reports/presentation/reports_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/admin_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/my_performance_screen.dart';
import 'package:walim_logistics/features/admin/presentation/riders_list_screen.dart';
import 'package:walim_logistics/features/admin/presentation/supervisors_list_screen.dart';
import 'package:walim_logistics/features/admin/presentation/platforms_list_screen.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';

class MainDashboardShell extends ConsumerWidget {
  const MainDashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final role = authState.profile?.role ?? 'Rider';

    final l10n = AppLocalizations.of(context)!;
    final config = _getTabConfig(context, ref, navState.activeTab, role, l10n);

    return DashboardScaffold(
      title: config.title,
      subtitle: config.subtitle,
      body: config.body,
      activeItem: config.activeItem,
      onSearchChanged: config.onSearchChanged,
      searchHint: config.searchHint,
      headerActions: config.headerActions,
      showBackButton: config.showBackButton,
      onBack: config.onBack,
      showBottomNavigationBar: true,
    );
  }

  _TabConfig _getTabConfig(BuildContext context, WidgetRef ref, DashboardTab tab, String role, AppLocalizations l10n) {
    switch (tab) {
      case DashboardTab.dashboard:
        return _getDashboardConfig(role, l10n);
      case DashboardTab.liveOps:
        final tracker = ref.watch(trackingProvider);
        return _TabConfig(
          title: tracker.selectedCity == 'All' 
            ? l10n.liveGPS.toUpperCase() 
            : '${l10n.liveGPS.toUpperCase()} - ${tracker.selectedCity.toUpperCase()}',
          subtitle: 'Real-time tracking and delivery monitoring',
          activeItem: 'Live GPS',
          onSearchChanged: (v) => ref.read(trackingProvider.notifier).setFilter(v),
          searchHint: 'Search riders, vehicles, orders...',
          headerActions: [
            _buildLiveStatusIndicator(tracker),
          ],
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: Theme(
            data: Theme.of(context).brightness == Brightness.dark 
              ? tracking_theme.AppTheme.darkTheme 
              : tracking_theme.AppTheme.lightTheme,
            child: const walim_tracking.HomeScreen(showScaffold: false),
          ),
        );
      case DashboardTab.liveRider:
        if (role != 'Admin') {
          return _getDashboardConfig(role, l10n);
        }
        return _TabConfig(
          title: l10n.liveRiderTracking.toUpperCase(),
          subtitle: 'Real-time positioning of all active riders',
          activeItem: 'Live Rider',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const LiveRiderMap(),
        );
      case DashboardTab.hr:
        return _TabConfig(
          title: l10n.hrManagement,
          subtitle: 'Manage staff, government regulations, housing, and assets',
          activeItem: 'HR',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const HRDashboard(showScaffold: false),
        );
      case DashboardTab.assets:
        return _TabConfig(
          title: 'ASSET RESPONSIBILITY',
          subtitle: 'Tracking company assets assigned to staff members',
          activeItem: 'Assets',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const AssetManagementScreen(showScaffold: false),
        );
      case DashboardTab.vehicles:
        return _TabConfig(
          title: 'VEHICLE REGISTRY',
          subtitle: 'Track vehicle registrations, inspections, and insurance',
          activeItem: 'Vehicles',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const FleetAssetRegistryScreen(showScaffold: false),
        );
      case DashboardTab.finance:
        return _TabConfig(
          title: l10n.financialManagement.toUpperCase(),
          subtitle: 'Payroll, vendor invoicing, and expenses',
          activeItem: 'Finance',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const FinanceDashboard(showScaffold: false),
        );
      case DashboardTab.support:
        return _TabConfig(
          title: l10n.support.toUpperCase(),
          subtitle: 'Report issues and track your tickets',
          activeItem: 'Support',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const SupportTicketsScreen(showScaffold: false),
        );
      case DashboardTab.documents:
        return _TabConfig(
          title: l10n.documentVault.toUpperCase(),
          subtitle: 'Your personal documents and permits',
          activeItem: 'Documents',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const DocumentVaultScreen(showScaffold: false),
        );
      case DashboardTab.attendance:
        final isOpsOrAdmin = role == 'Admin' || role == 'Operations Manager';
        final isSupervisor = role == 'Supervisor';
        return _TabConfig(
          title: isOpsOrAdmin ? l10n.fleetPerformanceHub.toUpperCase() : l10n.performanceManagement.toUpperCase(),
          subtitle: isOpsOrAdmin 
            ? 'Global operational metrics and platform reconciliation'
            : 'Real-time SLA tracking and platform compliance',
          activeItem: 'Performance',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: (isOpsOrAdmin || isSupervisor)
            ? const AdminPerformanceScreen(showScaffold: false)
            : (role == 'Rider' 
                ? const MyPerformanceScreen(showScaffold: false) 
                : const SupervisorDashboard(showScaffold: false)),
        );
      case DashboardTab.reports:
        final isOpsOrAdmin = role == 'Admin' || role == 'Operations Manager';
        return _TabConfig(
          title: 'PLATFORM REPORTS',
          subtitle: isOpsOrAdmin 
            ? 'Compliance tracking and multi-platform performance audit'
            : 'Daily, weekly, and monthly platform report submissions',
          activeItem: 'Reports',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const ReportsScreen(showScaffold: false),
        );
      case DashboardTab.requests:
        return _TabConfig(
          title: l10n.myRequests.toUpperCase(),
          subtitle: 'Manage leave and salary advance requests',
          activeItem: 'Requests',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const rider_requests.LeaveRequestScreen(showScaffold: false),
        );
      case DashboardTab.settings:
        return _TabConfig(
          title: l10n.settings.toUpperCase(),
          subtitle: 'Manage your application preferences',
          activeItem: 'Settings',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          body: const SettingsScreen(),
        );
      case DashboardTab.riders:
        return _TabConfig(
          title: 'ALL RIDERS',
          subtitle: 'Monitor status, vehicle and legal details for all riders',
          activeItem: 'Riders',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          onSearchChanged: (v) => ref.read(riderSearchQueryProvider.notifier).state = v,
          searchHint: 'Search by name, iqama or phone...',
          body: const RidersListScreen(),
        );
      case DashboardTab.supervisors:
        return _TabConfig(
          title: 'ALL SUPERVISORS',
          subtitle: 'Monitor platforms and groups managed by all supervisors',
          activeItem: 'Supervisors',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          onSearchChanged: (v) => ref.read(supervisorSearchQueryProvider.notifier).state = v,
          searchHint: 'Search by name, platform or group...',
          body: const SupervisorsListScreen(),
        );
      case DashboardTab.platforms:
        return _TabConfig(
          title: 'ALL PLATFORMS',
          subtitle: 'Monitor active shifts, allocated riders and supervisors per platform',
          activeItem: 'Platforms',
          showBackButton: true,
          onBack: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.dashboard),
          onSearchChanged: (v) => ref.read(platformSearchQueryProvider.notifier).state = v,
          searchHint: 'Search by platform name...',
          body: const PlatformsListScreen(),
        );
    }
  }

  _TabConfig _getDashboardConfig(String role, AppLocalizations l10n) {
    switch (role) {
      case 'Admin':
        return _TabConfig(
          title: l10n.controlTower.toUpperCase(),
          subtitle: l10n.controlTowerSubtitle,
          activeItem: 'Dashboard',
          body: const AdminDashboard(showScaffold: false),
        );
      case 'HR':
        return _TabConfig(
          title: l10n.hrManagement,
          subtitle: l10n.hrManagementSubtitle,
          activeItem: 'Dashboard',
          body: const HRDashboard(showScaffold: false),
        );
      case 'Finance Manager':
        return _TabConfig(
          title: l10n.financialManagement.toUpperCase(),
          subtitle: l10n.financialManagementSubtitle,
          activeItem: 'Dashboard',
          body: const FinanceDashboard(showScaffold: false),
        );
      case 'Operations Manager':
        return _TabConfig(
          title: l10n.opsStrategy.toUpperCase(),
          subtitle: l10n.opsStrategySubtitle,
          activeItem: 'Dashboard',
          body: const OpsManagerDashboard(showScaffold: false),
        );
      case 'Supervisor':
        return _TabConfig(
          title: l10n.commandCenter.toUpperCase(),
          subtitle: l10n.supervisorDashboardSubtitle,
          activeItem: 'Dashboard',
          body: const SupervisorDashboard(showScaffold: false),
        );
      case 'IT_Dev':
        return _TabConfig(
          title: l10n.itDevelopment.toUpperCase(),
          subtitle: l10n.itDevDashboardSubtitle,
          activeItem: 'Dashboard',
          body: const ITDevDashboard(showScaffold: false),
        );
      case 'Leader':
        return _TabConfig(
          title: l10n.teamLeadership.toUpperCase(),
          subtitle: l10n.teamLeadershipSubtitle,
          activeItem: 'Dashboard',
          body: const LeaderDashboard(showScaffold: false),
        );
      case 'Rider':
        return _TabConfig(
          title: l10n.myDashboard.toUpperCase(),
          subtitle: l10n.riderDashboardSubtitle,
          activeItem: 'Dashboard',
          body: const RiderDashboard(showScaffold: false),
        );
      case 'Business Development':
        return _TabConfig(
          title: l10n.businessGrowth.toUpperCase(),
          subtitle: l10n.bizDevDashboardSubtitle,
          activeItem: 'Dashboard',
          body: const BizDevDashboard(showScaffold: false),
        );
      default:
        return _TabConfig(
          title: 'DASHBOARD',
          subtitle: 'Welcome to Walim Logistics',
          activeItem: 'Dashboard',
          body: _getDashboardForRole(role),
        );
    }
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'Admin': return const AdminDashboard(showScaffold: false);
      case 'HR': return const HRDashboard(showScaffold: false);
      case 'Finance Manager': return const FinanceDashboard(showScaffold: false);
      case 'Operations Manager': return const OpsManagerDashboard(showScaffold: false);
      case 'Supervisor': return const SupervisorDashboard(showScaffold: false);
      case 'IT_Dev': return const ITDevDashboard(showScaffold: false);
      case 'Leader': return const LeaderDashboard(showScaffold: false);
      case 'Rider': return const RiderDashboard(showScaffold: false);
      case 'Business Development': return const BizDevDashboard(showScaffold: false);
      default: return const AdminDashboard(showScaffold: false);
    }
  }

  Widget _buildLiveStatusIndicator(TrackingProvider provider) {
    final isError = provider.error != null;
    final dotColor = provider.loading
        ? Colors.orange
        : (isError ? Colors.red : Colors.green);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          provider.loading ? 'Syncing...' : (isError ? 'Sync Error' : 'Live'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: dotColor,
          ),
        ),
      ],
    );
  }
}

class _TabConfig {
  final String title;
  final String subtitle;
  final String activeItem;
  final Widget body;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final List<Widget>? headerActions;
  final bool showBackButton;
  final VoidCallback? onBack;
  
  _TabConfig({
    required this.title,
    required this.subtitle,
    required this.activeItem,
    required this.body,
    this.onSearchChanged,
    this.searchHint,
    this.headerActions,
    this.showBackButton = false,
    this.onBack,
  });
}
