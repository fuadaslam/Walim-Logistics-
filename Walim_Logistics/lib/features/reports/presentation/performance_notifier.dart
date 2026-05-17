import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/performance_repository.dart';
import '../models/performance_record.dart';
import '../../auth/presentation/auth_notifier.dart';

class PerformanceState {
  final List<PerformanceRecord> records;
  final List<ShiftRecord> shifts;
  final bool loading;
  final bool uploading;
  final String? error;
  final String? selectedPlatformId;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedReportType;

  PerformanceState({
    this.records = const [],
    this.shifts = const [],
    this.loading = false,
    this.uploading = false,
    this.error,
    this.selectedPlatformId,
    DateTime? startDate,
    DateTime? endDate,
    this.selectedReportType,
  })  : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  PerformanceState copyWith({
    List<PerformanceRecord>? records,
    List<ShiftRecord>? shifts,
    bool? loading,
    bool? uploading,
    String? error,
    String? selectedPlatformId,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedReportType,
  }) =>
      PerformanceState(
        records: records ?? this.records,
        shifts: shifts ?? this.shifts,
        loading: loading ?? this.loading,
        uploading: uploading ?? this.uploading,
        error: error,
        selectedPlatformId: selectedPlatformId ?? this.selectedPlatformId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        selectedReportType: selectedReportType,
      );

  // ── Computed analytics ───────────────────────────────────────────────────

  double get avgDeliveryOntime {
    final vals = records.map((r) => r.deliveryOntimePct).whereType<double>().toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double get avgShiftCompliance {
    final vals = records.map((r) => r.shiftCompliancePct).whereType<double>().toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  int get totalOrders => records.fold(0, (sum, r) => sum + (r.totalOrders ?? 0));
  int get totalDelivered => records.fold(0, (sum, r) => sum + (r.deliveredOrders ?? 0));

  List<PerformanceRecord> get topPerformers {
    final sorted = [...records]
      ..sort((a, b) => (b.deliveryOntimePct ?? 0).compareTo(a.deliveryOntimePct ?? 0));
    return sorted.take(10).toList();
  }

  List<PerformanceRecord> get bottomPerformers {
    final sorted = records
        .where((r) => r.deliveryOntimePct != null)
        .toList()
      ..sort((a, b) => (a.deliveryOntimePct ?? 0).compareTo(b.deliveryOntimePct ?? 0));
    return sorted.take(10).toList();
  }

  Map<String, double> get avgByPlatform {
    final grouped = <String, List<double>>{};
    for (final r in records) {
      if (r.deliveryOntimePct == null) continue;
      final key = r.platformName.isNotEmpty ? r.platformName : r.platformId;
      grouped.putIfAbsent(key, () => []).add(r.deliveryOntimePct!);
    }
    return grouped.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
  }
}

class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final PerformanceRepository _repo;
  final String userId;

  PerformanceNotifier(this._repo, this.userId) : super(PerformanceState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.fetchPerformanceRecords(
          platformId: state.selectedPlatformId,
          startDate: state.startDate,
          endDate: state.endDate,
          reportType: state.selectedReportType,
        ),
        _repo.fetchShiftRecords(
          platformId: state.selectedPlatformId,
          startDate: state.startDate,
          endDate: state.endDate,
        ),
      ]);
      state = state.copyWith(
        records: results[0] as List<PerformanceRecord>,
        shifts: results[1] as List<ShiftRecord>,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setPlatform(String? id) {
    state = state.copyWith(selectedPlatformId: id);
    loadData();
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    loadData();
  }

  void setReportType(String? type) {
    state = state.copyWith(selectedReportType: type);
    loadData();
  }

  Future<void> uploadAndParse({
    required Uint8List fileBytes,
    required String fileName,
    required String platformId,
    required DateTime reportDate,
    required ReportType reportType,
  }) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      await _repo.uploadAndRecord(
        fileBytes: fileBytes,
        fileName: fileName,
        userId: userId,
        platformId: platformId,
        reportDate: reportDate,
        reportType: reportType,
      );
      state = state.copyWith(uploading: false);
      await loadData();
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
      rethrow;
    }
  }
}

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  return PerformanceRepository(Supabase.instance.client);
});

final performanceProvider =
    StateNotifierProvider.autoDispose<PerformanceNotifier, PerformanceState>((ref) {
  final repo = ref.watch(performanceRepositoryProvider);
  final auth = ref.watch(authProvider);
  return PerformanceNotifier(repo, auth.user?.id ?? '');
});
