import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/shared/widgets/walim_table.dart';

class RidersListScreen extends ConsumerStatefulWidget {
  const RidersListScreen({super.key});

  @override
  ConsumerState<RidersListScreen> createState() => _RidersListScreenState();
}

class _RidersListScreenState extends ConsumerState<RidersListScreen> {
  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(detailedRidersProvider);
    final searchQuery = ref.watch(riderSearchQueryProvider).toLowerCase();
    final statusFilter = ref.watch(riderFilterStatusProvider);
    
    return ridersAsync.when(
      data: (allRiders) {
        // Apply filters
        var filteredRiders = allRiders.where((rider) {
          final matchesSearch = searchQuery.isEmpty ||
              (rider['full_name']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
              (rider['iqama_number']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
              (rider['phone_number']?.toString().toLowerCase().contains(searchQuery) ?? false);
          
          final matchesStatus = statusFilter == null || rider['status'] == statusFilter;
          
          return matchesSearch && matchesStatus;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(context),
            const SizedBox(height: 24),
            Expanded(
              child: WalimDataTable<Map<String, dynamic>>(
                columns: const [
                  WalimColumn(label: 'RIDER', icon: Icons.person_outline_rounded),
                  WalimColumn(label: 'STATUS', icon: Icons.info_outline_rounded),
                  WalimColumn(label: 'VEHICLE', icon: Icons.motorcycle_rounded),
                  WalimColumn(label: 'IQAMA', icon: Icons.badge_outlined),
                  WalimColumn(label: 'PHONE', icon: Icons.phone_android_rounded),
                ],
                items: filteredRiders,
                rowBuilder: (pagedRiders) => pagedRiders.map((rider) => DataRow(
                  onSelectChanged: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderDetailScreen(profile: UserProfile.fromJson(rider)),
                      ),
                    );
                  },
                  cells: [
                    DataCell(_buildRiderInfo(rider)),
                    DataCell(_buildStatusBadge(rider['status'] ?? 'unknown')),
                    DataCell(Text(rider['vehicle'] ?? 'No vehicle', style: GoogleFonts.outfit(fontWeight: FontWeight.w500))),
                    DataCell(Text(rider['iqama_number'] ?? 'N/A', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
                    DataCell(Text(rider['phone_number'] ?? 'N/A', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
                  ],
                )).toList(),
                emptyState: _buildEmptyState(),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final currentStatus = ref.watch(riderFilterStatusProvider);
    final statuses = [null, 'active', 'on leave', 'inactive'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = currentStatus == status;
                  final label = status == null ? 'All Status' : status.toUpperCase();
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label, style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondary),
                      )),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(riderFilterStatusProvider.notifier).state = selected ? status : null;
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        width: 1,
                      ),
                      showCheckmark: false,
                      elevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInfo(Map<String, dynamic> rider) {
    final name = rider['full_name'] ?? 'Rider';
    final color = Colors.grey.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rider['group_name'] ?? 'General Fleet',
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

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase().replaceAll('_', ' ')) {
      case 'active':
      case 'active completed':
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF10B981); // Emerald Green
        break;
      case 'active pending':
        icon = Icons.pending_actions_rounded;
        color = const Color(0xFFF59E0B); // Amber for Pending
        break;
      case 'on leave': 
        icon = Icons.pause_circle_filled_rounded;
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 'inactive':
      case 'inactive completed':
      case 'inactive pending':
        icon = Icons.cancel_rounded;
        color = const Color(0xFFEF4444); // Red
        break;
      default: 
        icon = Icons.help_rounded;
        color = const Color(0xFF64748B); // Slate Grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
            child: Icon(Icons.people_outline_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No riders found',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
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
