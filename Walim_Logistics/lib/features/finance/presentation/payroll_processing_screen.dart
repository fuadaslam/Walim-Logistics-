import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class PayrollProcessingScreen extends StatelessWidget {
  const PayrollProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'PAYROLL PROCESSING',
      subtitle: 'Calculate salaries, bonuses, and deductions',
      showBackButton: true,
      children: [
        _buildPayrollHeader(),
        const SizedBox(height: 32),
        Text('Staff List', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildStaffPayrollTable(),
      ],
    );
  }

  Widget _buildPayrollHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF4A4ED7)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Period', style: TextStyle(color: Colors.white70)),
                  Text('April 2024', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Payroll'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.accent),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Total Payout', '﷼ 425.8k'),
              _buildMetric('Staff Count', '156'),
              _buildMetric('Pending', '12'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStaffPayrollTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Staff')),
          DataColumn(label: Text('Base')),
          DataColumn(label: Text('Bonus')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('Ahmed Ali')),
            const DataCell(Text('﷼ 3,500')),
            const DataCell(Text('﷼ 450')),
            const DataCell(Text('﷼ 3,950')),
            DataCell(Icon(Icons.check_circle, color: Colors.green[400])),
          ]),
          DataRow(cells: [
            const DataCell(Text('Mohammed Khan')),
            const DataCell(Text('﷼ 3,200')),
            const DataCell(Text('﷼ 200')),
            const DataCell(Text('﷼ 3,400')),
            const DataCell(Icon(Icons.pending_actions, color: Colors.orange)),
          ]),
        ],
      ),
    );
  }
}
