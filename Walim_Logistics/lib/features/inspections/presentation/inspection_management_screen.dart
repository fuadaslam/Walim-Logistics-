import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'inspection_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:intl/intl.dart';

class InspectionManagementScreen extends ConsumerWidget {
  final int initialTabIndex;
  const InspectionManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(inspectionStatusProvider);

    return DashboardScaffold(
      title: 'SAFETY COMPLIANCE',
      subtitle: 'Real-time monitoring of daily vehicle & rider inspections',
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(inspectionStatusProvider.future),
        child: statusAsync.when(
          data: (status) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: _buildContent(context, status),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InspectionStatus status) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(status),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: TabBar(
              tabs: [
                Tab(text: 'Completed (${status.completed.length})'),
                Tab(text: 'Pending (${status.pending.length})'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 600, // Fixed height for the list area
            child: TabBarView(
              children: [
                _buildRiderList(status.completed, true),
                _buildRiderList(status.pending, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(InspectionStatus status) {
    final total = status.completed.length + status.pending.length;
    final rate = total == 0 ? 0 : (status.completed.length / total * 100).toInt();

    return Row(
      children: [
        _buildStatCard('Compliance Rate', '$rate%', Icons.verified_user_rounded, Colors.green),
        const SizedBox(width: 20),
        _buildStatCard('Completed', '${status.completed.length}', Icons.check_circle_rounded, Colors.blue),
        const SizedBox(width: 20),
        _buildStatCard('Action Required', '${status.pending.length}', Icons.warning_amber_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderList(List<RiderInspectionState> riders, bool isCompleted) {
    if (riders.isEmpty) {
      return EmptyStatePlaceholder(
        icon: isCompleted ? Icons.task_alt_rounded : Icons.person_off_rounded,
        title: isCompleted ? 'No completed inspections' : 'All clear!',
        subtitle: isCompleted 
            ? 'Waiting for riders to submit their daily safety checks.' 
            : 'Every rider on duty has completed their safety inspection.',
        color: isCompleted ? Colors.blue : Colors.green,
      );
    }

    return ListView.separated(
      itemCount: riders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rider = riders[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                child: Text(
                  rider.riderName[0],
                  style: TextStyle(color: isCompleted ? Colors.green : Colors.orange),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      rider.phone ?? 'No phone',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isCompleted && rider.inspection != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rider.inspection!.isSafeToDrive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rider.inspection!.isSafeToDrive ? 'SAFE' : 'ISSUES',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rider.inspection!.isSafeToDrive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(rider.inspection!.createdAt),
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              if (!isCompleted)
                ElevatedButton.icon(
                  onPressed: () {
                    // Action to remind rider
                  },
                  icon: const Icon(Icons.notifications_active_outlined, size: 16),
                  label: const Text('Remind'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    foregroundColor: Colors.orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  // Navigate to rider detail
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
