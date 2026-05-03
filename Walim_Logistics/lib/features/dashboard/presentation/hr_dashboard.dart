import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/housing_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/government_integration_screen.dart';
import 'package:walim_logistics/features/hr/presentation/onboarding_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/leave_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/asset_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/layout_provider.dart';

class HRDashboard extends ConsumerWidget {
  final bool showScaffold;
  const HRDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([_buildContent(context, ref, layout)]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'HR Management',
      subtitle: 'Manage staff, government regulations, housing, and assets',
      activeItem: 'HR',
      children: [_buildContent(context, ref, layout)],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardLayout layout) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (!isDesktop) {
      return Column(
        children: layout.sections.map((section) => _buildSection(context, ref, section)).toList(),
      );
    }

    // Desktop 2-column layout
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    for (var i = 0; i < layout.sections.length; i++) {
      final section = layout.sections[i];
      final sectionWidget = _buildSection(context, ref, section);
      
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
            children: leftColumn,
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

  Widget _buildSection(BuildContext context, WidgetRef ref, DashboardSection section) {
    switch (section) {
      case DashboardSection.metrics:
        return _buildMetricsSection(ref);
      case DashboardSection.actions:
        return _buildActionsSection(context, ref);
      case DashboardSection.compliance:
        return _buildComplianceSection(ref);
      case DashboardSection.activity:
        return _buildActivitySection(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsSection(WidgetRef ref) {
    final stats = ref.watch(hrStatsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Workforce Overview'),
        const SizedBox(height: 24),
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
                label: 'Total Staff',
                value: stats.totalStaff.toString(),
                icon: Icons.people_outline,
                color: Colors.teal,
                trend: 'Active profiles',
                sparklineData: const [140, 142, 145, 148, 150, 152, 156],
              ),
              DashboardStatCard(
                label: 'Compliance Alerts',
                value: stats.complianceAlerts.toString(),
                icon: Icons.badge_outlined,
                color: AppColors.error,
                trend: stats.complianceAlerts > 0 ? 'Action Required' : 'All clear',
                isPositive: stats.complianceAlerts == 0,
                sparklineData: const [5, 8, 4, 10, 7, 11, 12],
              ),
              DashboardStatCard(
                label: 'Pending Leaves',
                value: stats.pendingLeaves.toString(),
                icon: Icons.time_to_leave_outlined,
                color: Colors.blue,
                trend: 'Awaiting review',
              ),
              const DashboardStatCard(
                label: 'Housing Capacity',
                value: '—',
                icon: Icons.apartment_rounded,
                color: Colors.indigo,
                trend: 'Not configured',
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
        _buildSectionHeader('Management Modules'),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth > 800 ? 2 : 1,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 2.2,
              children: [
                DashboardActionCard(
                  title: 'Government Integration',
                  subtitle: 'Qiwa, Absher, Iqama, and Insurance',
                  icon: Icons.g_translate_outlined,
                  color: Colors.green,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GovernmentIntegrationScreen())),
                ),
                DashboardActionCard(
                  title: 'Leave & Requests',
                  subtitle: 'Manage leave and staff schedules',
                  icon: Icons.calendar_month_outlined,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LeaveManagementScreen())),
                ),
                DashboardActionCard(
                  title: 'Onboarding Portal',
                  subtitle: 'Digital contracts and training progress',
                  icon: Icons.person_add_alt_1_outlined,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const OnboardingManagementScreen())),
                ),
                DashboardActionCard(
                  title: 'Housing (Mawaqi)',
                  subtitle: 'Managing laborer accommodation assignments',
                  icon: Icons.apartment_outlined,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HousingManagementScreen())),
                ),
                DashboardActionCard(
                  title: 'Asset Accountability',
                  subtitle: 'Company assets assigned to staff',
                  icon: Icons.assignment_turned_in_outlined,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AssetManagementScreen())),
                ),
                DashboardActionCard(
                  title: 'Staff Document Vault',
                  subtitle: 'Central repository for staff records',
                  icon: Icons.folder_shared_outlined,
                  color: Colors.teal,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildComplianceSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Compliance Watch'),
        const SizedBox(height: 24),
        _buildComplianceWatch(ref),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Activity'),
        const SizedBox(height: 24),
        _buildActivityFeed(context, ref),
      ],
    );
  }

  Widget _buildComplianceWatch(WidgetRef ref) {
    final alertsAsync = ref.watch(complianceAlertsProvider);

    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withOpacity(0.1)),
        ),
        child: const Text('Failed to load compliance data',
            style: TextStyle(color: AppColors.error)),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 12),
                Text('All documents are compliant',
                    style: GoogleFonts.outfit(
                        color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        final grouped = <String, int>{};
        for (final alert in alerts) {
          final type = alert['type'] as String? ?? 'Document';
          grouped[type] = (grouped[type] ?? 0) + 1;
        }

        final entries = grouped.entries.toList();
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.error.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 32),
                _buildComplianceItem(
                  entries[i].key,
                  '${entries[i].value} staff member(s)',
                  'Expiring within 30 days',
                  Colors.orange,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplianceItem(
      String title, String count, String status, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(count,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActivityFeed(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(hrRecentActivityProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Text('Failed to load activity',
            style: TextStyle(color: AppColors.error)),
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Text('No recent activity',
                  style:
                      GoogleFonts.outfit(color: AppColors.textSecondary)),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < activities.length; i++) ...[
                if (i > 0) const Divider(height: 32),
                _buildActivityItem(
                  context,
                  activities[i]['profiles']?['full_name'] as String? ??
                      'Unknown',
                  '${activities[i]['type'] ?? 'Request'} — ${activities[i]['status'] ?? 'Pending'}',
                  _formatTime(activities[i]['created_at']),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title,
      String subtitle, String time, IconData icon, Color color) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RiderDetailScreen())),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            Text(time,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
