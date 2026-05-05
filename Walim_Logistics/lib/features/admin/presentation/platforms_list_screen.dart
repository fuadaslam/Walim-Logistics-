import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';

class PlatformsListScreen extends ConsumerWidget {
  const PlatformsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(detailedPlatformsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return platformsAsync.when(
      data: (platforms) {
        if (platforms.isEmpty) {
          return _buildEmptyState();
        }
        return _buildPlatformsTable(context, platforms, isDark);
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPlatformsTable(BuildContext context, List<Map<String, dynamic>> platforms, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background),
              dataRowMaxHeight: 70,
              dividerThickness: 0.5,
              columns: [
                DataColumn(label: _buildHeaderLabel('Platform')),
                DataColumn(label: _buildHeaderLabel('Active Shifts')),
                DataColumn(label: _buildHeaderLabel('Allocated Riders')),
                DataColumn(label: _buildHeaderLabel('Assigned Supervisors')),
              ],
              rows: platforms.map((platform) => DataRow(
                cells: [
                  DataCell(_buildPlatformInfo(platform)),
                  DataCell(Text(platform['shifts'] ?? 'No active shifts', style: GoogleFonts.outfit())),
                  DataCell(_buildCountBadge(platform['riders_count'].toString())),
                  DataCell(Text(platform['supervisors'] ?? 'None', style: GoogleFonts.outfit())),
                ],
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPlatformInfo(Map<String, dynamic> platform) {
    final name = platform['name'] ?? 'Platform';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.hub_rounded, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCountBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: GoogleFonts.outfit(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.business_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No platforms found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
