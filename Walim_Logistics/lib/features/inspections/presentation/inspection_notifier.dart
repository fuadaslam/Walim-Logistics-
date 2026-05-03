import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inspection_repository.dart';
import '../domain/inspection.dart';

class InspectionStatus {
  final List<RiderInspectionState> completed;
  final List<RiderInspectionState> pending;

  InspectionStatus({required this.completed, required this.pending});
}

class RiderInspectionState {
  final String riderId;
  final String riderName;
  final String? phone;
  final Inspection? inspection;
  final bool isCompleted;

  RiderInspectionState({
    required this.riderId,
    required this.riderName,
    this.phone,
    this.inspection,
    required this.isCompleted,
  });
}

final inspectionStatusProvider = FutureProvider<InspectionStatus>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  
  final results = await Future.wait([
    repo.getRidersWithShiftToday(),
    repo.getTodayInspections(),
  ]);

  final ridersWithShifts = results[0] as List<Map<String, dynamic>>;
  final todayInspections = results[1] as List<Inspection>;

  final completed = <RiderInspectionState>[];
  final pending = <RiderInspectionState>[];

  final inspectionMap = {
    for (var inspection in todayInspections) inspection.profileId: inspection
  };

  for (var riderData in ridersWithShifts) {
    final riderId = riderData['rider_id'] as String;
    final profile = riderData['profiles'] as Map<String, dynamic>;
    final name = profile['full_name'] as String? ?? 'Unknown';
    final phone = profile['phone_number'] as String?;
    
    final inspection = inspectionMap[riderId];
    
    if (inspection != null) {
      completed.add(RiderInspectionState(
        riderId: riderId,
        riderName: name,
        phone: phone,
        inspection: inspection,
        isCompleted: true,
      ));
    } else {
      pending.add(RiderInspectionState(
        riderId: riderId,
        riderName: name,
        phone: phone,
        isCompleted: false,
      ));
    }
  }

  return InspectionStatus(completed: completed, pending: pending);
});
