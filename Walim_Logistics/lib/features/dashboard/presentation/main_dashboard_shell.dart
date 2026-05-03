import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

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
import 'package:walim_logistics/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';
import 'package:walim_logistics/features/tracking/theme/app_theme.dart' as tracking_theme;
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/inspections/presentation/inspection_screen.dart';
import 'package:walim_logistics/features/support/presentation/support_tickets_screen.dart';
import 'package:walim_logistics/features/hr/presentation/document_vault_screen.dart';
import 'package:walim_logistics/features/requests/presentation/leave_request_screen.dart' as rider_requests;
import 'package:walim_logistics/features/fleet/presentation/live_tracking_screen.dart';
import 'package:walim_logistics/features/tracking/presentation/widgets/live_rider_map.dart';

class MainDashboardShell extends ConsumerWidget {
  const MainDashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final role = authState.profile?.role ?? 'Rider';

    final config = _getTabConfig(context, ref, navState.activeTab, role);

    return DashboardScaffold(
      title: config.title,
      subtitle: config.subtitle,
      body: config.body,
      activeItem: config.activeItem,
      onSearchChanged: config.onSearchChanged,
      searchHint: config.searchHint,
      headerActions: config.headerActions,
    );
  }

  _TabConfig _getTabConfig(BuildContext context, WidgetRef ref, DashboardTab tab, String role) {
    switch (tab) {
      case DashboardTab.dashboard:
        return _getDashboardConfig(role);
      case DashboardTab.liveOps:
        final tracker = ref.watch(trackingProvider);
        return _TabConfig(
          title: tracker.selectedCity == 'All' 
            ? 'LIVE GPS' 
            : 'LIVE GPS - ${tracker.selectedCity.toUpperCase()}',
          subtitle: 'Real-time tracking and delivery monitoring',
          activeItem: 'Live GPS',
          onSearchChanged: (v) => ref.read(trackingProvider.notifier).setFilter(v),
          searchHint: 'Search riders, vehicles, orders...',
          headerActions: [
            _buildLiveStatusIndicator(tracker),
          ],
          body: Theme(
            data: Theme.of(context).brightness == Brightness.dark 
              ? tracking_theme.AppTheme.darkTheme 
              : tracking_theme.AppTheme.lightTheme,
            child: const walim_tracking.HomeScreen(showScaffold: false),
          ),
        );
      case DashboardTab.liveRider:
        return _TabConfig(
          title: 'LIVE RIDER TRACKING',
          subtitle: 'Real-time positioning of all active riders',
          activeItem: 'Live Rider',
          body: const LiveRiderMap(),
        );
      case DashboardTab.hr:
        return _TabConfig(
          title: 'HR Management',
          subtitle: 'Manage staff, government regulations, housing, and assets',
          activeItem: 'HR',
          body: const HRDashboard(showScaffold: false),
        );
      case DashboardTab.assets:
        return _TabConfig(
          title: 'ASSET MANAGEMENT',
          subtitle: 'Track and assign fleet assets',
          activeItem: 'Assets',
          body: const FleetAssetRegistryScreen(showScaffold: false),
        );
      case DashboardTab.finance:
        return _TabConfig(
          title: 'FINANCIAL MANAGEMENT',
          subtitle: 'Payroll, vendor invoicing, and expenses',
          activeItem: 'Finance',
          body: const FinanceDashboard(showScaffold: false),
        );
      case DashboardTab.support:
        return _TabConfig(
          title: 'SUPPORT',
          subtitle: 'Report issues and track your tickets',
          activeItem: 'Support',
          body: const SupportTicketsScreen(showScaffold: false),
        );
      case DashboardTab.documents:
        return _TabConfig(
          title: 'DOCUMENT VAULT',
          subtitle: 'Your personal documents and permits',
          activeItem: 'Documents',
          body: const DocumentVaultScreen(showScaffold: false),
        );
      case DashboardTab.attendance:
        return _TabConfig(
          title: 'PERFORMANCE HUB',
          subtitle: 'Real-time SLA tracking and platform compliance',
          activeItem: 'Performance',
          body: const SupervisorDashboard(showScaffold: false),
        );
      case DashboardTab.requests:
        return _TabConfig(
          title: 'MY REQUESTS',
          subtitle: 'Manage leave and salary advance requests',
          activeItem: 'Requests',
          body: const rider_requests.LeaveRequestScreen(showScaffold: false),
        );
      case DashboardTab.settings:
        return _TabConfig(
          title: 'SETTINGS',
          subtitle: 'Manage your application preferences',
          activeItem: 'Settings',
          body: const Center(child: Text('Settings Screen')),
        );
      default:
        return _getDashboardConfig(role);
    }
  }

  _TabConfig _getDashboardConfig(String role) {
    switch (role) {
      case 'Admin':
        return _TabConfig(
          title: 'CONTROL TOWER',
          subtitle: 'Real-time metrics across all zones and platforms',
          activeItem: 'Dashboard',
          body: const AdminDashboard(showScaffold: false),
        );
      case 'HR':
        return _TabConfig(
          title: 'HR Management',
          subtitle: 'Manage staff, government regulations, housing, and assets',
          activeItem: 'Dashboard',
          body: const HRDashboard(showScaffold: false),
        );
      case 'Finance Manager':
        return _TabConfig(
          title: 'FINANCIAL MANAGEMENT',
          subtitle: 'Payroll, vendor invoicing, and expenses',
          activeItem: 'Dashboard',
          body: const FinanceDashboard(showScaffold: false),
        );
      case 'Operations Manager':
        return _TabConfig(
          title: 'OPERATIONS STRATEGY',
          subtitle: 'Fleet allocation, SLA monitoring, and planning',
          activeItem: 'Dashboard',
          body: const OpsManagerDashboard(showScaffold: false),
        );
      case 'Supervisor':
        return _TabConfig(
          title: 'PERFORMANCE HUB',
          subtitle: 'Oversee operations and resolve blockers',
          activeItem: 'Dashboard',
          body: const SupervisorDashboard(showScaffold: false),
        );
      case 'IT_Dev':
        return _TabConfig(
          title: 'IT & DEVELOPMENT',
          subtitle: 'System health and API monitoring',
          activeItem: 'Dashboard',
          body: const ITDevDashboard(showScaffold: false),
        );
      case 'Leader':
        return _TabConfig(
          title: 'TEAM LEADERSHIP',
          subtitle: 'Manage your team and performance',
          activeItem: 'Dashboard',
          body: const LeaderDashboard(showScaffold: false),
        );
      case 'Rider':
        return _TabConfig(
          title: 'MY DASHBOARD',
          subtitle: 'Your daily stats and tasks',
          activeItem: 'Dashboard',
          body: const RiderDashboard(showScaffold: false),
        );
      case 'Business Development':
        return _TabConfig(
          title: 'BUSINESS GROWTH',
          subtitle: 'Sales and partnership metrics',
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
                color: dotColor.withOpacity(0.4),
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

  _TabConfig({
    required this.title,
    required this.subtitle,
    required this.activeItem,
    required this.body,
    this.onSearchChanged,
    this.searchHint,
    this.headerActions,
  });
}
