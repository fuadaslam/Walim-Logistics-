import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/performance_record.dart';
import 'parser_utils.dart';

/// Parses Amazon/Noon Monthly Payment Review Excel files.
/// Sheet "WALM": TID | Station | DSP | [date cols…] | Grand Total | Working Days | Days Off | Total
class AmazonPaymentParser {
  static List<PerformanceRecord> parse(
    Uint8List bytes, {
    required String uploadId,
    required String platformId,
    required DateTime reportDate,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final records = <PerformanceRecord>[];

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.length < 2) continue;

      final headerRow = sheet.rows[0];
      final totalCol = findColByHeader(headerRow, 'Grand Total') ??
          findColByHeader(headerRow, 'Total');
      final workingDaysCol = findColByHeader(headerRow, 'Working Days');

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || row[0] == null) continue;

        final tid = cellStr(row, 0);
        if (tid.isEmpty || tid.toLowerCase() == 'tid') continue;

        records.add(PerformanceRecord.create(
          uploadId: uploadId,
          platformId: platformId,
          recordDate: reportDate,
          externalRiderId: tid,
          riderName: tid,
          totalOrders: totalCol != null ? cellInt(row, totalCol) : null,
          reportType: ReportType.amazonPayment,
          rawMetrics: {
            'station': cellStr(row, 1),
            'dsp': cellStr(row, 2),
            'working_days': workingDaysCol != null ? cellInt(row, workingDaysCol) : null,
          },
        ));
      }
    }
    return records;
  }
}

/// Parses Amazon Monthly DA performance sheets (April 2026.xlsx format).
/// Reads "DA attendance" and "DA deliveries" sheets.
class AmazonMonthlyParser {
  static List<PerformanceRecord> parse(
    Uint8List bytes, {
    required String uploadId,
    required String platformId,
    required DateTime reportDate,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final records = <PerformanceRecord>[];

    // Try to find attendance or delivery data sheets
    for (final sheetName in excel.tables.keys) {
      final lower = sheetName.toLowerCase();
      if (!lower.contains('attendance') && !lower.contains('deliveri') && !lower.contains('earning')) {
        continue;
      }

      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.length < 3) continue;

      // Row 0 may be DSP name; row 1 is the actual header with rider names
      // Find the rider data start
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final first = cellStr(row, 0);
        if (first.isEmpty || first.toLowerCase().contains('dsp') || first.toLowerCase().contains('da name')) continue;

        final riderId = cellStr(row, 1);
        final riderName = first;
        if (riderName.isEmpty) continue;

        // Count present days from remaining columns (P = present, values > 0 = delivered)
        int presentDays = 0;
        int totalDeliveries = 0;
        for (var c = 6; c < row.length; c++) {
          final v = cellStr(row, c);
          if (v.toUpperCase() == 'P' || v == '1') {
            presentDays++;
          } else {
            final num = cellInt(row, c);
            if (num != null && num > 0) totalDeliveries += num;
          }
        }

        records.add(PerformanceRecord.create(
          uploadId: uploadId,
          platformId: platformId,
          recordDate: reportDate,
          externalRiderId: riderId.isNotEmpty ? riderId : riderName,
          riderName: riderName,
          totalOrders: totalDeliveries > 0 ? totalDeliveries : null,
          reportType: ReportType.amazonMonthly,
          rawMetrics: {
            'present_days': presentDays,
            'sheet': sheetName,
          },
        ));
      }
    }
    return records;
  }
}

/// Parses Keeta shift booking spreadsheet (Book6 format).
/// Columns: Task ID | Date | Week | Shift time slot | Shift area |
///          Target courier number | Max scheduled couriers | Actual courier number | Service metrics
class KeetaShiftParser {
  static List<ShiftRecord> parse(
    Uint8List bytes, {
    required String uploadId,
    required String platformId,
    required DateTime reportDate,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final records = <ShiftRecord>[];

    final sheetName = excel.tables.keys.firstOrNull ?? '';
    if (sheetName.isEmpty) return [];

    final sheet = excel.tables[sheetName]!;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty || row[0] == null) continue;

      final date = cellDate(row, 1) ?? reportDate;
      final shiftSlot = cellStr(row, 3);
      final area = cellStr(row, 4);
      final targetCount = cellInt(row, 5) ?? 0;
      final maxCount = cellInt(row, 6);
      final actualCount = cellInt(row, 7);

      if (shiftSlot.isEmpty && area.isEmpty) continue;

      records.add(ShiftRecord(
        uploadId: uploadId,
        platformId: platformId,
        recordDate: date,
        shiftSlot: shiftSlot,
        area: area,
        targetCount: targetCount,
        maxCount: maxCount,
        actualCount: actualCount,
        externalRiderId: cellStr(row, 0),
        riderName: '',
      ));
    }
    return records;
  }
}
