import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/features/fleet/presentation/live_tracking_screen.dart';
import 'package:last_mile_fleet/features/incidents/presentation/incident_approval_screen.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'PERFORMANCE HUB',
      subtitle: 'Oversee operations and resolve blockers',
      actions: [
        IconButton(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout),
        ),
      ],
      children: [
        // KPI Section
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Avg. Delivery',
              value: '18m',
              icon: Icons.timer_outlined,
              color: AppColors.accent,
              trend: '-2m',
              isPositive: true,
            ),
            DashboardStatCard(
              label: 'Success Rate',
              value: '98.2%',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              trend: '+0.5%',
              isPositive: true,
            ),
            DashboardStatCard(
              label: 'Fleet Utilization',
              value: '84%',
              icon: Icons.local_shipping_outlined,
              color: Colors.blue,
              trend: '+5%',
              isPositive: true,
            ),
            DashboardStatCard(
              label: 'Open Incidents',
              value: '4',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              trend: 'Action required',
              isPositive: false,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Live Tracking Preview
        Text(
          'Real-time Operations',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        
        DashboardActionCard(
          title: 'Live Tracking Map',
          subtitle: 'Currently monitoring 42 active riders in Riyadh South',
          icon: Icons.map_outlined,
          color: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
            );
          },
        ),

        const SizedBox(height: 32),

        Text(
          'Incident Management',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        _buildIncidentCard(
          rider: 'Khalid Mansour',
          type: 'Delay Justification',
          time: '10 mins ago',
          status: 'Awaiting Review',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IncidentApprovalScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildIncidentCard(
          rider: 'Youssef Ali',
          type: 'Accident Report',
          time: '1 hour ago',
          status: 'Investigating',
        ),
      ],
    );
  }

  Widget _buildIncidentCard({
    required String rider,
    required String type,
    required String time,
    required String status,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.background,
              child: Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$type • $time',
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: GoogleFonts.outfit(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

