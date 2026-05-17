import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/performance_record.dart';
import 'parser_utils.dart';

/// Parses Keeta daily operations Excel exports.
/// Expected columns (0-indexed):
///  0: Date, 1: Courier ID, 2: First Name, 3: Last Name, 4: Supervisor, 5: Vehicle Type
///  6: Shift_Attendance Summary, 7: Shift_On-Shift?, 8: Shift_Valid Day?
///  9: Shift_Courier App Online Time, 10: Shift_Valid Online Time, 11: Shift_Peak Online Hours
///  12: Task Volumes_Accepted Tasks, 13: …restaurant arrivals, 14: Delivered Tasks
///  15: Large Order Tasks, 16: Rejected Tasks, 17: Rejected (Courier), 18: Rejected (Auto)
///  19: Cancellation Rate, 20: Order completion rate
///  21: Delivery Experience_On-time Rate (D), 22: Large order on-time rate
///  23: Avg Delivery Time, 24: Delivered Orders Prop. (Over 55min)
///  25: Overdue Order Tasks, 26: Severely Overdue Order Tasks
class KeetaDailyParser {
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

      // First row may be headers; detect by checking if Courier ID is a number
      final startRow = _detectDataStart(sheet.rows);

      for (var i = startRow; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final courierId = cellStr(row, 1);
        if (courierId.isEmpty || courierId == 'Courier ID') continue;

        final firstName = cellStr(row, 2);
        final lastName = cellStr(row, 3);
        final riderName = '$firstName $lastName'.trim();
        if (riderName.isEmpty) continue;

        final ontime = cellDouble(row, 21);
        final acceptedTasks = cellInt(row, 12);
        final deliveredTasks = cellInt(row, 14);
        final date = cellDate(row, 0) ?? reportDate;

        records.add(PerformanceRecord.create(
          uploadId: uploadId,
          platformId: platformId,
          recordDate: date,
          externalRiderId: courierId,
          riderName: riderName,
          totalOrders: acceptedTasks,
          deliveredOrders: deliveredTasks,
          deliveryOntimePct: safePercent(ontime),
          workingHours: cellDouble(row, 9),
          reportType: ReportType.keetaDaily,
          rawMetrics: {
            'supervisor': cellStr(row, 4),
            'vehicle_type': cellStr(row, 5),
            'attendance_summary': cellStr(row, 6),
            'on_shift': cellStr(row, 7),
            'valid_day': cellStr(row, 8),
            'valid_online_time': cellDouble(row, 10),
            'peak_online_hours': cellDouble(row, 11),
            'restaurant_arrivals': cellInt(row, 13),
            'large_order_tasks': cellInt(row, 15),
            'rejected_tasks': cellInt(row, 16),
            'rejected_courier': cellInt(row, 17),
            'rejected_auto': cellInt(row, 18),
            'cancellation_rate': safePercent(cellDouble(row, 19)),
            'order_completion_rate': safePercent(cellDouble(row, 20)),
            'large_order_ontime': safePercent(cellDouble(row, 22)),
            'avg_delivery_time': cellDouble(row, 23),
            'orders_over_55min_pct': safePercent(cellDouble(row, 24)),
            'overdue_tasks': cellInt(row, 25),
            'severely_overdue': cellInt(row, 26),
          },
        ));
      }
    }
    return records;
  }

  static int _detectDataStart(List<List<Data?>> rows) {
    for (var i = 0; i < rows.length && i < 5; i++) {
      final row = rows[i];
      if (row.length > 1) {
        final val = cellStr(row, 1);
        if (val != 'Courier ID' && val.isNotEmpty && RegExp(r'^\d+$').hasMatch(val)) {
          return i;
        }
      }
    }
    return 1;
  }
}
