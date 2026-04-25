import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';

import 'package:last_mile_fleet/features/finance/presentation/reconciliation_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:last_mile_fleet/features/tracking/services/tracking_provider.dart';
import 'package:last_mile_fleet/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:last_mile_fleet/features/tracking/theme/app_theme.dart' as tracking_theme;
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

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
      title: 'CONTROL TOWER',
      subtitle: 'Real-time metrics across all zones and platforms',
      actions: [
        IconButton(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout, color: AppColors.textPrimary),
        ),
      ],
      children: [
        // KPI Section
        ResponsiveGrid(
          children: [
            const DashboardStatCard(
              label: 'Active Riders',
              value: '142',
              icon: Icons.motorcycle,
              color: Colors.blue,
              trend: '+12%',
              isPositive: true,
            ),
            const DashboardStatCard(
              label: 'Live Orders',
              value: '854',
              icon: Icons.shopping_bag_outlined,
              color: Colors.orange,
              trend: '+5.4%',
              isPositive: true,
            ),
            const DashboardStatCard(
              label: 'Fleet Health',
              value: '94%',
              icon: Icons.verified_user_outlined,
              color: Colors.green,
              trend: '-1%',
              isPositive: false,
            ),
            const DashboardStatCard(
              label: 'Pending COD',
              value: '﷼ 12.4k',
              icon: Icons.payments_outlined,
              color: Colors.purple,
              trend: '+8%',
              isPositive: true,
            ),
          ],
        ),
        
        const SizedBox(height: 40),

        // Management Tools Section
        Text(
          'Management Tools',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 2 : 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 3 : 2.5,
              children: [
                DashboardActionCard(
                  title: 'Live Operations Map',
                  subtitle: 'Monitor all active riders and deliveries',
                  icon: Icons.map_outlined,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => provider_pkg.ChangeNotifierProvider(
                      create: (_) => TrackingProvider(),
                      child: Theme(
                        data: tracking_theme.AppTheme.theme,
                        child: const walim_tracking.HomeScreen(),
                      ),
                    ),
                  )),
                ),
                DashboardActionCard(
                  title: 'Financial Reconciliation',
                  subtitle: 'Audit COD collections and platform reports',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReconciliationDashboard())),
                ),
                DashboardActionCard(
                  title: 'Inventory & Assets',
                  subtitle: 'Manage uniforms, bags, and fuel cards',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange,
                  onTap: () {},
                ),
                DashboardActionCard(
                  title: 'Performance Analytics',
                  subtitle: 'View detailed fleet and rider reports',
                  icon: Icons.analytics_outlined,
                  color: Colors.indigo,
                  onTap: () {},
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}

