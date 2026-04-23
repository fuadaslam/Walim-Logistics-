import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String> uploadInspectionPhoto(File file, String userId) async {
    final extension = p.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final path = 'inspections/$userId/$fileName';

    await _supabase.storage.from('fleet_assets').upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _supabase.storage.from('fleet_assets').getPublicUrl(path);
  }
}
