import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

import '../../dashboard/presentation/widgets/dashboard_scaffold.dart';

class ReconciliationDashboard extends StatelessWidget {
  final bool showScaffold;
  const ReconciliationDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context) {
    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'COD RECONCILIATION',
      subtitle: 'Audit COD collections and platform reports',
      activeItem: 'Finance',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 32),
        const Text(
          'Recent Collections',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildReconciliationTable(context),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Collected', 'SAR 45,200', AppColors.accent)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Pending Match', 'SAR 12,800', AppColors.warning)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Discrepancies', 'SAR -1,450', AppColors.error)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildReconciliationTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: DataTable(
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        columns: const [
          DataColumn(label: Text('Rider')),
          DataColumn(label: Text('Platform')),
          DataColumn(label: Text('Collected')),
          DataColumn(label: Text('Expected')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          _buildDataRow('Ahmed Al-Saud', 'Noon', 1250, 1250, 'Matched'),
          _buildDataRow('Khalid Mansour', 'Keeta', 840, 900, 'Flagged'),
          _buildDataRow('Youssef Ali', 'Amazon', 2100, 2100, 'Matched'),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String rider, String platform, double collected, double expected, String status) {
    final isDiscrepancy = collected != expected;
    return DataRow(cells: [
      DataCell(Text(rider)),
      DataCell(Text(platform)),
      DataCell(Text('SAR $collected')),
      DataCell(Text('SAR $expected', style: TextStyle(color: isDiscrepancy ? AppColors.error : AppColors.accent))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (status == 'Matched' ? AppColors.accent : AppColors.error).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: status == 'Matched' ? AppColors.accent : AppColors.error,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ]);
  }
}
