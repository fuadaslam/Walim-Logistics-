import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class PartnerPortalsScreen extends StatelessWidget {
  const PartnerPortalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _partners = [
      {'name': 'Noon', 'deliveries': '4.2k', 'status': 'Contract Active', 'color': Colors.amber},
      {'name': 'Amazon', 'deliveries': '2.8k', 'status': 'Renewal Due', 'color': Colors.orange},
      {'name': 'Keeta', 'deliveries': '1.5k', 'status': 'Contract Active', 'color': Colors.blue},
      {'name': 'HungerStation', 'deliveries': '800', 'status': 'Pending Setup', 'color': Colors.red},
    ];

    return DashboardScaffold(
      title: 'PARTNER PORTALS',
      subtitle: 'Manage client relationships and performance',
      showBackButton: true,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2,
          ),
          itemCount: _partners.length,
          itemBuilder: (context, index) {
            final p = _partners[index];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: p['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(p['name'][0], style: TextStyle(color: p['color'], fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${p['deliveries']} deliveries this month', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(p['status'], style: TextStyle(color: p['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.divider),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
