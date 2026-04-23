import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/fleet/presentation/inventory_handover_screen.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class LeaderDashboard extends ConsumerWidget {
  const LeaderDashboard({super.key});

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
      title: 'LEADER PORTAL',
      subtitle: 'Manage your team and inventory flow',
      actions: [
        IconButton(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout),
        ),
      ],
      children: [
        // Team Stats
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Active Riders',
              value: '12',
              icon: Icons.people_rounded,
              color: AppColors.primary,
              trend: 'Full Team',
            ),
            DashboardStatCard(
              label: 'Pending Handovers',
              value: '3',
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.orange,
              trend: 'Action Needed',
              isPositive: false,
            ),
            DashboardStatCard(
              label: 'Live Incidents',
              value: '1',
              icon: Icons.report_problem_rounded,
              color: AppColors.error,
              trend: 'High Priority',
              isPositive: false,
            ),
            DashboardStatCard(
              label: 'Fleet Readiness',
              value: '98%',
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
              trend: '+2%',
              isPositive: true,
            ),
          ],
        ),

        const SizedBox(height: 32),

        Text(
          'Team Operations',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 2,
          childAspectRatio: 3,
          children: [
            DashboardActionCard(
              title: 'Shift Assignment',
              subtitle: 'Assign riders to clusters',
              icon: Icons.grid_view_rounded,
              color: AppColors.accent,
              onTap: () {},
            ),
            DashboardActionCard(
              title: 'Inventory Handover',
              subtitle: 'Scan QR for bags/fuel cards',
              icon: Icons.qr_code_scanner,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InventoryHandoverScreen()),
                );
              },
            ),
            DashboardActionCard(
              title: 'Live Team Tracking',
              subtitle: 'Monitor 12 active riders',
              icon: Icons.radar_outlined,
              color: Colors.blue,
              onTap: () {},
            ),
            DashboardActionCard(
              title: 'Performance Review',
              subtitle: 'Check team delivery rates',
              icon: Icons.insights_rounded,
              color: Colors.indigo,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Urgent Alert Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Alert',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error),
                    ),
                    Text(
                      'Vehicle Plate 4521-XYZ reported stolen. Immediate action required.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(100, 40),
                ),
                child: const Text('Resolve'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

