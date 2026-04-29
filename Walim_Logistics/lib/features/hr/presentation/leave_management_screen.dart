import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class LeaveManagementScreen extends StatelessWidget {
  const LeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'LEAVE MANAGEMENT',
      subtitle: 'Review and approve staff leave requests',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        _buildRequestStats(),
        const SizedBox(height: 32),
        _buildRequestList(),
      ],
    );
  }

  Widget _buildRequestStats() {
    return Row(
      children: [
        _buildStatCard('Pending', '8', Icons.pending_actions_rounded, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('Approved', '24', Icons.check_circle_outline_rounded, Colors.green),
        const SizedBox(width: 16),
        _buildStatCard('On Leave', '5', Icons.flight_takeoff_rounded, AppColors.primary),
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

  Widget _buildRequestList() {
    final List<Map<String, dynamic>> requests = [
      {
        'name': 'Ahmed Ali',
        'type': 'Annual Leave',
        'dates': 'May 10 - May 24',
        'reason': 'Visiting family in Egypt',
        'status': 'Pending'
      },
      {
        'name': 'Mohammed Khan',
        'type': 'Sick Leave',
        'dates': 'Apr 26 - Apr 28',
        'reason': 'Medical emergency',
        'status': 'Approved'
      },
      {
        'name': 'Rajesh Kumar',
        'type': 'Emergency Leave',
        'dates': 'May 02 - May 05',
        'reason': 'Urgent personal matter',
        'status': 'Pending'
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isPending = req['status'] == 'Pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
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
                      Text(req['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(req['type'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  _buildStatusChip(req['status']),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(req['dates'], style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Reason: ${req['reason']}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
              if (isPending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
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
                        onPressed: () {},
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
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Approved' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
