import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

class RidersListScreen extends ConsumerStatefulWidget {
  const RidersListScreen({super.key});

  @override
  ConsumerState<RidersListScreen> createState() => _RidersListScreenState();
}

class _RidersListScreenState extends ConsumerState<RidersListScreen> {
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(detailedRidersProvider);
    final searchQuery = ref.watch(riderSearchQueryProvider).toLowerCase();
    final statusFilter = ref.watch(riderFilterStatusProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

        if (allRiders.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(context),
            const SizedBox(height: 20),
            Expanded(
              child: _buildRidersTable(context, filteredRiders, isDark),
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
    
    return SingleChildScrollView(
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              )),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(riderFilterStatusProvider.notifier).state = selected ? status : null;
                setState(() {
                  _currentPage = 0; // Reset to first page on filter change
                });
              },
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRidersTable(BuildContext context, List<Map<String, dynamic>> riders, bool isDark) {
    // Client-side pagination
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage) < riders.length ? (startIndex + _rowsPerPage) : riders.length;
    final pagedRiders = riders.isEmpty ? <Map<String, dynamic>>[] : riders.sublist(startIndex, endIndex);
    final totalPages = (riders.length / _rowsPerPage).ceil();

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
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background),
                    dataRowMaxHeight: 70,
                    dividerThickness: 0.5,
                    columns: [
                      DataColumn(label: _buildHeaderLabel('Rider')),
                      DataColumn(label: _buildHeaderLabel('Status')),
                      DataColumn(label: _buildHeaderLabel('Vehicle')),
                      DataColumn(label: _buildHeaderLabel('Iqama Number')),
                      DataColumn(label: _buildHeaderLabel('Phone')),
                      DataColumn(label: _buildHeaderLabel('Action')),
                    ],
                    rows: pagedRiders.map((rider) => DataRow(
                      cells: [
                        DataCell(_buildRiderInfo(rider)),
                        DataCell(_buildStatusBadge(rider['status'] ?? 'unknown')),
                        DataCell(Text(rider['vehicle'] ?? 'No vehicle', style: GoogleFonts.outfit())),
                        DataCell(Text(rider['iqama_number'] ?? 'N/A', style: GoogleFonts.outfit())),
                        DataCell(Text(rider['phone_number'] ?? 'N/A', style: GoogleFonts.outfit())),
                        DataCell(_buildAction(context, rider)),
                      ],
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
          _buildPaginationFooter(riders.length, totalPages, isDark),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int totalItems, int totalPages, bool isDark) {
    if (totalItems == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage * _rowsPerPage) + 1} to ${((_currentPage + 1) * _rowsPerPage).clamp(0, totalItems)} of $totalItems riders',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                // Show only a few page numbers if there are many
                if (totalPages > 7) {
                  if (index != 0 && index != totalPages - 1 && (index < _currentPage - 1 || index > _currentPage + 1)) {
                    if (index == _currentPage - 2 || index == _currentPage + 2) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...'),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPageNumber(index, isDark),
                );
              }),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(int index, bool isDark) {
    final isSelected = _currentPage == index;
    return InkWell(
      onTap: () => setState(() => _currentPage = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : AppColors.divider),
          ),
        ),
        child: Text(
          '${index + 1}',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.divider),
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

  Widget _buildRiderInfo(Map<String, dynamic> rider) {
    final name = rider['full_name'] ?? 'Rider';
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active': color = Colors.green; break;
      case 'on leave': color = Colors.orange; break;
      case 'inactive': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, Map<String, dynamic> rider) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderDetailScreen(profile: UserProfile.fromJson(rider)),
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
            'No riders found',
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
