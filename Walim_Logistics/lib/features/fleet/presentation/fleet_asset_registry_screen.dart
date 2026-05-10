import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';
import 'package:walim_logistics/features/tracking/screens/vehicle_detail_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/tracking/screens/map_overview_screen.dart';
import 'package:walim_logistics/shared/widgets/add_asset_dialog.dart';

class FleetAssetRegistryScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const FleetAssetRegistryScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<FleetAssetRegistryScreen> createState() => _FleetAssetRegistryScreenState();
}

enum AssetViewMode { list, map }

class _FleetAssetRegistryScreenState extends ConsumerState<FleetAssetRegistryScreen> {
  AssetViewMode _viewMode = AssetViewMode.list;
  int _currentPage = 0;
  int _rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (dashboardData.isLoading && dashboardData.fleetAssets.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final vehiclesData = dashboardData.fleetAssets;
    
    // Pagination calculation
    final totalItems = vehiclesData.length;
    int totalPages = (totalItems / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    if (_currentPage < 0) _currentPage = 0;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage) < totalItems ? (startIndex + _rowsPerPage) : totalItems;
    final paginatedVehiclesData = totalItems > 0 ? vehiclesData.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];
    
    // Map data to Vehicle models for the Map view
    final List<Vehicle> vehicleModels = vehiclesData.map((v) => Vehicle(
      id: v['id'].toString(),
      name: '${v['type']} - ${v['plate']}',
      plateNumber: v['plate'].toString(),
      status: v['status'].toString().toLowerCase(),
      riderName: v['assignedTo'] != 'Unassigned' ? v['assignedTo'] : null,
      iqamaNumber: v['iqamaNumber'] != 'N/A' ? v['iqamaNumber'] : null,
      make: v['make']?.toString() ?? '',
      model: v['model']?.toString() ?? '',
      vin: v['vin']?.toString() ?? '',
    )).toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        _buildSummaryCards(vehiclesData),
        const SizedBox(height: 32),
        
        // View Controls
        _buildViewControls(context, vehiclesData.length),
        const SizedBox(height: 16),

        // Main Content
        if (_viewMode == AssetViewMode.map && vehiclesData.isNotEmpty)
          Container(
            height: 600,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MapOverviewScreen(vehicles: vehicleModels),
            ),
          )
        else
          vehiclesData.isEmpty
              ? _buildEmptyState(context)
              : Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : AppColors.background),
                              dataRowMaxHeight: 75,
                              dataRowMinHeight: 65,
                              dividerThickness: 0.5,
                              horizontalMargin: 24,
                              columnSpacing: 12,
                              columns: [
                                DataColumn(label: _buildHeaderLabel('VEHICLE', Icons.directions_car_filled_rounded)),
                                DataColumn(label: _buildHeaderLabel('ASSIGNED TO', Icons.person_outline_rounded)),
                                DataColumn(label: _buildHeaderLabel('STATUS', Icons.info_outline_rounded)),
                                DataColumn(label: _buildHeaderLabel('EXPIRY', Icons.event_note_rounded)),
                              ],
                              rows: paginatedVehiclesData.map((v) {
                                final vehicle = Vehicle(
                                  id: v['id'].toString(),
                                  name: '${v['type']} - ${v['plate']}',
                                  plateNumber: v['plate'].toString(),
                                  status: v['status'].toString().toLowerCase(),
                                  riderName: v['assignedTo'] != 'Unassigned' ? v['assignedTo'] : null,
                                  iqamaNumber: v['iqamaNumber'] != 'N/A' ? v['iqamaNumber'] : null,
                                  make: v['make']?.toString() ?? '',
                                  model: v['model']?.toString() ?? '',
                                  vin: v['vin']?.toString() ?? '',
                                );
                                return DataRow(
                                  onSelectChanged: (_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                                      ),
                                    );
                                  },
                                  cells: [
                                    DataCell(_buildAssetCell(v)),
                                    DataCell(_buildAssignmentCell(v)),
                                    DataCell(_buildStatusBadge(v['status'])),
                                    DataCell(_buildExpiryCell(v)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.5),
                        _buildPaginationRow(context, totalItems),
                      ],
                    ),
                  ),
                ),
      ],
    );

    if (!widget.showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 10 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                content,
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'FLEET ASSET REGISTRY',
      subtitle: 'Track vehicle registrations, inspections, and insurance',
      showBackButton: true,
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          ref
              .read(navigationProvider.notifier)
              .setTab(DashboardTab.dashboard);
        }
      },
      actions: [
        IconButton(
          onPressed: () => _showAddAssetDialog(context),
          icon: const Icon(Icons.add_circle_outline,
              size: 28, color: AppColors.primary),
        ),
      ],
      children: [
        content,
      ],
    );
  }

  void _showAddAssetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAssetDialog(),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> vehicles) {
    final total = vehicles.length;
    final active = vehicles.where((v) => v['status'] == 'Active').length;
    final maintenance = vehicles.where((v) => v['status'] == 'Maintenance').length;
    final available = vehicles.where((v) => v['assignedTo'] == 'Unassigned').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile(context) ? 3.0 : 2.5,
          children: [
            _buildStatCard(context, 'Total Vehicles', total.toString(), Icons.directions_car_rounded, Colors.grey.shade500),
            _buildStatCard(context, 'Active Now', active.toString(), Icons.check_circle_rounded, Colors.grey.shade500),
            _buildStatCard(context, 'In Maintenance', maintenance.toString(), Icons.build_circle_rounded, Colors.grey.shade500),
            _buildStatCard(context, 'Available', available.toString(), Icons.event_available_rounded, Colors.grey.shade500),
          ],
        );
      },
    );
  }

  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewControls(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'REGISTERED VEHICLES ($count)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.divider.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(AssetViewMode.list, Icons.list_alt_rounded, 'List'),
              _buildViewToggleButton(AssetViewMode.map, Icons.map_rounded, 'Map'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton(AssetViewMode mode, IconData icon, String label) {
    final isActive = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.primary : AppColors.textSecondary),
            if (!isMobile(context)) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCell(Map<String, dynamic> v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade400.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            v['type'] == 'Bike' ? Icons.motorcycle_rounded : Icons.local_shipping_rounded,
            color: Colors.grey.shade600,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v['plate'].toString(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              v['type'].toString(),
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentCell(Map<String, dynamic> v) {
    final assigned = v['assignedTo'] != 'Unassigned';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey.shade400.withValues(alpha: 0.1),
          backgroundImage: v['avatar'] != null ? NetworkImage(v['avatar']) : null,
          child: v['avatar'] == null ? Icon(Icons.person_rounded, size: 14, color: assigned ? Colors.grey.shade600 : Colors.grey) : null,
        ),
        const SizedBox(width: 10),
        Text(
          v['assignedTo'],
          style: GoogleFonts.outfit(
            fontWeight: assigned ? FontWeight.w600 : FontWeight.w400,
            color: assigned ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryCell(Map<String, dynamic> v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'MVPI: ${v['mvpi']}',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          'INS: ${v['insurance']}',
          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_filled_outlined,
                size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            'No vehicles registered yet',
            style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first fleet asset to the registry.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddAssetDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Register First Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF10B981); // Emerald Green
        break;
      case 'maintenance':
        color = const Color(0xFFF59E0B); // Amber / Orange
        break;
      case 'retired':
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        color = const Color(0xFF3B82F6); // Blue
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaginationRow(BuildContext context, int totalItems) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final totalPages = (totalItems / _rowsPerPage).ceil() == 0 ? 1 : (totalItems / _rowsPerPage).ceil();
    
    final startEntry = _currentPage * _rowsPerPage + 1;
    final endEntry = (startEntry + _rowsPerPage - 1) > totalItems ? totalItems : (startEntry + _rowsPerPage - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: entries description
          Text(
            totalItems == 0 
                ? 'No entries' 
                : 'Showing $startEntry to $endEntry of $totalItems entries',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Right: Row of Page Size and Navigation Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDesktop) ...[
                Text(
                  'Rows per page:',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _rowsPerPage,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      elevation: 2,
                      dropdownColor: theme.cardColor,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _rowsPerPage = newValue;
                            _currentPage = 0; // reset to first page when changing rows per page
                          });
                        }
                      },
                      items: <int>[5, 10, 20, 50].map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              
              // Navigation Buttons
              _buildPaginationButton(
                icon: Icons.first_page_rounded,
                onPressed: _currentPage > 0 
                    ? () => setState(() => _currentPage = 0) 
                    : null,
              ),
              const SizedBox(width: 4),
              _buildPaginationButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onPressed: _currentPage > 0 
                    ? () => setState(() => _currentPage--) 
                    : null,
              ),
              const SizedBox(width: 8),
              
              // Page Numbers / Current Page Info
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(width: 8),
              _buildPaginationButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onPressed: _currentPage < totalPages - 1 
                    ? () => setState(() => _currentPage++) 
                    : null,
              ),
              const SizedBox(width: 4),
              _buildPaginationButton(
                icon: Icons.last_page_rounded,
                onPressed: _currentPage < totalPages - 1 
                    ? () => setState(() => _currentPage = totalPages - 1) 
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({required IconData icon, VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled 
                  ? theme.dividerColor.withValues(alpha: 0.5) 
                  : theme.dividerColor.withValues(alpha: 0.1),
            ),
            color: enabled ? Colors.transparent : theme.disabledColor.withValues(alpha: 0.05),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
