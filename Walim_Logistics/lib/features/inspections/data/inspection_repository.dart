import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/inspection.dart';

class InspectionRepository {
  final SupabaseClient _supabase;

  InspectionRepository(this._supabase);

  Future<List<Inspection>> getTodayInspections() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final response = await _supabase
        .from('inspections')
        .select('*, profiles(full_name)')
        .gte('created_at', startOfDay.toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((json) => Inspection.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getRidersWithShiftToday() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from('rider_shift_plans')
        .select('rider_id, profiles(full_name, phone_number, iqama_number)')
        .eq('shift_date', dateStr);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> submitInspection(Inspection inspection) async {
    await _supabase.from('inspections').insert(inspection.toJson());
  }
}

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository(Supabase.instance.client);
});
