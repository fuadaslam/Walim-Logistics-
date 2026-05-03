import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supervisor_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

class RiderAttendanceItem {
  final String? riderId;
  final String riderName;
  final String? riderIqama;
  final String attendanceStatus;
  final String? absenceReason;
  final bool isCarryOver;
  final bool isManualAddition;
  final String? manualAdditionReason;

  const RiderAttendanceItem({
    this.riderId,
    required this.riderName,
    this.riderIqama,
    this.attendanceStatus = 'present',
    this.absenceReason,
    this.isCarryOver = false,
    this.isManualAddition = false,
    this.manualAdditionReason,
  });

  RiderAttendanceItem copyWith({
    String? riderId,
    String? riderName,
    String? riderIqama,
    String? attendanceStatus,
    String? absenceReason,
    bool clearAbsenceReason = false,
    bool? isCarryOver,
    bool? isManualAddition,
    String? manualAdditionReason,
  }) {
    return RiderAttendanceItem(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderIqama: riderIqama ?? this.riderIqama,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      absenceReason:
          clearAbsenceReason ? null : (absenceReason ?? this.absenceReason),
      isCarryOver: isCarryOver ?? this.isCarryOver,
      isManualAddition: isManualAddition ?? this.isManualAddition,
      manualAdditionReason: manualAdditionReason ?? this.manualAdditionReason,
    );
  }

  Map<String, dynamic> toMap() => {
        'rider_id': riderId,
        'rider_name': riderName,
        'rider_iqama': riderIqama,
        'attendance_status': attendanceStatus,
        'absence_reason': absenceReason,
        'is_carry_over': isCarryOver,
        'is_manual_addition': isManualAddition,
        'manual_addition_reason': manualAdditionReason,
      };
}

class ShiftControlState {
  final Map<String, dynamic>? report;
  final List<RiderAttendanceItem> attendanceItems;
  final List<Map<String, dynamic>> validationFlags;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> platforms;
  final String? selectedPlatformId;
  final String? selectedGroupId;
  final DateTime selectedDate;
  final bool loading;
  final String? error;
  final bool nextSupervisorSosSubmitted;

  const ShiftControlState({
    this.report,
    this.attendanceItems = const [],
    this.validationFlags = const [],
    this.groups = const [],
    this.platforms = const [],
    this.selectedPlatformId,
    this.selectedGroupId,
    required this.selectedDate,
    this.loading = false,
    this.error,
    this.nextSupervisorSosSubmitted = false,
  });

  String get reportStatus => report?['status'] as String? ?? 'DRAFT';

  bool get canLoadReport =>
      selectedPlatformId != null && selectedGroupId != null;

  ShiftControlState copyWith({
    Map<String, dynamic>? report,
    bool clearReport = false,
    List<RiderAttendanceItem>? attendanceItems,
    List<Map<String, dynamic>>? validationFlags,
    List<Map<String, dynamic>>? groups,
    List<Map<String, dynamic>>? platforms,
    String? selectedPlatformId,
    String? selectedGroupId,
    DateTime? selectedDate,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? nextSupervisorSosSubmitted,
  }) {
    return ShiftControlState(
      report: clearReport ? null : (report ?? this.report),
      attendanceItems: attendanceItems ?? this.attendanceItems,
      validationFlags: validationFlags ?? this.validationFlags,
      groups: groups ?? this.groups,
      platforms: platforms ?? this.platforms,
      selectedPlatformId: selectedPlatformId ?? this.selectedPlatformId,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedDate: selectedDate ?? this.selectedDate,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      nextSupervisorSosSubmitted:
          nextSupervisorSosSubmitted ?? this.nextSupervisorSosSubmitted,
    );
  }
}

class ShiftControlNotifier extends StateNotifier<ShiftControlState> {
  final SupervisorRepository _repo;
  final String supervisorId;
  final String userRole;

  ShiftControlNotifier(this._repo, this.supervisorId, {required this.userRole})
      : super(ShiftControlState(selectedDate: DateTime.now())) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(loading: true);
    try {
      // If user is a supervisor, only fetch groups they are assigned to.
      // If admin/manager, fetch all.
      final filterId = (userRole == 'Supervisor') ? supervisorId : null;

      final results = await Future.wait([
        _repo.fetchGroups(supervisorId: filterId),
        _repo.fetchPlatforms(),
      ]);

      final groups = results[0];
      final platforms = results[1];

      String? selectedPlatformId;
      String? selectedGroupId;

      // Auto-select if only one option exists
      if (platforms.length == 1) {
        selectedPlatformId = platforms[0]['id'] as String;
      }

      if (groups.length == 1) {
        selectedGroupId = groups[0]['id'] as String;
        selectedPlatformId ??= groups[0]['platform_id'] as String?;
      }

      state = state.copyWith(
        groups: groups,
        platforms: platforms,
        selectedPlatformId: selectedPlatformId,
        selectedGroupId: selectedGroupId,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      clearReport: true,
      attendanceItems: [],
      validationFlags: [],
      clearError: true,
    );
  }

  void selectPlatform(String? platformId) {
    // If the currently selected group doesn't belong to the new platform, clear it
    String? newGroupId = state.selectedGroupId;
    if (platformId != null && newGroupId != null) {
      final group = state.groups.firstWhere(
        (g) => g['id'] == newGroupId,
        orElse: () => <String, dynamic>{},
      );
      if (group.isNotEmpty && group['platform_id'] != platformId) {
        newGroupId = null;
      }
    }

    state = state.copyWith(
      selectedPlatformId: platformId,
      selectedGroupId: newGroupId,
      clearReport: true,
      attendanceItems: [],
      validationFlags: [],
      clearError: true,
    );
  }

  void selectGroup(String? groupId) {
    String? newPlatformId = state.selectedPlatformId;

    if (groupId != null) {
      final group = state.groups.firstWhere(
        (g) => g['id'] == groupId,
        orElse: () => <String, dynamic>{},
      );
      if (group.isNotEmpty && group['platform_id'] != null) {
        newPlatformId = group['platform_id'] as String;
      }
    }

    state = state.copyWith(
      selectedGroupId: groupId,
      selectedPlatformId: newPlatformId,
      clearReport: true,
      attendanceItems: [],
      validationFlags: [],
      clearError: true,
    );
  }

  Future<void> loadReport() async {
    if (!state.canLoadReport) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      var report = await _repo.fetchReport(
        supervisorId: supervisorId,
        date: state.selectedDate,
        platformId: state.selectedPlatformId!,
        groupId: state.selectedGroupId!,
      );

      report ??= await _repo.createReport(
        supervisorId: supervisorId,
        date: state.selectedDate,
        platformId: state.selectedPlatformId!,
        groupId: state.selectedGroupId!,
      );

      final items = await _buildAttendanceItems(report);
      final flags = await _loadFlags(report);

      state = state.copyWith(
        report: report,
        attendanceItems: items,
        validationFlags: flags,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<List<RiderAttendanceItem>> _buildAttendanceItems(
      Map<String, dynamic> report) async {
    if (report['status'] == 'DRAFT') {
      final planned = await _repo.fetchPlannedRiders(
        date: state.selectedDate,
        platformId: state.selectedPlatformId!,
        groupId: state.selectedGroupId!,
      );
      return planned.map((p) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        return RiderAttendanceItem(
          riderId: profile?['id'] ?? p['rider_id'],
          riderName: profile?['full_name'] as String? ?? 'Unknown',
          riderIqama: profile?['iqama_number'] as String?,
          attendanceStatus: 'present',
        );
      }).toList();
    }

    final existing = await _repo.fetchReportItems(report['id'] as String);
    return existing.map((item) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      return RiderAttendanceItem(
        riderId: item['rider_id'] as String?,
        riderName: profile?['full_name'] as String? ??
            item['rider_name'] as String? ??
            'Unknown',
        riderIqama: item['rider_iqama'] as String?,
        attendanceStatus: item['attendance_status'] as String? ?? 'present',
        absenceReason: item['absence_reason'] as String?,
        isCarryOver: item['is_carry_over'] as bool? ?? false,
        isManualAddition: item['is_manual_addition'] as bool? ?? false,
        manualAdditionReason: item['manual_addition_reason'] as String?,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadFlags(
      Map<String, dynamic> report) async {
    if (report['status'] == 'NEEDS_CORRECTION') {
      return _repo.fetchValidationFlags(report['id'] as String);
    }
    return [];
  }

  void updateAttendanceStatus(int index, String status) {
    final items = [...state.attendanceItems];
    items[index] = items[index].copyWith(
      attendanceStatus: status,
      clearAbsenceReason: status != 'absent',
    );
    state = state.copyWith(attendanceItems: items);
  }

  void updateAbsenceReason(int index, String reason) {
    final items = [...state.attendanceItems];
    items[index] = items[index].copyWith(absenceReason: reason);
    state = state.copyWith(attendanceItems: items);
  }

  void addManualRider({
    required String name,
    required String iqama,
    required String reason,
    String? riderId,
  }) {
    final items = [
      ...state.attendanceItems,
      RiderAttendanceItem(
        riderId: riderId,
        riderName: name,
        riderIqama: iqama,
        attendanceStatus: 'present',
        isManualAddition: true,
        manualAdditionReason: reason,
      ),
    ];
    state = state.copyWith(attendanceItems: items);
  }

  /// Returns an error string or null on success.
  Future<String?> submitSOS() async {
    for (final item in state.attendanceItems) {
      if (item.attendanceStatus == 'absent' &&
          (item.absenceReason == null || item.absenceReason!.trim().isEmpty)) {
        return 'Add an absence reason for every absent rider before submitting.';
      }
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.submitSOS(
        reportId: state.report!['id'] as String,
        items: state.attendanceItems.map((i) => i.toMap()).toList(),
        markedBy: supervisorId,
      );
      await loadReport();
      return null;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<void> checkNextSupervisorSOS() async {
    if (state.report == null) return;
    final ok = await _repo.checkNextSupervisorSOS(
      currentReportId: state.report!['id'] as String,
      groupId: state.selectedGroupId!,
      platformId: state.selectedPlatformId!,
    );
    state = state.copyWith(nextSupervisorSosSubmitted: ok);
  }

  Future<void> submitEOS() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.submitEOS(state.report!['id'] as String);
      await loadReport();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> uploadPlatformReport({
    required String fileName,
    required String fileType,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.uploadPlatformReport(
        reportId: state.report!['id'] as String,
        supervisorId: supervisorId,
        platformId: state.selectedPlatformId!,
        uploadDate: state.selectedDate,
        fileUrl: 'uploads/${state.selectedDate.toIso8601String()}/$fileName',
        fileName: fileName,
        fileType: fileType,
      );
      await loadReport();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> runValidation() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final flags =
          await _repo.runValidation(state.report!['id'] as String);
      await loadReport();
      state = state.copyWith(validationFlags: flags, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> saveCorrectionNotes(String notes) async {
    if (state.report == null) return;
    await _repo.updateReportCorrectionNotes(
        state.report!['id'] as String, notes);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final supervisorRepositoryProvider = Provider<SupervisorRepository>(
  (ref) => SupervisorRepository(Supabase.instance.client),
);

final shiftControlProvider = StateNotifierProvider.autoDispose<
    ShiftControlNotifier, ShiftControlState>(
  (ref) {
    final repo = ref.watch(supervisorRepositoryProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.user?.id ?? '';
    final role = auth.profile?.role ?? 'Rider';
    return ShiftControlNotifier(repo, uid, userRole: role);
  },
);
