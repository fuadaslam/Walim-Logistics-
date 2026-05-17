import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/performance_record.dart';
import 'parser_utils.dart';

/// Parses Ninja grocery shift assignment Excel files.
/// Each meaningful sheet represents one day (e.g. "1st May shifts", "2nd May", "4 May").
/// Columns: Sr.no | DA Name | ID Belong to | ID User | Shift Time Start | Area | ...
class NinjaShiftParser {
  static List<ShiftRecord> parse(
    Uint8List bytes, {
    required String uploadId,
    required String platformId,
    required DateTime baseDate,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final records = <ShiftRecord>[];

    for (final sheetName in excel.tables.keys) {
      // Skip generic/unused sheets
      final lower = sheetName.toLowerCase();
      if (lower == 'sheet1' || lower == 'sheet2' || lower == 'sheet3') continue;

      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.length < 2) continue;

      final date = _parseDateFromSheet(sheetName, baseDate);

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        // ID User is the internal rider ID; DA Name is the name
        final riderId = cellStr(row, 3); // ID User
        final riderName = cellStr(row, 1); // DA Name
        if (riderId.isEmpty && riderName.isEmpty) continue;
        if (riderId == 'ID User' || riderName == 'DA Name') continue;

        final shiftTime = cellStr(row, 4);
        final area = cellStr(row, 5);

        records.add(ShiftRecord(
          uploadId: uploadId,
          platformId: platformId,
          recordDate: date,
          shiftSlot: shiftTime,
          area: area,
          targetCount: 0,
          externalRiderId: riderId.isNotEmpty ? riderId : riderName,
          riderName: riderName,
        ));
      }
    }
    return records;
  }

  static DateTime _parseDateFromSheet(String sheetName, DateTime baseDate) {
    // Patterns: "1st May shifts", "2nd May", "3 May", "4 May"
    final clean = sheetName.toLowerCase().replaceAll(RegExp(r'(st|nd|rd|th|shifts?)'), '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts[0]);
      final month = _monthNum(parts[1]);
      if (day != null && month != null) {
        return DateTime(baseDate.year, month, day);
      }
    }
    return baseDate;
  }

  static int? _monthNum(String name) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[name.substring(0, 3)];
  }
}
