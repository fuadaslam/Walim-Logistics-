import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'SYSTEM HEALTH',
      subtitle: 'API status, database load, and system metrics',
      showBackButton: true,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildHealthMetric('Database', '99.9%', Icons.storage, Colors.green),
            _buildHealthMetric('Supabase Auth', 'Connected', Icons.vpn_key, Colors.green),
            _buildHealthMetric('Noon API', '45ms', Icons.api, Colors.blue),
            _buildHealthMetric('Salla Bridge', 'Active', Icons.sync, Colors.green),
            _buildHealthMetric('Server Load', '12%', Icons.speed, Colors.orange),
            _buildHealthMetric('Error Logs', '0', Icons.bug_report, Colors.green),
          ],
        ),
        const SizedBox(height: 40),
        Text('Active Bridges', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildBridgeStatus('Keeta Delivery Bridge', 'Connected'),
        _buildBridgeStatus('Amazon Flex Integration', 'Active'),
        _buildBridgeStatus('HungerStation Webhook', 'Waiting'),
      ],
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBridgeStatus(String name, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: AppColors.accent),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
