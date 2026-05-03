import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  final SupabaseClient _supabase;

  FinanceRepository(this._supabase);



  Future<Map<String, double>> getFinanceStats() async {
    double fuelExpenses = 0;
    try {
      final expensesResponse = await _supabase
          .from('expenses')
          .select('amount')
          .eq('category', 'fuel');
      for (final row in expensesResponse) {
        fuelExpenses += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      debugPrint('Fuel expenses unavailable: $e');
    }

    return {
      'fuelExpenses': fuelExpenses,
    };
  }







  Future<List<Map<String, dynamic>>> getUpcomingInvoices() async {
    try {
      return await _supabase
          .from('vendor_invoices')
          .select()
          .order('due_date', ascending: true)
          .limit(5);
    } catch (_) {
      return [];
    }
  }


}


