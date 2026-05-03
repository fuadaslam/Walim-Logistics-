import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'admin_notifier.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return DashboardScaffold(
      title: 'AUDIT LOGS',
      subtitle: 'Track every action taken across the system',
      showBackButton: true,
      children: [
        logsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyStatePlaceholder(
            icon: Icons.error_outline_rounded,
            title: 'Audit Logs Unavailable',
            subtitle: 'We couldn\'t load the system audit logs. Error: $e',
            color: AppColors.error,
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.history_rounded,
                title: 'No Audit Logs',
                subtitle: 'No system actions have been recorded yet.',
                color: Colors.blueGrey,
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final userName = (log['profiles'] as Map?)?['full_name'] ?? 'Unknown';
                  final entityType = log['entity_type'] as String? ?? 'System';
                  final createdAt = log['created_at'] != null
                      ? DateFormat('MMM d, h:mm a')
                          .format(DateTime.parse(log['created_at']).toLocal())
                      : '';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getLogIcon(entityType),
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      log['action'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      'By $userName • $entityType',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      createdAt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'Security':
        return Icons.lock_outline;
      case 'Finance':
        return Icons.attach_money;
      case 'Ops':
        return Icons.settings_outlined;
      case 'HR':
        return Icons.people_outline;
      case 'Fleet':
        return Icons.local_shipping_outlined;
      default:
        return Icons.history;
    }
  }
}
