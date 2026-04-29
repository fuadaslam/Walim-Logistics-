import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/hr/presentation/housing_management_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/government_integration_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/onboarding_management_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/leave_management_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/asset_management_screen.dart';

class HRDashboard extends ConsumerWidget {
  final bool showScaffold;
  const HRDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'HR Management',
      subtitle: 'Manage staff, government regulations, housing, and assets',
      activeItem: 'HR',
      children: [
        _buildContent(context, ref),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HR Stats Section
        _buildSectionHeader('Workforce Overview'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: [
            DashboardStatCard(
              label: 'Total Staff',
              value: '156',
              icon: Icons.people_outline,
              color: Colors.teal,
              trend: '+4 this month',
              sparklineData: [140, 142, 145, 148, 150, 152, 156],
            ),
            DashboardStatCard(
              label: 'Compliance Alerts',
              value: '12',
              icon: Icons.badge_outlined,
              color: AppColors.error,
              trend: 'Action Required',
              isPositive: false,
              sparklineData: [5, 8, 4, 10, 7, 11, 12],
            ),
            DashboardStatCard(
              label: 'Pending Leaves',
              value: '8',
              icon: Icons.time_to_leave_outlined,
              color: Colors.blue,
              trend: 'Awaiting review',
            ),
            DashboardStatCard(
              label: 'Housing Capacity',
              value: '84%',
              icon: Icons.apartment_rounded,
              color: Colors.indigo,
              trend: '32 beds available',
            ),
          ],
        ),

        const SizedBox(height: 48),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Management Modules
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Management Modules'),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: constraints.maxWidth > 800 ? 2 : 1,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 2.2,
                        children: [
                          DashboardActionCard(
                            title: 'Government Integration',
                            subtitle: 'Qiwa, Absher, Iqama, and Insurance',
                            icon: Icons.g_translate_outlined,
                            color: Colors.green,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GovernmentIntegrationScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Leave & Requests',
                            subtitle: 'Manage leave and staff schedules',
                            icon: Icons.calendar_month_outlined,
                            color: Colors.orange,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveManagementScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Onboarding Portal',
                            subtitle: 'Digital contracts and training progress',
                            icon: Icons.person_add_alt_1_outlined,
                            color: Colors.blue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingManagementScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Housing (Mawaqi)',
                            subtitle: 'Managing laborer accommodation assignments',
                            icon: Icons.apartment_outlined,
                            color: Colors.indigo,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HousingManagementScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Asset Accountability',
                            subtitle: 'Company assets assigned to staff',
                            icon: Icons.assignment_turned_in_outlined,
                            color: Colors.purple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetManagementScreen())),
                          ),
                          DashboardActionCard(
                            title: 'Staff Document Vault',
                            subtitle: 'Central repository for staff records',
                            icon: Icons.folder_shared_outlined,
                            color: Colors.teal,
                            onTap: () {},
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Side: Compliance & Activity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Compliance Watch'),
                  const SizedBox(height: 24),
                  _buildComplianceWatch(),
                  const SizedBox(height: 48),
                  _buildSectionHeader('Recent Activity'),
                  const SizedBox(height: 24),
                  _buildActivityFeed(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceWatch() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildComplianceItem('Iqama Expiry', '4 staff members', 'Expiring in 7 days', Colors.red),
          const Divider(height: 32),
          _buildComplianceItem('Health Insurance', '12 staff members', 'Renewal due', Colors.orange),
          const Divider(height: 32),
          _buildComplianceItem('Balady Card', '2 staff members', 'Expired', Colors.red),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String title, String count, String status, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(count, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildActivityItem('Ahmed Ali', 'Requested Annual Leave', '10 mins ago', Icons.calendar_today, Colors.orange),
          const Divider(height: 32),
          _buildActivityItem('James Wilson', 'Completed Safety Training', '2 hours ago', Icons.school, Colors.blue),
          const Divider(height: 32),
          _buildActivityItem('New Asset', 'Vehicle #9021 assigned to M. Khan', 'Yesterday', Icons.motorcycle, Colors.green),
        ],
      ),
    );
  }



  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
