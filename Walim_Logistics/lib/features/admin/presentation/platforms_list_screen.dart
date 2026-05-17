import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/widgets/walim_table.dart';

class PlatformsListScreen extends ConsumerWidget {
  const PlatformsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(detailedPlatformsProvider);
    final searchQuery = ref.watch(platformSearchQueryProvider).toLowerCase();
    return platformsAsync.when(
      data: (platforms) {
        final filteredPlatforms = platforms.where((plat) {
          return searchQuery.isEmpty ||
              (plat['name']?.toString().toLowerCase().contains(searchQuery) ?? false);
        }).toList();

        return WalimDataTable<Map<String, dynamic>>(
          columns: const [
            WalimColumn(label: 'PLATFORM', icon: Icons.hub_rounded),
            WalimColumn(label: 'SHIFTS', icon: Icons.schedule_rounded),
            WalimColumn(label: 'RIDERS', icon: Icons.motorcycle_rounded),
            WalimColumn(label: 'SUPERVISORS', icon: Icons.supervisor_account_rounded),
          ],
          items: filteredPlatforms,
          rowBuilder: (pagedPlatforms) => pagedPlatforms.map((platform) => DataRow(
            cells: [
              DataCell(_buildPlatformInfo(platform)),
              DataCell(Text(platform['shifts'] ?? 'No active shifts', style: GoogleFonts.outfit(fontWeight: FontWeight.w500))),
              DataCell(_buildCountBadge(platform['riders_count'].toString())),
              DataCell(Text(platform['supervisors'] ?? 'None', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
            ],
          )).toList(),
          emptyState: _buildEmptyState(),
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPlatformInfo(Map<String, dynamic> platform) {
    final color = Colors.grey.shade500;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.hub_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              platform['name'] ?? 'Unknown Platform',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Integrated Platform',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountBadge(String count) {
    final color = Colors.grey.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        count,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No platforms found',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
