import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class CODReconciliationScreen extends StatefulWidget {
  const CODReconciliationScreen({super.key});

  @override
  State<CODReconciliationScreen> createState() => _CODReconciliationScreenState();
}

class _CODReconciliationScreenState extends State<CODReconciliationScreen> {
  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'COD RECONCILIATION',
      subtitle: 'Audit collected cash vs platform delivery data',
      showBackButton: true,
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 32),
        Text('Pending Reconciliation', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRiderCashList(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat('Total COD', '﷼ 125,400', Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMiniStat('Matched', '﷼ 112,000', Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMiniStat('Gap', '﷼ 13,400', AppColors.error),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildRiderCashList() {
    final List<Map<String, dynamic>> _data = [
      {'rider': 'Ahmed Ali', 'platform': '﷼ 2,400', 'collected': '﷼ 2,400', 'status': 'Matched'},
      {'rider': 'Mohammed Khan', 'platform': '﷼ 1,800', 'collected': '﷼ 1,750', 'status': 'Gap'},
      {'rider': 'Saeed Ahmed', 'platform': '﷼ 3,200', 'collected': '﷼ 3,200', 'status': 'Matched'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final item = _data[index];
        final isGap = item['status'] == 'Gap';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isGap ? AppColors.error.withOpacity(0.3) : AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['rider'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Platform: ${item['platform']} • Collected: ${item['collected']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isGap ? AppColors.error : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(color: isGap ? AppColors.error : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
        );
      },
    );
  }
}
