import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  final SupabaseClient _supabase;

  FinanceRepository(this._supabase);

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

  Future<List<Map<String, dynamic>>> getPendingReconciliations() async {
    return await _supabase
        .from('cod_reconciliation')
        .select('*, profiles!inner(full_name), platforms!inner(name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> reconcile({
    required String reconId,
    required double expectedAmount,
    required String status,
  }) async {
    final row = await _supabase
        .from('cod_reconciliation')
        .select('collected_amount')
        .eq('id', reconId)
        .single();

    final discrepancy = expectedAmount - ((row['collected_amount'] as num?)?.toDouble() ?? 0.0);

    await _supabase.from('cod_reconciliation').update({
      'expected_amount': expectedAmount,
      'discrepancy': discrepancy,
      'status': status,
      'reconciled_at': DateTime.now().toIso8601String(),
    }).eq('id', reconId);
  }

  Future<List<Map<String, dynamic>>> getPlatforms() async {
    return await _supabase
        .from('platforms')
        .select()
        .order('name', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getReconciliationForPlatform(
    String platformId,
  ) async {
    return await _supabase
        .from('cod_reconciliation')
        .select('*, profiles!inner(full_name, status)')
        .eq('platform_id', platformId)
        .order('created_at', ascending: false)
        .limit(30);
  }
}
