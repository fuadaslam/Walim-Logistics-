import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';

class OnboardingManagementScreen extends ConsumerWidget {
  const OnboardingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserRole = ref.watch(authProvider).profile?.role;
    
    return DashboardScaffold(
      title: 'ONBOARDING & OFFBOARDING',
      subtitle: 'Digital contracts, training progress, and staff transitions',
      showBackButton: true,
      activeItem: 'HR',
      children: [
        _buildPhaseTabs(context, ref, currentUserRole),
      ],
    );
  }

  Widget _buildPhaseTabs(BuildContext context, WidgetRef ref, String? currentUserRole) {
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
                _buildOnboardingList(context, ref, currentUserRole),
                _buildOffboardingList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingList(BuildContext context, WidgetRef ref, String? currentUserRole) {
    final onboardingAsync = ref.watch(onboardingStaffProvider);

    return onboardingAsync.when(
      data: (onboardingStaff) {
        final filteredStaff = onboardingStaff.where((staff) {
          final role = staff['role'] as String? ?? '';
          
          // Apply role-based visibility restrictions
          if (currentUserRole == 'Supervisor') {
            return role == 'Rider';
          } else if (currentUserRole == 'Operations Manager') {
            return role == 'Rider' || role == 'Supervisor';
          }
          return true;
        }).toList();

        if (filteredStaff.isEmpty) {
          return const EmptyStatePlaceholder(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No Active Onboarding',
            subtitle: 'There are currently no staff members in the onboarding process.',
            color: Colors.blueGrey,
          );
        }

        return ListView.builder(
          itemCount: filteredStaff.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final staff = filteredStaff[index];
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
                  // Pass a partial UserProfile for now or fetch full details
                  final profile = UserProfile(
                    id: staff['id'],
                    role: staff['role'],
                    fullName: staff['name'],
                    status: 'active',
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RiderDetailScreen(profile: profile)));
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
                                staff['name'].isNotEmpty ? staff['name'][0] : 'S',
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
                            child: _buildTaskStatus('Training', (staff['training'] as double) > 0.0),
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyStatePlaceholder(
        icon: Icons.error_outline_rounded,
        title: 'Data Unavailable',
        subtitle: 'Error: $e',
        color: AppColors.error,
      ),
    );
  }
  Widget _buildOffboardingList() {
    return const EmptyStatePlaceholder(
      icon: Icons.history_rounded,
      title: 'No Offboarding Requests',
      subtitle: 'There are no staff members currently in the offboarding process.',
      color: Colors.blueGrey,
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

