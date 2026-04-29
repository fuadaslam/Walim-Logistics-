import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class RBACManagementScreen extends StatelessWidget {
  const RBACManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'ACCESS CONTROL (RBAC)',
      subtitle: 'Manage user permissions and role assignments',
      showBackButton: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          itemBuilder: (context, index) {
            final roles = ['Admin', 'Rider', 'Leader', 'Supervisor', 'Ops Manager', 'HR', 'Finance', 'Biz Dev', 'IT Dev'];
            final role = roles[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(_getRoleIcon(role), color: AppColors.primary, size: 20),
                ),
                title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('View-only, Edit, or Master access'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPermissionSwitch('Can view financial data', role == 'Finance' || role == 'Admin'),
                        _buildPermissionSwitch('Can assign shifts', role == 'Leader' || role == 'Admin'),
                        _buildPermissionSwitch('Can approve leaves', role == 'HR' || role == 'Admin'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () {}, child: const Text('Edit Permissions')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPermissionSwitch(String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(value: value, onChanged: (v) {}, activeColor: AppColors.primary),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin': return Icons.security;
      case 'Rider': return Icons.motorcycle;
      case 'Leader': return Icons.leaderboard;
      case 'Finance': return Icons.payments;
      default: return Icons.person;
    }
  }
}
