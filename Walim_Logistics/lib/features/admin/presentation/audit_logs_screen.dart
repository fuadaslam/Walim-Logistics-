import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _logs = [
      {'user': 'Admin_Fuad', 'action': 'Updated RBAC for Leader', 'time': 'Just now', 'type': 'Security'},
      {'user': 'Finance_Sara', 'action': 'Approved Payroll Batch #42', 'time': '10 mins ago', 'type': 'Finance'},
      {'user': 'HR_Ahmed', 'action': 'Changed Sakan assignment VH-001', 'time': '1 hour ago', 'type': 'Ops'},
      {'user': 'Leader_Kahn', 'action': 'Assigned Shift Riyadh North', 'time': '2 hours ago', 'type': 'Fleet'},
    ];

    return DashboardScaffold(
      title: 'AUDIT LOGS',
      subtitle: 'Track every action taken across the system',
      showBackButton: true,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final log = _logs[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Icon(_getLogIcon(log['type']), size: 18, color: AppColors.textSecondary),
                ),
                title: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('By ${log['user']} • ${log['type']}', style: const TextStyle(fontSize: 12)),
                trailing: Text(log['time'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'Security': return Icons.lock_outline;
      case 'Finance': return Icons.attach_money;
      case 'Ops': return Icons.settings_outlined;
      default: return Icons.history;
    }
  }
}
