import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walim_logistics/core/services/location_service.dart';
import '../data/attendance_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final attendanceRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AttendanceRepository(supabase);
});

class AttendanceState {
  final bool isCheckingIn;
  final bool hasActiveShift;
  final String? error;
  final int? _todayCheckIns;

  int get todayCheckIns => _todayCheckIns ?? 0;

  AttendanceState({
    this.isCheckingIn = false,
    this.hasActiveShift = false,
    this.error,
    int? todayCheckIns = 0,
  }) : _todayCheckIns = todayCheckIns;

  AttendanceState copyWith({
    bool? isCheckingIn,
    bool? hasActiveShift,
    String? error,
    int? todayCheckIns,
  }) {
    return AttendanceState(
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      hasActiveShift: hasActiveShift ?? this.hasActiveShift,
      error: error,
      todayCheckIns: todayCheckIns ?? _todayCheckIns,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref _ref;

  AttendanceNotifier(this._repository, this._ref) : super(AttendanceState()) {
    _checkActiveShift();
  }

  Future<void> _checkActiveShift() async {
    final profile = _ref.read(authProvider).profile;
    if (profile != null) {
      final activeShift = await _repository.getActiveShift(profile.id);
      final completedPeriods = await _repository.getTodayCheckInPeriods(
        profile.id,
      );

      state = state.copyWith(
        hasActiveShift: activeShift != null,
        todayCheckIns: completedPeriods.length,
      );

      if (activeShift != null) {
        _ref.read(locationServiceProvider).startTracking();
      }
    }
  }


  Future<void> toggleShift({
    required double centerLat,
    required double centerLong,
    required double radiusMeters,
  }) async {
    state = state.copyWith(isCheckingIn: true, error: null);
    try {
      final position = await Geolocator.getCurrentPosition();
      final profile = _ref.read(authProvider).profile;

      if (profile == null) throw Exception('User not authenticated');

      if (state.hasActiveShift) {
        // Check-out
        await _repository.checkOut(
          profileId: profile.id,
          lat: position.latitude,
          long: position.longitude,
        );
        _ref.read(locationServiceProvider).stopTracking();
        state = state.copyWith(hasActiveShift: false, isCheckingIn: false);
      } else {
        // Checking IN
        final currentPeriod = _repository.getShiftPeriod(DateTime.now());
        final completedPeriods = await _repository.getTodayCheckInPeriods(
          profile.id,
        );

        if (completedPeriods.contains(currentPeriod)) {
          state = state.copyWith(
            isCheckingIn: false,
            error:
                'You have already checked in for the $currentPeriod shift. Please wait for the next shift.',
            todayCheckIns: completedPeriods.length,
          );
          return;
        }

        // Check-in with Geofence validation
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          centerLat,
          centerLong,
        );

        final isValid = distance <= radiusMeters;

        await _repository.checkIn(
          profileId: profile.id,
          lat: position.latitude,
          long: position.longitude,
          isValid: isValid,
        );

        // Add current period to count since they just checked in
        final newCount = completedPeriods.length + 1;

        if (!isValid) {
          state = state.copyWith(
            error: 'You are outside the geofenced area!',
            hasActiveShift: true,
            isCheckingIn: false,
            todayCheckIns: newCount,
          );
        } else {
          state = state.copyWith(
            hasActiveShift: true,
            isCheckingIn: false,
            todayCheckIns: newCount,
          );
        }
        _ref.read(locationServiceProvider).startTracking();
      }
    } catch (e) {
      state = state.copyWith(isCheckingIn: false, error: e.toString());
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      final repository = ref.watch(attendanceRepositoryProvider);
      return AttendanceNotifier(repository, ref);
    });
