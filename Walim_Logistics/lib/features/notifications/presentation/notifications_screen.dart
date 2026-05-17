import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'notifications_notifier.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final profile = ref.watch(authProvider).profile;

    return DashboardScaffold(
      title: 'NOTIFICATIONS',
      subtitle: 'Your alerts and updates',
      showBackButton: true,
      actions: [
        TextButton(
          onPressed: profile == null
              ? null
              : () => ref
                  .read(notificationsRepositoryProvider)
                  .markAllAsRead(profile.id),
          child: Text(
            'Mark all read',
            style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ),
      ],
      children: [
        notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text("You're all caught up!",
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: notifications
                  .map((n) => _NotificationTile(notification: n))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const _NotificationTile({required this.notification});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'shift_alert':
        return Icons.schedule_rounded;
      case 'check_in_reminder':
        return Icons.location_on_rounded;
      case 'office_call':
        return Icons.business_center_rounded;
      case 'asset_handover':
        return Icons.swap_horiz_rounded;
      case 'request_update':
        return Icons.assignment_rounded;
      case 'incident_update':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'shift_alert':
        return Colors.blue;
      case 'check_in_reminder':
        return Colors.green;
      case 'office_call':
        return Colors.orange;
      case 'asset_handover':
        return Colors.purple;
      case 'request_update':
        return Colors.teal;
      case 'incident_update':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] as String?;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    final id = notification['id'] as String;
    final color = _colorForType(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          ref.read(notificationsRepositoryProvider).markAsRead(id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Theme.of(context).cardColor
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Theme.of(context).dividerColor.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(type), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body,
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    createdAt != null
                        ? DateFormat('MMM d, h:mm a')
                            .format(DateTime.parse(createdAt).toLocal())
                        : '',
                    style: GoogleFonts.outfit(
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
