import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class HousingManagementScreen extends StatelessWidget {
  const HousingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _accommodations = [
      {'name': 'Sakan Al-Malaz', 'location': 'Riyadh East', 'capacity': 40, 'occupied': 38, 'type': 'Rider Housing'},
      {'name': 'Batha Camp', 'location': 'Riyadh Central', 'capacity': 100, 'occupied': 85, 'type': 'Rider Housing'},
      {'name': 'Exit 28 Apartments', 'location': 'Riyadh West', 'capacity': 20, 'occupied': 12, 'type': 'Staff Housing'},
    ];

    return DashboardScaffold(
      title: 'HOUSING & MAWAQI',
      subtitle: 'Manage laborer accommodation and assignments',
      showBackButton: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _accommodations.length,
          itemBuilder: (context, index) {
            final s = _accommodations[index];
            final occupancy = s['occupied'] / s['capacity'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      _buildTypeTag(s['type']),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(s['location'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Occupancy: ${s['occupied']}/${s['capacity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(occupancy * 100).toInt()}% Full', style: TextStyle(color: occupancy > 0.9 ? AppColors.error : Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: occupancy,
                    backgroundColor: AppColors.background,
                    color: occupancy > 0.9 ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    child: const Text('Manage Assignments'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeTag(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
    );
  }
}
