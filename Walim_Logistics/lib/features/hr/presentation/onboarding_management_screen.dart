import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 400,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.divider),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Active Onboarding'),
                Tab(text: 'Offboarding Process'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 700,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final staff = onboardingStaff[index];
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDetailScreen()));
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            staff['name'][0],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['name'],
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.work_outline_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  staff['role'],
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip('Start Date: ${staff['startDate']}', Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildTaskStatus('Contract Status', staff['contract'] == 'Signed'),
                      const SizedBox(width: 40),
                      _buildTaskStatus('Asset Allocation', staff['assets'] == 'Assigned'),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Training Progress',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${(staff['training'] * 100).toInt()}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    color: isDarkMode ? Colors.white10 : AppColors.background,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: staff['training'],
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primary, AppColors.primaryLight],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffboardingList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No active offboarding requests',
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatus(String label, bool isComplete) {
    final Color color = isComplete ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                isComplete ? 'Complete' : 'Pending',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
