import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  final SupabaseClient _supabase;

  FinanceRepository(this._supabase);

  Future<Map<String, double>> getFinanceStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

    double totalRevenue = 0.0;
    double totalDeliveries = 0.0;
    double pendingCodAmount = 0.0;

    try {
      final reportsResponse = await _supabase
          .from('platform_reports')
          .select('delivery_count, total_cod_amount')
          .gte('report_date', monthStart);
      for (final row in reportsResponse as List) {
        totalRevenue += (row['total_cod_amount'] as num?)?.toDouble() ?? 0.0;
        totalDeliveries += (row['delivery_count'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    try {
      final codResponse = await _supabase
          .from('cod_reconciliation')
          .select('expected_amount')
          .inFilter('status', ['pending', 'flagged']);
      for (final row in codResponse as List) {
        pendingCodAmount += (row['expected_amount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    final profitPerDelivery = totalDeliveries > 0 ? totalRevenue / totalDeliveries : 0.0;

    return {
      'fuelExpenses': 0.0,
      'profitPerDelivery': profitPerDelivery,
      'totalRevenue': totalRevenue,
      'pendingInvoices': pendingCodAmount,
    };
  }

  Future<List<Map<String, dynamic>>> getUpcomingInvoices() async {
    try {
      final res = await _supabase
          .from('cod_reconciliation')
          .select('*, platforms(name)')
          .inFilter('status', ['pending', 'flagged'])
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }
}
