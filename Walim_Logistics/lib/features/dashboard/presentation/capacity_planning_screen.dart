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

    if (dashboardData.isLoading && dashboardData.activeRiders == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DashboardScaffold(
      title: 'CAPACITY PLANNING',
      subtitle: 'Analyze demand and manage fleet recruitment',
      showBackButton: true,
      children: [
        Text(
          'Demand Forecast',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildForecastChart(context, dashboardData),
        const SizedBox(height: 24),
        Text(
          'Capacity vs. Utilization',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 3,
          childAspectRatio: 3.2,
          children: [
            _buildHiringCard(
              peak: 'Current Capacity',
              count: '${dashboardData.activeRiders} / ${dashboardData.peakCapacity}',
              target: 'Total Riders',
              icon: Icons.people_outline_rounded,
              color: AppColors.primary,
            ),
            _buildHiringCard(
              peak: 'Platform Coverage',
              count: '${dashboardData.platforms.length} Platforms',
              target: 'Active Hubs',
              icon: Icons.hub_outlined,
              color: Colors.teal,
            ),
            _buildHiringCard(
              peak: 'Asset Health',
              count: '${dashboardData.assetHealth}% Ready',
              target: 'Fleet Status',
              icon: Icons.vibration_outlined,
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Create Recruitment Campaign'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(300, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastChart(BuildContext context, DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volume Projections (Mock)',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(40, 'Oct', AppColors.primaryLight),
                _buildBar(60, 'Nov', AppColors.primaryLight),
                _buildBar(100, 'Dec', AppColors.primary), // Peak
                _buildBar(50, 'Jan', AppColors.primaryLight),
                _buildBar(80, 'Feb', AppColors.primaryLight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: heightFactor * 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHiringCard({
    required String peak,
    required String count,
    required String target,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peak,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  count,
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                target,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
