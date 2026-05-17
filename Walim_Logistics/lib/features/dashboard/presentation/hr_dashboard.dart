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
    final stats = ref.watch(hrStatsProvider);

    final List<Widget> contentWidgets = [
      // Premium Refresh Bar & Context
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'OVERVIEW & INSIGHTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            DashboardRefreshBar(
              lastUpdated: DateTime.now(), // or keep track in state/notifier if available
              isLoading: stats.isLoading,
              onRefresh: () {
                ref.read(hrStatsProvider.notifier).loadStats();
                ref.invalidate(complianceAlertsProvider);
                ref.invalidate(hrRecentActivityProvider);
              },
            ),
          ],
        ),
      ),
    ];

    if (!isDesktop) {
      contentWidgets.addAll(
        layout.sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _buildSection(context, ref, section),
        )).toList(),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
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
        leftColumn.add(const SizedBox(height: 40));
      } else {
        rightColumn.add(sectionWidget);
        rightColumn.add(const SizedBox(height: 40));
      }
    }

    contentWidgets.add(
      Row(
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
      )
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
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
        _buildSectionHeader('Workforce Ecosystem'),
        const SizedBox(height: 24),
        if (stats.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else
          ResponsiveGrid(
            desktopCrossAxisCount: 4,
            tabletCrossAxisCount: 4,
            mobileCrossAxisCount: 2,
            spacing: 16,
            childAspectRatio: 1.4,
            children: [
              DashboardStatCard(
                label: 'Total Staff',
                value: stats.totalStaff.toString(),
                icon: Icons.supervised_user_circle_outlined,
                color: Colors.blueAccent,
                trend: 'Live workforce',
                isPositive: true,
                sparklineData: const [140, 142, 145, 148, 150, 152, 156, 155, 158, 162],
              ),
              DashboardStatCard(
                label: 'Compliance Alerts',
                value: stats.complianceAlerts.toString(),
                icon: Icons.shield_outlined,
                color: stats.complianceAlerts > 0 ? AppColors.error : Colors.green,
                trend: stats.complianceAlerts > 0 ? 'Action Critical' : 'Optimal',
                isPositive: stats.complianceAlerts == 0,
                sparklineData: const [5, 8, 4, 10, 7, 11, 12, 9, 8],
              ),
              DashboardStatCard(
                label: 'Active Leaves',
                value: stats.pendingLeaves.toString(),
                icon: Icons.event_busy_outlined,
                color: Colors.amber.shade700,
                trend: 'Requires attention',
                isPositive: stats.pendingLeaves < 5,
                sparklineData: const [2, 1, 3, 2, 4, 3, 2],
              ),
              DashboardStatCard(
                label: 'Active Staff Rate',
                value: '${stats.activeStaffRate}%',
                icon: Icons.group_outlined,
                color: Colors.deepPurpleAccent,
                trend: 'Of total workforce',
                isPositive: stats.activeStaffRate >= 70,
                sparklineData: const [60, 65, 70, 72, 75, 78, 80],
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
        _buildSectionHeader('Governance Core'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          desktopCrossAxisCount: 2,
          tabletCrossAxisCount: 2,
          mobileCrossAxisCount: 1,
          spacing: 16,
          childAspectRatio: 2.6,
          children: [
            DashboardActionCard(
              title: 'Government Portal',
              subtitle: 'Absher, Qiwa & Insurance synced',
              icon: Icons.account_balance_outlined,
              color: Colors.indigoAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GovernmentIntegrationScreen())),
            ),
            DashboardActionCard(
              title: 'Leaves & Logistics',
              subtitle: 'Employee schedule orchestration',
              icon: Icons.perm_contact_calendar_outlined,
              color: Colors.orangeAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaveManagementScreen())),
            ),
            DashboardActionCard(
              title: 'Smart Onboarding',
              subtitle: 'Pipeline, contracts & compliance',
              icon: Icons.rocket_launch_outlined,
              color: Colors.cyan,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OnboardingManagementScreen())),
            ),
            DashboardActionCard(
              title: 'Housing Network',
              subtitle: 'Real estate & capacity control',
              icon: Icons.corporate_fare_rounded,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HousingManagementScreen())),
            ),
            DashboardActionCard(
              title: 'Digital Vault',
              subtitle: 'Protected repository for identities',
              icon: Icons.fingerprint_rounded,
              color: Colors.teal,
              onTap: () {
                 // TODO: Route to asset / vault
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Security & Compliance'),
        const SizedBox(height: 24),
        _buildComplianceWatch(ref),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Orchestration Feed'),
        const SizedBox(height: 24),
        _buildActivityFeed(context, ref),
      ],
    );
  }

  Widget _buildComplianceWatch(WidgetRef ref) {
    final alertsAsync = ref.watch(complianceAlertsProvider);
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: alertsAsync.when(
        loading: () => Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.1))
          ),
          child: const CircularProgressIndicator(strokeWidth: 2.5)
        ),
        error: (e, _) => const EmptyStatePlaceholder(
          icon: Icons.gpp_maybe_rounded,
          title: 'Compliance Interrupted',
          subtitle: 'Unable to connect to compliance sync server.',
          color: AppColors.error,
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyStatePlaceholder(
              icon: Icons.verified_rounded,
              title: 'Zero Violations',
              subtitle: 'System architecture conforms entirely to mandatory regulations.',
              color: Colors.teal,
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
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.error.withValues(alpha: 0.05),
                  Colors.transparent
                ]
              )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${alerts.length} PENDING DISCREPANCIES',
                      style: GoogleFonts.outfit(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...List.generate(entries.length, (index) {
                  final isLast = index == entries.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: _buildEnhancedComplianceItem(
                      entries[index].key,
                      'Requires immediate validation for ${entries[index].value} instances',
                      'URGENT',
                      Colors.orangeAccent,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedComplianceItem(
      String title, String subtitle, String tag, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notification_important_rounded, color: accent, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: GoogleFonts.outfit(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(hrRecentActivityProvider);

    return activityAsync.when(
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.1))
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      ),
      error: (e, _) => const EmptyStatePlaceholder(
        icon: Icons.running_with_errors_outlined,
        title: 'Activity Feed Offline',
        subtitle: 'Encountered temporal sync failure.',
        color: AppColors.error,
      ),
      data: (activities) {
        final feedItems = activities.map((activity) {
          final name = activity['profiles']?['full_name'] as String? ?? 'Unknown User';
          final type = activity['type'] as String? ?? 'Interaction';
          final status = activity['status'] as String? ?? 'Logged';
          
          IconData icon;
          Color accent;
          if (type.toLowerCase().contains('leave')) {
            icon = Icons.beach_access_rounded;
            accent = Colors.orange;
          } else if (type.toLowerCase().contains('document')) {
            icon = Icons.file_present_rounded;
            accent = Colors.blue;
          } else {
            icon = Icons.bolt_rounded;
            accent = Colors.teal;
          }

          return ActivityItem(
            title: name,
            subtitle: '$type requested - Status: $status',
            time: _formatTime(activity['created_at']),
            icon: icon,
            color: accent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDetailScreen()));
            },
          );
        }).toList();

        return ActivityFeed(
          items: feedItems,
          onViewAll: () {
            // Handle global activity exploration
          },
        );
      },
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '—';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      ),
    );
  }
}
