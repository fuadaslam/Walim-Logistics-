import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class ShiftAssignmentScreen extends ConsumerStatefulWidget {
  const ShiftAssignmentScreen({super.key});

  @override
  ConsumerState<ShiftAssignmentScreen> createState() => _ShiftAssignmentScreenState();
}

class _ShiftAssignmentScreenState extends ConsumerState<ShiftAssignmentScreen> {
  final List<String> _clusters = ['Riyadh Central', 'Riyadh North', 'Riyadh South', 'Riyadh West', 'Riyadh East'];
  
  final List<Map<String, dynamic>> _riders = [
    {'name': 'Ahmed Ali', 'status': 'Available', 'cluster': 'None'},
    {'name': 'Mohammed Khan', 'status': 'On Duty', 'cluster': 'Riyadh North'},
    {'name': 'Saeed Ahmed', 'status': 'Available', 'cluster': 'None'},
    {'name': 'Omar Farooq', 'status': 'On Duty', 'cluster': 'Riyadh South'},
    {'name': 'Khalid Mansour', 'status': 'Break', 'cluster': 'Riyadh Central'},
  ];

  void _assignCluster(int index, String? cluster) {
    setState(() {
      _riders[index]['cluster'] = cluster ?? 'None';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'SHIFT ASSIGNMENT',
      subtitle: 'Assign riders to operational clusters',
      showBackButton: true,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _riders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rider = _riders[index];
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
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(rider['name'][0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(rider['status'], style: TextStyle(color: _getStatusColor(rider['status']), fontSize: 13)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: rider['cluster'] == 'None' ? null : rider['cluster'],
                    hint: const Text('Select Cluster'),
                    underline: const SizedBox(),
                    items: _clusters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => _assignCluster(index, val),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assignments saved successfully!')),
            );
            Navigator.pop(context);
          },
          child: const Text('Save Assignments'),
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
