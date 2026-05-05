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
import 'package:walim_logistics/l10n/app_localizations.dart';

class FleetAssetRegistryScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const FleetAssetRegistryScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<FleetAssetRegistryScreen> createState() => _FleetAssetRegistryScreenState();
}

enum AssetViewMode { list, map }

class _FleetAssetRegistryScreenState extends ConsumerState<FleetAssetRegistryScreen> {
  AssetViewMode _viewMode = AssetViewMode.list;

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
    
    // Map data to Vehicle models for the Map view
    final List<Vehicle> vehicleModels = vehiclesData.map((v) => Vehicle(
      id: v['id'].toString(),
      name: '${v['type']} - ${v['plate']}',
      plateNumber: v['plate'].toString(),
      status: v['status'].toString().toLowerCase(),
      riderName: v['assignedTo'] != 'Unassigned' ? v['assignedTo'] : null,
      iqamaNumber: v['iqamaNumber'] != 'N/A' ? v['iqamaNumber'] : null,
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
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehiclesData.length,
                  itemBuilder: (context, index) {
                    final v = vehiclesData[index];
                    return _buildVehicleCard(v, isDesktop);
                  },
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
            _buildStatCard('Total Assets', total.toString(), Icons.inventory_2_rounded, Colors.blue),
            _buildStatCard('Active Now', active.toString(), Icons.check_circle_rounded, Colors.green),
            _buildStatCard('In Maintenance', maintenance.toString(), Icons.build_circle_rounded, Colors.orange),
            _buildStatCard('Available', available.toString(), Icons.event_available_rounded, Colors.teal),
          ],
        );
      },
    );
  }

  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
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
          'REGISTERED ASSETS ($count)',
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
            color: AppColors.divider.withOpacity(0.3),
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
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
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

  Widget _buildVehicleCard(Map<String, dynamic> v, bool isDesktop) {
    final isAlert = v['status'] == 'Maintenance';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? AppColors.error.withOpacity(0.3) : AppColors.divider,
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () {
          final vehicle = Vehicle(
            id: v['id'].toString(),
            name: '${v['type']} - ${v['plate']}',
            plateNumber: v['plate'].toString(),
            status: v['status'].toString().toLowerCase(),
            riderName: v['assignedTo'] != 'Unassigned' ? v['assignedTo'] : null,
            iqamaNumber: v['iqamaNumber'] != 'N/A' ? v['iqamaNumber'] : null,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      v['type'] == 'Bike' ? Icons.motorcycle : Icons.local_shipping,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v['type']} - ${v['plate']}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Asset ID: ${v['id']}',
                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(v['status']),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAssignmentInfo(v),
                    _buildInfoColumn('MVPI Expiry', v['mvpi']),
                    _buildInfoColumn('Insurance Expiry', v['insurance']),
                    _buildUpdateButton(),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAssignmentInfo(v),
                        _buildStatusBadge(v['status']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('MVPI', v['mvpi']),
                        _buildInfoColumn('Insurance', v['insurance']),
                        _buildUpdateButton(),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_filled_outlined,
                size: 80, color: AppColors.primary.withOpacity(0.2)),
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

  Widget _buildAssignmentInfo(Map<String, dynamic> v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: v['avatar'] != null ? NetworkImage(v['avatar']) : null,
          child: v['avatar'] == null ? const Icon(Icons.person, size: 18) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              v['assignedTo'],
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              v['role'] ?? '',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(80, 36),
      ),
      child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
