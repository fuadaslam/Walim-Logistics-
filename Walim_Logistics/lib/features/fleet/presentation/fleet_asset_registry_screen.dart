import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';
import 'package:walim_logistics/features/tracking/screens/vehicle_detail_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class FleetAssetRegistryScreen extends ConsumerWidget {
  final bool showScaffold;
  const FleetAssetRegistryScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (dashboardData.isLoading && dashboardData.fleetAssets.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final vehicles = dashboardData.fleetAssets;

    final content = vehicles.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final isAlert = v['status'] == 'Maintenance';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAlert
                        ? AppColors.error.withOpacity(0.3)
                        : AppColors.divider,
                    width: isAlert ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
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
                                v['type'] == 'Bike'
                                    ? Icons.motorcycle
                                    : Icons.local_shipping,
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
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
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
                              // Assigned To Info
                              _buildAssignmentInfo(v),
                              // Expiry Info Columns
                              _buildInfoColumn('MVPI Expiry', v['mvpi']),
                              _buildInfoColumn('Insurance Expiry', v['insurance']),
                              // Update Button
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
                                  _buildStatusBadge(
                                      v['status']), // Re-show status on mobile
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
            },
          );

    if (!showScaffold) return content;

    return DashboardScaffold(
      title: 'FLEET ASSET REGISTRY',
      subtitle: 'Track vehicle registrations, inspections, and insurance',
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline,
              size: 28, color: AppColors.primary),
        ),
      ],
      children: [
        content,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.directions_car_filled_outlined,
              size: 64, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No vehicles registered yet',
            style: GoogleFonts.outfit(
                fontSize: 18, color: AppColors.textSecondary),
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
          backgroundImage: NetworkImage(v['avatar']),
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
              v['role'],
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (v['iqamaNumber'] != 'N/A')
              Text(
                'Iqama: ${v['iqamaNumber']}',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
