import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class AssetManagementScreen extends StatelessWidget {
  const AssetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'ASSET RESPONSIBILITY',
      subtitle: 'Tracking company assets assigned to staff members',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        _buildAssetStats(),
        const SizedBox(height: 32),
        _buildStaffAssetList(),
      ],
    );
  }

  Widget _buildAssetStats() {
    return Row(
      children: [
        _buildStatCard('Assigned Assets', '342', Icons.inventory_2_rounded, AppColors.primary),
        const SizedBox(width: 16),
        _buildStatCard('Awaiting Return', '18', Icons.assignment_return_rounded, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('Damaged/Lost', '4', Icons.report_problem_rounded, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffAssetList() {
    final List<Map<String, dynamic>> staffAssets = [
      {
        'name': 'Ahmed Ali',
        'role': 'Rider',
        'assets': [
          {'type': 'Vehicle', 'id': 'V-9021', 'desc': 'Honda CD 110'},
          {'type': 'Fuel Card', 'id': 'FC-442', 'desc': 'Aramco 500 SAR'},
          {'type': 'Uniform', 'id': 'U-XL', 'desc': 'Set of 2'},
        ]
      },
      {
        'name': 'Mohammed Khan',
        'role': 'Rider',
        'assets': [
          {'type': 'Vehicle', 'id': 'V-8812', 'desc': 'Yamaha YS125'},
          {'type': 'Smartphone', 'id': 'SP-77', 'desc': 'Samsung A14'},
        ]
      },
      {
        'name': 'Sarah Al-Otaibi',
        'role': 'Operations',
        'assets': [
          {'type': 'Laptop', 'id': 'LP-012', 'desc': 'MacBook Air M2'},
          {'type': 'Access Badge', 'id': 'AB-404', 'desc': 'HQ Level 2'},
        ]
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: staffAssets.length,
      itemBuilder: (context, index) {
        final staff = staffAssets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: CircleAvatar(
              backgroundColor: AppColors.background,
              child: Text(staff['name'][0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(staff['role'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: Text('${staff['assets'].length} Assets', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: (staff['assets'] as List).map((asset) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _getAssetIcon(asset['type']),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(asset['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(asset['desc'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text(asset['id'], style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getAssetIcon(String type) {
    IconData icon;
    switch (type) {
      case 'Vehicle': icon = Icons.motorcycle_rounded; break;
      case 'Laptop': icon = Icons.laptop_mac_rounded; break;
      case 'Smartphone': icon = Icons.phone_android_rounded; break;
      case 'Fuel Card': icon = Icons.credit_card_rounded; break;
      default: icon = Icons.inventory_2_outlined;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
    );
  }
}
