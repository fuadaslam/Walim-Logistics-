import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';


final _allRidersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(operationsRepositoryProvider).fetchRiders();
});

final _allGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(operationsRepositoryProvider).fetchGroups();
});

class ShiftAssignmentScreen extends ConsumerStatefulWidget {
  const ShiftAssignmentScreen({super.key});

  @override
  ConsumerState<ShiftAssignmentScreen> createState() => _ShiftAssignmentScreenState();
}

class _ShiftAssignmentScreenState extends ConsumerState<ShiftAssignmentScreen> {
  final Map<String, String?> _localAssignments = {};

  void _assignCluster(String riderId, String? cluster) {
    setState(() {
      _localAssignments[riderId] = cluster;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(_allRidersProvider);
    final groupsAsync = ref.watch(_allGroupsProvider);

    return DashboardScaffold(
      title: 'SHIFT ASSIGNMENT',
      subtitle: 'Assign riders to operational clusters',
      showBackButton: true,
      children: [
        ridersAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          )),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (riders) => groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (groups) {
              final clusterNames = groups.map((g) => g['name'] as String).toList();
              
              if (riders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No riders found.'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: riders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rider = riders[index];
                  final riderId = rider['id'] as String;
                  final name = rider['full_name'] as String? ?? 'Unknown';
                  final status = rider['status'] as String? ?? 'Unknown';
                  final currentCluster = _localAssignments[riderId];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', 
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownButton<String>(
                          value: currentCluster,
                          hint: const Text('Select Cluster'),
                          underline: const SizedBox(),
                          items: clusterNames.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => _assignCluster(riderId, val),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignments saved successfully!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Assignments'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On Duty': return Colors.green;
      case 'Available': return Colors.blue;
      case 'Break': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
