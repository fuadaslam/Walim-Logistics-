import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(allStaffProvider);

    return DashboardScaffold(
      title: 'GROUP MANAGEMENT',
      subtitle: 'Oversee and support your team',
      showBackButton: true,
      children: [
        staffAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No team members found.'),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final String name = member['full_name'] ?? 'Unknown';
                final String role = member['role'] ?? 'Staff';
                
                String joinedStr = 'N/A';
                if (member['created_at'] != null) {
                  try {
                    final dt = DateTime.parse(member['created_at']);
                    joinedStr = DateFormat('MMM yyyy').format(dt);
                  } catch (_) {}
                }

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
                              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: AppColors.accent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text(role, style: const TextStyle(color: AppColors.textSecondary)),
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
                                    Text(
                                      (member['rating'] ?? '4.5').toString(), 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                                Text('Joined $joinedStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                            _buildActionButton(Icons.info_outline, 'Details', () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => RiderDetailScreen(
                                    profile: UserProfile.fromJson(member)
                                  )
                                )
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Error loading team: $error'),
            ),
          ),
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
