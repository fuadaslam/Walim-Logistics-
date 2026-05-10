import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/shared/widgets/walim_table.dart';

class SupervisorsListScreen extends ConsumerWidget {
  const SupervisorsListScreen({super.key});

  static const List<Color> avatarGradients = [
    Colors.blueAccent,
    Colors.indigoAccent,
    Colors.deepPurpleAccent,
    Colors.tealAccent,
    Colors.deepOrangeAccent,
    Colors.amber,
  ];

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return avatarGradients[0];
    final code = name.codeUnitAt(0) + name.length;
    return avatarGradients[code % avatarGradients.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supervisorsAsync = ref.watch(detailedSupervisorsProvider);
    final searchQuery = ref.watch(supervisorSearchQueryProvider).toLowerCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return supervisorsAsync.when(
      data: (supervisors) {
        final filteredSupervisors = supervisors.where((sup) {
          final fullName = sup['full_name']?.toString().toLowerCase() ?? '';
          final platforms = sup['managed_platforms']?.toString().toLowerCase() ?? '';
          final groups = sup['managed_groups']?.toString().toLowerCase() ?? '';
          return searchQuery.isEmpty ||
              fullName.contains(searchQuery) ||
              platforms.contains(searchQuery) ||
              groups.contains(searchQuery);
        }).toList();

        return WalimDataTable<Map<String, dynamic>>(
          columns: const [
            WalimColumn(label: 'SUPERVISOR PROFILE', icon: Icons.badge_outlined),
            WalimColumn(label: 'PLATFORMS', icon: Icons.hub_outlined),
            WalimColumn(label: 'ASSIGNED GROUPS', icon: Icons.group_work_outlined),
            WalimColumn(label: 'ACTION', icon: Icons.bolt_rounded),
          ],
          items: filteredSupervisors,
          rowBuilder: (pagedSupervisors) => pagedSupervisors.map((supervisor) => DataRow(
            onSelectChanged: (_) => _navigateToDetail(context, supervisor),
            cells: [
              DataCell(_buildSupervisorInfo(supervisor)),
              DataCell(_buildBadgeCloud(supervisor['managed_platforms'], Colors.indigoAccent, isDark)),
              DataCell(_buildBadgeCloud(supervisor['managed_groups'], Colors.teal, isDark)),
              DataCell(
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          )).toList(),
          emptyState: _buildEnhancedEmptyState(),
        );
      },
      loading: () => Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text('Synchronizing roster data...', 
                style: TextStyle(color: AppColors.textSecondary, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load supervisors roster', 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(err.toString(), style: const TextStyle(color: AppColors.textSecondary)),
          ],
        )
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> supervisor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderDetailScreen(profile: UserProfile.fromJson(supervisor)),
      ),
    );
  }

  Widget _buildBadgeCloud(String? rawData, Color baseColor, bool isDark) {
    if (rawData == null || rawData.trim().isEmpty || rawData.toLowerCase() == 'none') {
      return Text(
        '—',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Split by common delimiters
    final items = rawData
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3) // Restrict visible counts for layout cleanliness
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: baseColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            tag,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? baseColor.withValues(alpha: 0.9) : baseColor.withValues(alpha: 0.8),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSupervisorInfo(Map<String, dynamic> supervisor) {
    final name = supervisor['full_name'] as String? ?? 'Unknown System User';
    final accentColor = _getAvatarColor(name);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACTIVE LEADER',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.05), width: 2)
            ),
            child: Icon(Icons.person_search_outlined, size: 52, color: Colors.indigo.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            'Null Roster Match',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 280,
            child: Text(
              'No supervisory records dynamically match your specified analytical parameters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
