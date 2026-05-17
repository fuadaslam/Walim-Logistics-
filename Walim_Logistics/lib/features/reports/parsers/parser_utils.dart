import 'package:excel/excel.dart';

double? cellDouble(List<Data?> row, int col) {
  if (col >= row.length || row[col] == null) return null;
  final v = row[col]!.value;
  if (v is IntCellValue) return v.value.toDouble();
  if (v is DoubleCellValue) return v.value;
  if (v is TextCellValue) return double.tryParse((v.value.text ?? '').trim());
  return null;
}

int? cellInt(List<Data?> row, int col) {
  final d = cellDouble(row, col);
  return d?.round();
}

String cellStr(List<Data?> row, int col) {
  if (col >= row.length || row[col] == null) return '';
  final v = row[col]!.value;
  if (v is TextCellValue) return (v.value.text ?? '').trim();
  if (v is IntCellValue) return v.value.toString();
  if (v is DoubleCellValue) return v.value.toString();
  if (v is DateCellValue) return v.asDateTimeLocal().toIso8601String().split('T')[0];
  return v.toString().trim();
}

DateTime? cellDate(List<Data?> row, int col) {
  if (col >= row.length || row[col] == null) return null;
  final v = row[col]!.value;
  if (v is DateCellValue) return v.asDateTimeLocal();
  if (v is TextCellValue) return DateTime.tryParse((v.value.text ?? '').trim());
  return null;
}

double? safePercent(double? value) {
  if (value == null) return null;
  return value > 1.5 ? value : value * 100;
}

int? findColByHeader(List<Data?> headerRow, String name) {
  for (int i = 0; i < headerRow.length; i++) {
    final h = cellStr(headerRow, i).toLowerCase();
    if (h.contains(name.toLowerCase())) return i;
  }
  return null;
}

double? parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

int? parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString().split('.')[0]);
}
