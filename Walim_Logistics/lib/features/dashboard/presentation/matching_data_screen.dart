import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class MatchingDataScreen extends StatefulWidget {
  const MatchingDataScreen({super.key});

  @override
  State<MatchingDataScreen> createState() => _MatchingDataScreenState();
}

class _MatchingDataScreenState extends State<MatchingDataScreen> {
  String _selectedPlatform = 'Noon';
  final List<String> _platforms = ['Noon', 'Amazon', 'Keeta', 'HungerStation'];

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'DATA RECONCILIATION',
      subtitle: 'Match platform performance with internal records',
      showBackButton: true,
      actions: [
        DropdownButton<String>(
          value: _selectedPlatform,
          items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (val) => setState(() => _selectedPlatform = val!),
        ),
      ],
      children: [
        _buildComparisonTable(),
        const SizedBox(height: 32),
        _buildDiscrepancyCard(),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Rider')),
          DataColumn(label: Text('Platform Deliveries')),
          DataColumn(label: Text('Internal Status')),
          DataColumn(label: Text('Match')),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('Ahmed Ali')),
            const DataCell(Text('24')),
            const DataCell(Text('On Duty')),
            DataCell(Icon(Icons.check_circle, color: Colors.green[400])),
          ]),
          DataRow(cells: [
            const DataCell(Text('Mohammed Khan')),
            const DataCell(Text('0')),
            const DataCell(Text('Sick Leave')),
            DataCell(Icon(Icons.check_circle, color: Colors.green[400])),
          ]),
          DataRow(cells: [
            const DataCell(Text('Saeed Ahmed')),
            const DataCell(Text('12')),
            const DataCell(Text('Weekly Off')),
            const DataCell(Icon(Icons.warning, color: Colors.orange)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem, color: AppColors.error),
              SizedBox(width: 8),
              Text('Action Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Saeed Ahmed shows 12 deliveries on $_selectedPlatform reports, but was marked "Weekly Off" in our HR system. Please verify the shift.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Resolve Discrepancy'),
          ),
        ],
      ),
    );
  }
}
