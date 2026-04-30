import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class FleetAssetRegistryScreen extends StatelessWidget {
  final bool showScaffold;
  const FleetAssetRegistryScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _vehicles = [
      {'id': 'VH-001', 'plate': '4521-XYZ', 'type': 'Bike', 'status': 'Active', 'mvpi': 'Oct 2024', 'insurance': 'Jan 2025'},
      {'id': 'VH-002', 'plate': '8832-ABC', 'type': 'Van', 'status': 'Maintenance', 'mvpi': 'May 2024', 'insurance': 'Aug 2024'},
      {'id': 'VH-003', 'plate': '1029-KLM', 'type': 'Bike', 'status': 'Active', 'mvpi': 'Dec 2024', 'insurance': 'Feb 2025'},
    ];

    final content = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        final isAlert = v['status'] == 'Maintenance';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isAlert ? AppColors.error.withOpacity(0.3) : AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(v['type'] == 'Bike' ? Icons.motorcycle : Icons.local_shipping, color: AppColors.accent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${v['type']} - ${v['plate']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Asset ID: ${v['id']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(v['status']),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('MVPI Expiry', v['mvpi']),
                  _buildInfoColumn('Insurance Expiry', v['insurance']),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
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
        IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary)),
      ],
      children: [
        content,
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
