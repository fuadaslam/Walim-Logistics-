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

final allRidersLocationProvider = StreamProvider<List<UserProfile>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .map((json) => UserProfile.fromJson(json))
          .where((p) =>
              p.role == _riderRoleName &&
              p.lastLat != null &&
              p.lastLng != null)
          .toList());
});
