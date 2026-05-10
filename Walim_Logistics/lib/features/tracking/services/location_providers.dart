import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/shared/models/profile.dart';

const _riderRoleName = 'Rider';

final permissionStatusProvider = FutureProvider<bool>((ref) async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
});

final rolesProvider = FutureProvider<Map<String, String>>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final res = await supabase.from('roles').select('id, name');
    return {
      for (final r in res as List) 
        r['id'].toString().toLowerCase(): r['name'].toString().trim()
    };
  } catch (_) {
    return const {};
  }
});

final allRidersLocationProvider = StreamProvider<List<UserProfile>>((ref) {
  final supabase = Supabase.instance.client;
  final rolesAsync = ref.watch(rolesProvider);

  return rolesAsync.when(
    data: (roleMap) {
      return supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .map((data) => data
              .map((json) {
                final roleId = json['role_id']?.toString().toLowerCase();
                final roleName = roleId != null ? (roleMap[roleId] ?? 'Rider') : 'Rider';
                return UserProfile.fromJson({
                  ...json,
                  'role_name': roleName,
                });
              })
              .where((p) =>
                  p.role == _riderRoleName &&
                  p.lastLat != null &&
                  p.lastLng != null)
              .toList());
    },
    loading: () => const Stream<List<UserProfile>>.empty(),
    error: (e, s) => const Stream<List<UserProfile>>.empty(),
  );
});
