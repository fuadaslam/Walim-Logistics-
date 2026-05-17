import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class CapacityPlanningScreen extends ConsumerWidget {
  const CapacityPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (dashboardData.isLoading && dashboardData.activeRiders == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DashboardScaffold(
      title: 'CAPACITY PLANNING',
      subtitle: 'Analyze demand and manage fleet recruitment strategy',
      showBackButton: true,
      children: [
        _buildSectionHeader('Demand Forecast'),
        const SizedBox(height: 16),
        _buildForecastChart(context, dashboardData, isDark),
        const SizedBox(height: 32),
        _buildSectionHeader('Capacity vs. Utilization'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 3,
          childAspectRatio: 2.5,
          spacing: 20,
          children: [
            DashboardStatCard(
              label: 'Current Capacity',
              value: '${dashboardData.activeRiders} / ${dashboardData.peakCapacity == 0 ? '--' : dashboardData.peakCapacity}',
              trend: 'Total Riders',
              icon: Icons.people_outline_rounded,
              color: AppColors.primary,
              sparklineData: [40, 45, 42, 48, 52, 50, 55], // Mock trend
            ),
            DashboardStatCard(
              label: 'Platform Coverage',
              value: '${dashboardData.platforms.length}',
              trend: 'Active Hubs',
              icon: Icons.hub_outlined,
              color: Colors.teal,
              sparklineData: [2, 3, 3, 4, 4, 5, 5], // Mock trend
            ),
            DashboardStatCard(
              label: 'Asset Health',
              value: '${dashboardData.assetHealth}%',
              trend: 'Fleet Status',
              icon: Icons.vibration_outlined,
              color: Colors.orange,
              isPositive: dashboardData.assetHealth > 80,
              sparklineData: [85, 82, 88, 90, 87, 85, 89], // Mock trend
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildActionBanner(context, isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildForecastChart(BuildContext context, DashboardData data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume Projections (Mock)',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Predicted order volume for the next 5 months',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI POWERED',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAnimatedBar(0.4, 'Oct', AppColors.primaryLight, isDark),
                _buildAnimatedBar(0.6, 'Nov', AppColors.primaryLight, isDark),
                _buildAnimatedBar(1.0, 'Dec', AppColors.primary, isDark, isPeak: true),
                _buildAnimatedBar(0.5, 'Jan', AppColors.primaryLight, isDark),
                _buildAnimatedBar(0.8, 'Feb', AppColors.primaryLight, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: (isDark ? Colors.white : AppColors.divider).withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricHint(Icons.trending_up, '15% Growth', 'MoM Projection'),
              _buildMetricHint(Icons.people_outline, '120 Riders', 'Target Hiring'),
              _buildMetricHint(Icons.flash_on_rounded, '98.5%', 'Confidence Score'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBar(double heightFactor, String label, Color color, bool isDark, {bool isPeak = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          tween: Tween(begin: 0, end: heightFactor * 180),
          builder: (context, height, child) {
            return Container(
              width: 50,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isPeak ? AppColors.primary : color,
                    isPeak ? AppColors.primaryLight : color.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: isPeak ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: isPeak ? const Center(
                child: Icon(Icons.star_rounded, color: Colors.white, size: 20),
              ) : null,
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricHint(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                  'Scale Your Operations',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Predicted peak in December requires 120 new riders. Start your recruitment campaign today to meet the demand.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Launch Campaign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(220, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              shadowColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
