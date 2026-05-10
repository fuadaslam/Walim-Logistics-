import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

class GovernmentIntegrationScreen extends StatelessWidget {
  const GovernmentIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'GOVERNMENT INTEGRATION',
      subtitle: 'Tracking Qiwa, Absher, Iqama, and Health Insurance',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 32),
        _buildComplianceTable(context),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final color = Colors.grey.shade500;
    return Row(
      children: [
        _buildStatCard('Expiring Soon', '12', Icons.warning_amber_rounded, color),
        const SizedBox(width: 16),
        _buildStatCard('Expired', '3', Icons.error_outline_rounded, color),
        const SizedBox(width: 16),
        _buildStatCard('Renewed (30d)', '45', Icons.check_circle_outline_rounded, color),
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

  Widget _buildComplianceTable(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {
        'name': 'Ahmed Ali',
        'iqama': '241029XXXX',
        'iqamaExpiry': '2024-05-20',
        'balady': 'Valid',
        'insurance': 'Class A - Bupa',
        'status': 'Expiring Soon'
      },
      {
        'name': 'Mohammed Khan',
        'iqama': '238821XXXX',
        'iqamaExpiry': '2024-08-12',
        'balady': 'Expired',
        'insurance': 'Class B - Tawuniya',
        'status': 'Action Required'
      },
      {
        'name': 'Rajesh Kumar',
        'iqama': '245512XXXX',
        'iqamaExpiry': '2025-01-05',
        'balady': 'Valid',
        'insurance': 'Class A - Bupa',
        'status': 'Compliant'
      },
      {
        'name': 'Saeed Mansour',
        'iqama': '249910XXXX',
        'iqamaExpiry': '2024-04-15',
        'balady': 'Valid',
        'insurance': 'Class B - Tawuniya',
        'status': 'Expired'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Staff Compliance Status', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Report'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          DataTable(
            headingTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            dataRowMaxHeight: 70,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Staff Name')),
              DataColumn(label: Text('Iqama Number')),
              DataColumn(label: Text('Iqama Expiry')),
              DataColumn(label: Text('Balady Card')),
              DataColumn(label: Text('Insurance')),
              DataColumn(label: Text('Status')),
            ],
            rows: data.map((item) {
              final statusColor = _getStatusColor(item['status']);
              return DataRow(
                onSelectChanged: (_) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDetailScreen()));
                },
                cells: [
                DataCell(Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(item['iqama'])),
                DataCell(Text(item['iqamaExpiry'])),
                DataCell(_buildStatusTag(item['balady'], Colors.grey.shade500)),
                DataCell(Text(item['insurance'])),
                DataCell(_buildStatusTag(item['status'], statusColor)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return Colors.grey.shade500;
  }
}
