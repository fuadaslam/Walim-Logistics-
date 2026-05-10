import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

final riderSearchQueryProvider = StateProvider<String>((ref) => '');
final riderFilterStatusProvider = StateProvider<String?>((ref) => null);

final supervisorSearchQueryProvider = StateProvider<String>((ref) => '');
final platformSearchQueryProvider = StateProvider<String>((ref) => '');

final detailedRidersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operationsRepositoryProvider);
  final hrRepo = ref.watch(hrRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  
  // Fetch riders with iqama and other details
  final riders = await repo.fetchRiders();
  
  // Fetch all vehicles with assignments to build a lookup map
  Map<String, String> assignedVehicleMap = {};
  try {
    final List<dynamic> vehiclesData = await supabase
        .from('vehicles')
        .select('assigned_profile_id, plate_number, type, make, model')
        .not('assigned_profile_id', 'is', null);
        
    for (var v in vehiclesData) {
      final profileId = v['assigned_profile_id'];
      if (profileId != null) {
        final plate = v['plate_number']?.toString() ?? '';
        final make = v['make']?.toString() ?? '';
        final model = v['model']?.toString() ?? '';
        final type = v['type']?.toString() ?? '';
        
        String vehicleName = plate;
        if (vehicleName.isEmpty && make.isNotEmpty) {
          vehicleName = '$make $model';
        }
        if (vehicleName.isEmpty) {
          vehicleName = type.toUpperCase();
        }
        assignedVehicleMap[profileId.toString()] = vehicleName;
      }
    }
  } catch (e) {
    // Fallback if query fails
  }
  
  // For each rider, try to find their active vehicle
  return Future.wait(riders.map((rider) async {
    final riderId = rider['id'];
    final assets = await hrRepo.getAssetsForProfile(riderId);
    final vehicle = assets.where((a) => a.assetCategory == 'vehicle').firstOrNull;
    
    final vehicleName = vehicle?.assetName ?? assignedVehicleMap[riderId] ?? 'No vehicle';
    
    return {
      ...rider,
      'vehicle': vehicleName,
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
