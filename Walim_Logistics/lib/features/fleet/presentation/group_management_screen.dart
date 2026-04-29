import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class GroupManagementScreen extends StatelessWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _teamMembers = [
      {'name': 'Ahmed Ali', 'role': 'Senior Rider', 'joined': 'Jan 2024', 'rating': 4.8},
      {'name': 'Mohammed Khan', 'role': 'Rider', 'joined': 'Feb 2024', 'rating': 4.5},
      {'name': 'Saeed Ahmed', 'role': 'Rider', 'joined': 'Mar 2024', 'rating': 4.9},
      {'name': 'Omar Farooq', 'role': 'Rider', 'joined': 'Jan 2024', 'rating': 4.2},
      {'name': 'Khalid Mansour', 'role': 'Trainee', 'joined': 'Apr 2024', 'rating': 0.0},
    ];

    return DashboardScaffold(
      title: 'GROUP MANAGEMENT',
      subtitle: 'Oversee and support your team of 12 riders',
      showBackButton: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _teamMembers.length,
          itemBuilder: (context, index) {
            final member = _teamMembers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.accent),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(member['role'], style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(member['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text('Joined ${member['joined']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.phone_outlined, 'Call', () {}),
                        _buildActionButton(Icons.chat_bubble_outline, 'Message', () {}),
                        _buildActionButton(Icons.assignment_ind_outlined, 'Assign Task', () {}),
                        _buildActionButton(Icons.info_outline, 'Details', () {}),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
