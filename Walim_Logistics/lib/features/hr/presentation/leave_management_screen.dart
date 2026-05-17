import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends ConsumerWidget {
  const LeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(hrAllLeaveRequestsProvider);
    final stats = ref.watch(hrStatsProvider);

    return DashboardScaffold(
      title: 'LEAVE MANAGEMENT',
      subtitle: 'Review and approve staff leave requests',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        // Stats row
        Row(
          children: [
            _buildStatCard(
              stats.isLoading ? '—' : stats.pendingLeaves.toString(),
              'Pending',
              Icons.pending_actions_rounded,
              Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '—',
              'Approved',
              Icons.check_circle_outline_rounded,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '—',
              'On Leave',
              Icons.flight_takeoff_rounded,
              AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Request list
        requestsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyStatePlaceholder(
            icon: Icons.error_outline_rounded,
            title: 'Requests Unavailable',
            subtitle: 'We couldn\'t load the leave requests. Error: $e',
            color: AppColors.error,
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.event_available_rounded,
                title: 'No Leave Requests',
                subtitle: 'There are no pending or history requests to display.',
                color: Colors.green,
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final isPending = req['status'] == 'Pending';
                final name = req['profiles']?['full_name'] as String? ?? 'Unknown';
                final startDate = req['start_date'] != null
                    ? DateFormat('MMM d').format(DateTime.parse(req['start_date']))
                    : '—';
                final endDate = req['end_date'] != null
                    ? DateFormat('MMM d').format(DateTime.parse(req['end_date']))
                    : '—';

                return InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RiderDetailScreen())),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(req['type'] as String? ?? 'Leave',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                            _buildStatusChip(req['status'] as String? ?? 'Pending'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('$startDate - $endDate',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        if (req['reason'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Reason: ${req['reason']}',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final hrRepo = ref.read(hrRepositoryProvider);
                                    await hrRepo.reviewLeaveRequest(
                                      requestId: req['id'],
                                      status: 'Approved',
                                      reviewedBy: '',
                                    );
                                    ref.invalidate(hrAllLeaveRequestsProvider);
                                    ref.read(hrStatsProvider.notifier).loadStats();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final hrRepo = ref.read(hrRepositoryProvider);
                                    await hrRepo.reviewLeaveRequest(
                                      requestId: req['id'],
                                      status: 'Rejected',
                                      reviewedBy: '',
                                    );
                                    ref.invalidate(hrAllLeaveRequestsProvider);
                                    ref.read(hrStatsProvider.notifier).loadStats();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
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
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Approved'
        ? Colors.green
        : status == 'Rejected'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
