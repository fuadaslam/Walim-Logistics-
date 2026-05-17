import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  static const _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp', '.bmp',
  };

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

  /// Uploads a staff document (image or PDF) to Supabase Storage.
  /// Images are compressed to ≤75% quality / 1200px before upload.
  /// Returns the public URL.
  Future<String> uploadDocument({
    required File file,
    required String profileId,
    required String docType,
  }) async {
    final ext = p.extension(file.path).toLowerCase();
    final isImage = _imageExtensions.contains(ext);

    if (!isImage) {
      final sizeBytes = await file.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        throw Exception('PDF is too large. Maximum size is 10 MB.');
      }
    }

    final safeType =
        docType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uploadExt = isImage ? '.jpg' : ext;
    final path = 'staff_documents/$profileId/$safeType/$timestamp$uploadExt';

    if (isImage) {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1200,
        minHeight: 1600,
        quality: 75,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressed == null) throw Exception('Image compression failed.');

      await _supabase.storage.from('fleet_assets').uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: false,
            ),
          );
    } else {
      await _supabase.storage.from('fleet_assets').upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              cacheControl: '3600',
              upsert: false,
            ),
          );
    }

    return _supabase.storage.from('fleet_assets').getPublicUrl(path);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseProvider));
});
