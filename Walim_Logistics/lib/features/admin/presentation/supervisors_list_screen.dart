import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

class SupervisorsListScreen extends ConsumerWidget {
  const SupervisorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supervisorsAsync = ref.watch(detailedSupervisorsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return supervisorsAsync.when(
      data: (supervisors) {
        if (supervisors.isEmpty) {
          return _buildEmptyState();
        }
        return _buildSupervisorsTable(context, supervisors, isDark);
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSupervisorsTable(BuildContext context, List<Map<String, dynamic>> supervisors, bool isDark) {
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
                DataColumn(label: _buildHeaderLabel('Supervisor')),
                DataColumn(label: _buildHeaderLabel('Managed Platforms')),
                DataColumn(label: _buildHeaderLabel('Managed Groups')),
                DataColumn(label: _buildHeaderLabel('Action')),
              ],
              rows: supervisors.map((supervisor) => DataRow(
                cells: [
                  DataCell(_buildSupervisorInfo(supervisor)),
                  DataCell(Text(supervisor['managed_platforms'] ?? 'None', style: GoogleFonts.outfit())),
                  DataCell(Text(supervisor['managed_groups'] ?? 'None', style: GoogleFonts.outfit())),
                  DataCell(_buildAction(context, supervisor)),
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

  Widget _buildSupervisorInfo(Map<String, dynamic> supervisor) {
    final name = supervisor['full_name'] ?? 'Supervisor';
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: GoogleFonts.outfit(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAction(BuildContext context, Map<String, dynamic> supervisor) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderDetailScreen(profile: UserProfile.fromJson(supervisor)),
          ),
        );
      },
      child: Text('View Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No supervisors found',
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
