import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

final geocodingProvider = FutureProvider.family<String, ({double lat, double lng})>((ref, pos) async {
  final api = ApiService();
  return api.reverseGeocode(pos.lat, pos.lng);
});
