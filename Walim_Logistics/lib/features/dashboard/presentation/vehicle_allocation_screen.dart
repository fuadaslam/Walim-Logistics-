import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';
import 'package:walim_logistics/features/tracking/screens/vehicle_detail_screen.dart';
import 'package:walim_logistics/shared/widgets/add_asset_dialog.dart';

class VehicleAllocationScreen extends ConsumerWidget {
  const VehicleAllocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    if (dashboardData.isLoading && dashboardData.fleetAssets.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final assets = dashboardData.fleetAssets;
    final vans = assets.where((a) => a['type'] == 'Van').toList();
    final bikes = assets.where((a) => a['type'] == 'Bike').toList();
    
    final total = assets.length;
    final vanPercentage = total > 0 ? vans.length / total : 0.0;
    final bikePercentage = total > 0 ? bikes.length / total : 0.0;

    return DashboardScaffold(
      title: 'VEHICLE ALLOCATION',
      subtitle: 'Balance fleet distribution and monitor asset assignment',
      showBackButton: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddAssetDialog(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'ADD VEHICLE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
      children: [
        _buildBalanceOverview(context, vanPercentage, bikePercentage, vans.length, bikes.length),
        const SizedBox(height: 32),
        _buildAllocationStats(dashboardData),
        const SizedBox(height: 32),
        _buildDetailedList(context, assets),
      ],
    );
  }

  Widget _buildBalanceOverview(BuildContext context, double vanPct, double bikePct, int vanCount, int bikeCount) {
    final bool hasData = vanCount > 0 || bikeCount > 0;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleet Composition Balance',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current distribution between Vans and Bikes across all active zones',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Stack(
            children: [
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: !hasData 
                  ? Center(
                      child: Text(
                        'NO ASSETS REGISTERED',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  : null,
              ),
              if (hasData)
                Row(
                  children: [
                    if (vanCount > 0)
                      Expanded(
                        flex: (vanPct * 100).toInt().clamp(1, 100),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.horizontal(
                              left: const Radius.circular(24),
                              right: Radius.circular(bikeCount == 0 ? 24 : 0),
                            ),
                          ),
                          child: Center(
                            child: vanPct > 0.15 ? Text(
                              '${(vanPct * 100).toInt()}% VANS',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ) : null,
                          ),
                        ),
                      ),
                    if (bikeCount > 0)
                      Expanded(
                        flex: (bikePct * 100).toInt().clamp(1, 100),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                            ),
                            borderRadius: BorderRadius.horizontal(
                              right: const Radius.circular(24),
                              left: Radius.circular(vanCount == 0 ? 24 : 0),
                            ),
                          ),
                          child: Center(
                            child: bikePct > 0.15 ? Text(
                              '${(bikePct * 100).toInt()}% BIKES',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ) : null,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Vans', vanCount, const Color(0xFF4F46E5)),
              const SizedBox(width: 40),
              _buildLegendItem('Bikes', bikeCount, const Color(0xFF0D9488)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationStats(DashboardData data) {
    final assets = data.fleetAssets;
    final assigned = assets.where((a) => a['assignedTo'] != 'Unassigned').length;
    final unassigned = assets.length - assigned;
    final maintenance = assets.where((a) => a['status'] == 'Maintenance').length;

    return ResponsiveGrid(
      mobileCrossAxisCount: 1,
      tabletCrossAxisCount: 3,
      desktopCrossAxisCount: 3,
      childAspectRatio: 3,
      spacing: 16,
      children: [
        _buildStatCard(
          'Active Allocation',
          assigned.toString(),
          'Vehicles currently on duty',
          Icons.assignment_turned_in_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          'Pool Inventory',
          unassigned.toString(),
          'Available for assignment',
          Icons.inventory_2_rounded,
          Colors.teal,
        ),
        _buildStatCard(
          'Service/Maintenance',
          maintenance.toString(),
          'Assets out of rotation',
          Icons.build_circle_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedList(BuildContext context, List<Map<String, dynamic>> assets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocation Details',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: Text('FILTER ASSETS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (assets.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.local_shipping_outlined,
            title: 'No vehicles found',
            subtitle: 'There are no vehicles currently registered in the fleet system.',
            color: Colors.blueGrey,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 180,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              final isAssigned = asset['assignedTo'] != 'Unassigned';
              final type = asset['type'] as String? ?? 'Van';
              final status = asset['status'] as String? ?? 'Active';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    final vehicle = Vehicle(
                      id: asset['id'].toString(),
                      name: '${asset['type']} — ${asset['plate']}',
                      plateNumber: asset['plate'].toString(),
                      status: asset['status'].toString().toLowerCase(),
                      riderName: isAssigned ? asset['assignedTo'] : null,
                      iqamaNumber: asset['iqamaNumber'] != 'N/A' ? asset['iqamaNumber'] : null,
                      make: asset['make']?.toString() ?? '',
                      model: asset['model']?.toString() ?? '',
                      vin: asset['vin']?.toString() ?? '',
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (type == 'Bike' ? Colors.teal : Colors.indigo).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                type == 'Bike' ? Icons.motorcycle_rounded : Icons.local_shipping_rounded,
                                color: type == 'Bike' ? Colors.teal : Colors.indigo,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset['plate'] ?? 'No Plate',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  Text(
                                    type.toUpperCase(),
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const Spacer(),
                        const Divider(height: 1),
                        const Spacer(),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(isAssigned ? Icons.person_rounded : Icons.person_add_rounded, size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAssigned ? 'Assigned To' : 'Availability',
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    isAssigned ? asset['assignedTo'] : 'Available for duty',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 13,
                                      color: isAssigned ? AppColors.textPrimary : Colors.green,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
