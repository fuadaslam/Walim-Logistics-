import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

// Import dashboards
import 'package:last_mile_fleet/features/dashboard/presentation/admin_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/hr_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/finance_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/ops_manager_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/it_dev_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/leader_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/rider_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/biz_dev_dashboard.dart';

// Import other screens
import 'package:last_mile_fleet/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:last_mile_fleet/features/tracking/services/tracking_provider.dart';
import 'package:last_mile_fleet/features/tracking/theme/app_theme.dart' as tracking_theme;
import 'package:last_mile_fleet/features/fleet/presentation/inventory_handover_screen.dart';
import 'package:last_mile_fleet/features/finance/presentation/reconciliation_dashboard.dart';
import 'package:last_mile_fleet/features/inspections/presentation/inspection_screen.dart';
import 'package:last_mile_fleet/features/support/presentation/support_tickets_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/document_vault_screen.dart';
import 'package:last_mile_fleet/features/requests/presentation/leave_request_screen.dart' as rider_requests;
import 'package:provider/provider.dart' as provider_pkg;

class MainDashboardShell extends ConsumerWidget {
  const MainDashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final role = authState.profile?.role ?? 'Rider';

    final config = _getTabConfig(context, navState.activeTab, role);

    return DashboardScaffold(
      title: config.title,
      subtitle: config.subtitle,
      body: config.body,
      activeItem: config.activeItem,
    );
  }

  _TabConfig _getTabConfig(BuildContext context, DashboardTab tab, String role) {
    switch (tab) {
      case DashboardTab.dashboard:
        return _getDashboardConfig(role);
      case DashboardTab.liveOps:
        return _TabConfig(
          title: 'LIVE OPERATIONS',
          subtitle: 'Real-time tracking and delivery monitoring',
          activeItem: 'Live Ops',
          body: provider_pkg.ChangeNotifierProvider(
            create: (_) => TrackingProvider(),
            child: Theme(
              data: Theme.of(context).brightness == Brightness.dark 
                ? tracking_theme.AppTheme.darkTheme 
                : tracking_theme.AppTheme.lightTheme,
              child: const walim_tracking.HomeScreen(showScaffold: false),
            ),
          ),
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
          body: const InventoryHandoverScreen(showScaffold: false),
        );
      case DashboardTab.finance:
        return _TabConfig(
          title: 'FINANCIAL RECONCILIATION',
          subtitle: 'Audit COD collections and platform reports',
          activeItem: 'Finance',
          body: const ReconciliationDashboard(showScaffold: false),
        );
      case DashboardTab.inspections:
        return _TabConfig(
          title: 'INSPECTIONS',
          subtitle: 'Daily vehicle and gear compliance checks',
          activeItem: 'Inspections',
          body: const InspectionScreen(showScaffold: false),
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
          title: 'FINANCIAL CONTROL',
          subtitle: 'COD reconciliation, payroll, and expenses',
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
          subtitle: 'Welcome to Last Mile Fleet',
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
}

class _TabConfig {
  final String title;
  final String subtitle;
  final String activeItem;
  final Widget body;

  _TabConfig({
    required this.title,
    required this.subtitle,
    required this.activeItem,
    required this.body,
  });
}
