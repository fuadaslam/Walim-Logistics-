import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/performance_record.dart';
import '../parsers/keeta_daily_parser.dart';
import '../parsers/keeta_monthly_parser.dart';
import '../parsers/ninja_shift_parser.dart';
import '../parsers/amazon_parser.dart';

class PerformanceRepository {
  final SupabaseClient _supabase;

  PerformanceRepository(this._supabase);

  // ── Upload + parse ────────────────────────────────────────────────────────

  Future<String> uploadAndRecord({
    required Uint8List fileBytes,
    required String fileName,
    required String userId,
    required String platformId,
    required DateTime reportDate,
    required ReportType reportType,
  }) async {
    // 1. Upload file to storage
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'reports/$userId/${ts}_$fileName';
    await _supabase.storage.from('fleet_assets').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    final fileUrl = _supabase.storage.from('fleet_assets').getPublicUrl(path);
    final ext = fileName.split('.').last.toLowerCase();

    // 2. Insert platform_report_uploads record and get ID back
    final uploadRes = await _supabase
        .from('platform_report_uploads')
        .insert({
          'supervisor_id': userId,
          'platform_id': platformId,
          'upload_date': reportDate.toIso8601String().split('T')[0],
          'file_url': fileUrl,
          'file_name': fileName,
          'file_type': _normalizeFileType(ext),
          'status': 'uploaded',
        })
        .select('id')
        .single();
    final uploadId = uploadRes['id'] as String;

    // 3. Parse the file and insert performance/shift records
    await _parseAndInsert(
      fileBytes: fileBytes,
      uploadId: uploadId,
      platformId: platformId,
      reportDate: reportDate,
      reportType: reportType,
      fileExt: ext,
    );

    return uploadId;
  }

  Future<void> _parseAndInsert({
    required Uint8List fileBytes,
    required String uploadId,
    required String platformId,
    required DateTime reportDate,
    required ReportType reportType,
    required String fileExt,
  }) async {
    try {
      if (reportType == ReportType.keetaDaily) {
        final records = KeetaDailyParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertPerformance(records, platformId);
      } else if (reportType == ReportType.keetaMonthly || fileExt == 'csv') {
        final records = KeetaMonthlyParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertPerformance(records, platformId);
      } else if (reportType == ReportType.keetaShift) {
        final shifts = KeetaShiftParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertShifts(shifts);
      } else if (reportType == ReportType.ninjaShift) {
        final shifts = NinjaShiftParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          baseDate: reportDate,
        );
        await _insertShifts(shifts);
      } else if (reportType == ReportType.amazonPayment) {
        final records = AmazonPaymentParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertPerformance(records, platformId);
      } else if (reportType == ReportType.amazonMonthly) {
        final records = AmazonMonthlyParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertPerformance(records, platformId);
      }
      // Noon and Hunger Station use keetaDaily format until confirmed otherwise
      else if (reportType == ReportType.noonReport || reportType == ReportType.hungerStation) {
        final records = KeetaDailyParser.parse(
          fileBytes,
          uploadId: uploadId,
          platformId: platformId,
          reportDate: reportDate,
        );
        await _insertPerformance(records, platformId);
      }
    } catch (_) {
      // Parsing errors are non-fatal; the file is already uploaded
    }
  }

  Future<void> _insertPerformance(List<PerformanceRecord> records, String platformId) async {
    if (records.isEmpty) return;
    // Match riders by external ID against profiles
    final matched = await _matchRiders(records, platformId);
    // Batch insert in chunks of 100
    for (var i = 0; i < matched.length; i += 100) {
      final chunk = matched.sublist(i, i + 100 > matched.length ? matched.length : i + 100);
      await _supabase
          .from('platform_performance_records')
          .insert(chunk.map((r) => r.toInsertJson()).toList());
    }
  }

  Future<void> _insertShifts(List<ShiftRecord> records) async {
    if (records.isEmpty) return;
    for (var i = 0; i < records.length; i += 100) {
      final chunk = records.sublist(i, i + 100 > records.length ? records.length : i + 100);
      await _supabase
          .from('platform_shift_records')
          .insert(chunk.map((r) => r.toInsertJson()).toList());
    }
  }

  Future<List<PerformanceRecord>> _matchRiders(
    List<PerformanceRecord> records,
    String platformId,
  ) async {
    final extIds = records.map((r) => r.externalRiderId).where((id) => id.isNotEmpty).toSet().toList();
    if (extIds.isEmpty) return records;

    try {
      // Resolve platform name to pick the right ID column
      final platformRes = await _supabase
          .from('platforms')
          .select('name')
          .eq('id', platformId)
          .maybeSingle();
      final platformName = (platformRes?['name'] as String? ?? '').toLowerCase();

      String? idColumn;
      if (platformName.contains('keeta')) {
        idColumn = 'keeta_id';
      } else if (platformName.contains('ninja')) {
        idColumn = 'ninja_id';
      } else if (platformName.contains('amazon')) {
        idColumn = 'amazon_id';
      }

      if (idColumn == null) return records;

      final res = await _supabase
          .from('profiles')
          .select('id, $idColumn')
          .inFilter(idColumn, extIds);

      final idMap = <String, String>{};
      for (final row in res as List) {
        final extId = row[idColumn] as String?;
        final profileId = row['id'] as String?;
        if (extId != null && profileId != null) {
          idMap[extId] = profileId;
        }
      }

      return records.map((r) {
        final matched = idMap[r.externalRiderId];
        if (matched == null) return r;
        return PerformanceRecord.create(
          uploadId: r.uploadId,
          platformId: r.platformId,
          recordDate: r.recordDate,
          externalRiderId: r.externalRiderId,
          riderName: r.riderName,
          riderId: matched,
          totalOrders: r.totalOrders,
          deliveredOrders: r.deliveredOrders,
          deliveryOntimePct: r.deliveryOntimePct,
          shiftCompliancePct: r.shiftCompliancePct,
          attendanceOntimePct: r.attendanceOntimePct,
          workingHours: r.workingHours,
          pickupOntimePct: r.pickupOntimePct,
          returnOntimePct: r.returnOntimePct,
          avgDelayMin: r.avgDelayMin,
          avgRoamingMin: r.avgRoamingMin,
          avgOfflineMin: r.avgOfflineMin,
          rawMetrics: r.rawMetrics,
          reportType: r.reportType,
        );
      }).toList();
    } catch (_) {
      return records;
    }
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<PerformanceRecord>> fetchPerformanceRecords({
    String? platformId,
    DateTime? startDate,
    DateTime? endDate,
    String? reportType,
    int limit = 500,
  }) async {
    var query = _supabase
        .from('platform_performance_records')
        .select('*, platforms(name)');

    if (platformId != null) query = query.eq('platform_id', platformId);
    if (startDate != null) query = query.gte('record_date', startDate.toIso8601String().split('T')[0]);
    if (endDate != null) query = query.lte('record_date', endDate.toIso8601String().split('T')[0]);
    if (reportType != null) query = query.eq('report_type', reportType);

    final res = await query.order('record_date', ascending: false).limit(limit);
    return (res as List).map((j) => PerformanceRecord.fromJson(j)).toList();
  }

  Future<List<ShiftRecord>> fetchShiftRecords({
    String? platformId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 500,
  }) async {
    var query = _supabase
        .from('platform_shift_records')
        .select();

    if (platformId != null) query = query.eq('platform_id', platformId);
    if (startDate != null) query = query.gte('record_date', startDate.toIso8601String().split('T')[0]);
    if (endDate != null) query = query.lte('record_date', endDate.toIso8601String().split('T')[0]);

    final res = await query.order('record_date', ascending: false).limit(limit);
    return (res as List).map((j) => ShiftRecord.fromJson(j)).toList();
  }

  static String _normalizeFileType(String ext) {
    switch (ext) {
      case 'xlsx':
      case 'xls': return 'excel';
      case 'csv': return 'csv';
      case 'pdf': return 'pdf';
      default: return 'other';
    }
  }
}
