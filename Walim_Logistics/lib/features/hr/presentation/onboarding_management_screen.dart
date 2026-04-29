import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class OnboardingManagementScreen extends StatelessWidget {
  const OnboardingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'ONBOARDING & OFFBOARDING',
      subtitle: 'Digital contracts, training progress, and staff transitions',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        _buildPhaseTabs(context),
      ],
    );
  }

  Widget _buildPhaseTabs(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Active Onboarding'),
                Tab(text: 'Offboarding Process'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildOnboardingList(),
                _buildOffboardingList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingList() {
    final List<Map<String, dynamic>> onboardingStaff = [
      {
        'name': 'James Wilson',
        'role': 'Delivery Rider',
        'contract': 'Signed',
        'training': 0.8,
        'assets': 'Pending',
        'startDate': '2024-05-01',
      },
      {
        'name': 'Arun Varma',
        'role': 'Warehouse Assistant',
        'contract': 'Pending',
        'training': 0.3,
        'assets': 'Assigned',
        'startDate': '2024-05-05',
      },
      {
        'name': 'Faisal Ahmed',
        'role': 'Fleet Supervisor',
        'contract': 'Signed',
        'training': 1.0,
        'assets': 'Assigned',
        'startDate': '2024-04-25',
      },
    ];

    return ListView.builder(
      itemCount: onboardingStaff.length,
      itemBuilder: (context, index) {
        final staff = onboardingStaff[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(staff['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff['name'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(staff['role'], style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _buildStatusChip('Start Date: ${staff['startDate']}', Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildTaskStatus('Contract', staff['contract'] == 'Signed'),
                  const SizedBox(width: 24),
                  _buildTaskStatus('Assets', staff['assets'] == 'Assigned'),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Training Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${(staff['training'] * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: staff['training'],
                          backgroundColor: AppColors.background,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOffboardingList() {
    return const Center(child: Text('No active offboarding requests'));
  }

  Widget _buildTaskStatus(String label, bool isComplete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(isComplete ? Icons.check_circle_rounded : Icons.pending_rounded, 
                 color: isComplete ? Colors.green : Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(isComplete ? 'Complete' : 'Pending', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: isComplete ? Colors.green : Colors.orange, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
