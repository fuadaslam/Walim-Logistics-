import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/performance_record.dart';
import 'parser_utils.dart';

/// Parses Keeta captain_performance CSV exports.
/// Columns: Supplier ID, Captain ID, Captain Name, Total Orders, Avg Orders,
///          Total Working Hours, Avg Working Hours, Pickup On-Time %,
///          Delivery On-Time %, Return To Area On-Time %,
///          Delivery & Return On-Time %, Shift Compliance %,
///          Attendance On-Time %, Avg Delay (Min), Avg Roaming (Min), Avg Offline (Min)
class KeetaMonthlyParser {
  static List<PerformanceRecord> parse(
    Uint8List bytes, {
    required String uploadId,
    required String platformId,
    required DateTime reportDate,
  }) {
    final csvString = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(csvString);
    if (rows.length < 2) return [];

    final records = <PerformanceRecord>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;

      final captainId = row[1].toString().trim();
      final captainName = row[2].toString().trim();
      if (captainId.isEmpty || captainId == 'Captain ID') continue;

      records.add(PerformanceRecord.create(
        uploadId: uploadId,
        platformId: platformId,
        recordDate: reportDate,
        externalRiderId: captainId,
        riderName: captainName,
        totalOrders: row.length > 3 ? parseInt(row[3]) : null,
        workingHours: row.length > 5 ? parseDouble(row[5]) : null,
        pickupOntimePct: row.length > 7 ? parseDouble(row[7]) : null,
        deliveryOntimePct: row.length > 8 ? parseDouble(row[8]) : null,
        returnOntimePct: row.length > 9 ? parseDouble(row[9]) : null,
        shiftCompliancePct: row.length > 11 ? parseDouble(row[11]) : null,
        attendanceOntimePct: row.length > 12 ? parseDouble(row[12]) : null,
        avgDelayMin: row.length > 13 ? parseDouble(row[13]) : null,
        avgRoamingMin: row.length > 14 ? parseDouble(row[14]) : null,
        avgOfflineMin: row.length > 15 ? parseDouble(row[15]) : null,
        reportType: ReportType.keetaMonthly,
        rawMetrics: {
          'supplier_id': row[0].toString(),
          'avg_orders': row.length > 4 ? parseDouble(row[4]) : null,
          'avg_working_hours': row.length > 6 ? parseDouble(row[6]) : null,
          'delivery_return_ontime_pct': row.length > 10 ? parseDouble(row[10]) : null,
        },
      ));
    }
    return records;
  }
}
