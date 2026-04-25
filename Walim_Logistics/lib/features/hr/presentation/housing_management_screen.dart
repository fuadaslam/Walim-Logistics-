import 'package:flutter/material.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

class HousingManagementScreen extends StatelessWidget {
  const HousingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Housing Management')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHousingCard('Riyadh North Sakan', '124 Riders', '85% Full'),
          const SizedBox(height: 16),
          _buildHousingCard('Jeddah Port Sakan', '92 Riders', '60% Full'),
          const SizedBox(height: 16),
          _buildHousingCard('Taif Hub Sakan', '45 Riders', '40% Full'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHousingCard(String name, String occupancy, String capacity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(occupancy, style: const TextStyle(color: AppColors.textSecondary)),
              Text(capacity, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.85, // Example
            backgroundColor: AppColors.divider,
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Manage Assignments'),
          ),
        ],
      ),
    );
  }
}
