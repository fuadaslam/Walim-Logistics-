import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

final riderSearchQueryProvider = StateProvider<String>((ref) => '');
final riderFilterStatusProvider = StateProvider<String?>((ref) => null);

final detailedRidersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operationsRepositoryProvider);
  final hrRepo = ref.watch(hrRepositoryProvider);
  
  // Fetch riders with iqama and other details
  final riders = await repo.fetchRiders();
  
  // For each rider, try to find their active vehicle
  return Future.wait(riders.map((rider) async {
    final assets = await hrRepo.getAssetsForProfile(rider['id']);
    final vehicle = assets.where((a) => a.assetCategory == 'vehicle').firstOrNull;
    
    return {
      ...rider,
      'vehicle': vehicle?.assetName ?? 'No vehicle',
    };
  }));
});

final detailedSupervisorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operationsRepositoryProvider);
  
  // Fetch supervisors
  final supervisors = await repo.fetchSupervisors();
  
  // For each supervisor, find the groups and platforms they manage
  // We can use fetchGroups and filter by supervisor_id
  final allGroups = await repo.fetchGroups();
  
  return supervisors.map((sup) {
    final managedGroups = allGroups.where((g) => g['supervisor_id'] == sup['id']).toList();
    final groupNames = managedGroups.map((g) => g['name']).join(', ');
    final platformNames = managedGroups
        .map((g) => g['platforms']?['name'])
        .where((n) => n != null)
        .toSet()
        .join(', ');
        
    return {
      ...sup,
      'managed_groups': groupNames.isEmpty ? 'None' : groupNames,
      'managed_platforms': platformNames.isEmpty ? 'None' : platformNames,
    };
  }).toList();
});

final detailedPlatformsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operationsRepositoryProvider);
  
  // Fetch platforms
  final platforms = await repo.fetchPlatforms();
  final allGroups = await repo.fetchGroups();
  
  // Fetch today's shift plans to count riders per platform
  final today = DateTime.now();
  final shiftPlans = await repo.fetchShiftPlans(date: today);
  
  // Fetch today's supervisor schedules
  final supervisorSchedules = await repo.fetchSchedules(today);
  
  return platforms.map((plat) {
    final platId = plat['id'];
    
    // Groups in this platform
    final platformGroups = allGroups.where((g) => g['platform_id'] == platId).toList();
    
    // Riders allocated today
    final ridersCount = shiftPlans.where((p) => p['platform_id'] == platId).length;
    
    // Supervisors today
    final supervisors = supervisorSchedules
        .where((s) => s['platform_id'] == platId)
        .map((s) => s['profiles']?['full_name'])
        .where((n) => n != null)
        .toSet()
        .join(', ');

    // Shifts today (unique shift times)
    final shifts = shiftPlans
        .where((p) => p['platform_id'] == platId)
        .map((p) {
          final start = DateTime.parse(p['shift_start']);
          final end = DateTime.parse(p['shift_end']);
          return '${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
        })
        .toSet()
        .join(', ');

    return {
      ...plat,
      'riders_count': ridersCount,
      'supervisors': supervisors.isEmpty ? 'None' : supervisors,
      'shifts': shifts.isEmpty ? 'No active shifts' : shifts,
    };
  }).toList();
});
