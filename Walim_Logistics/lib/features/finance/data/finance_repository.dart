import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  final SupabaseClient _supabase;

  FinanceRepository(this._supabase);

  // Rider reports cash collected at end of shift
  Future<void> reportCashCollection({
    required String profileId,
    required String platformId,
    required double amount,
  }) async {
    await _supabase.from('cod_reconciliation').insert({
      'profile_id': profileId,
      'platform_id': platformId,
      'collected_amount': amount,
      'status': 'pending',
    });
  }

  // Get reconciliation data for Finance Manager
  Future<List<Map<String, dynamic>>> getPendingReconciliations() async {
    return await _supabase
        .from('cod_reconciliation')
        .select('*, profiles!inner(full_name), platforms!inner(name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  // Finalize reconciliation by matching with platform data
  Future<void> reconcile({
    required String reconId,
    required double expectedAmount,
    required String status,
  }) async {
    final discrepancy = expectedAmount - 
        (await _supabase.from('cod_reconciliation').select('collected_amount').eq('id', reconId).single())['collected_amount'];

    await _supabase.from('cod_reconciliation').update({
      'expected_amount': expectedAmount,
      'discrepancy': discrepancy,
      'status': status,
      'reconciled_at': DateTime.now().toIso8601String(),
    }).eq('id', reconId);
  }
}
