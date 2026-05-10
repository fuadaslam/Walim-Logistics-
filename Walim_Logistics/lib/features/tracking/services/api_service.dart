import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'api_service_web.dart' if (dart.library.io) 'api_service_io.dart'
    as platform;
import '../models/vehicle.dart';

class ApiService {
  static const String _apiKey = '57A645391187945A971B78D029383038';
  static const String _directBase = 'https://beta-api-iot.alrakeen.sa/api';

  // Web goes through the local proxy (handles CORS + API key injection).
  // Dev (flutter run):  proxy runs separately at 8080 → absolute URL needed.
  // Prod (built & served by proxy): same-origin → relative path is fine.
  static String get _base {
    if (!kIsWeb) return _directBase;
    return kDebugMode ? 'http://localhost:8080/rakeen' : '/rakeen';
  }

  // On web the proxy injects X-API-KEY; on native we add it ourselves.
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (!kIsWeb) 'X-API-KEY': _apiKey,
  };

  late final http.Client _client;
  String _lastError = '';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _client = platform.createClient();
  }

  Future<bool> init() async {
    try {
      final res = await _client.get(
        Uri.parse('$_base/healthcheck'),
        headers: _headers,
      );
      if (res.statusCode == 200) return true;
      _lastError = 'Health check failed (${res.statusCode})';
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<List<Vehicle>> getDevices() async {
    const pageSize = 250;
    final Map<String, Vehicle> uniqueVehicles = {};
    int page = 1;

    while (true) {
      final uri = Uri.parse('$_base/devices/locations').replace(
        queryParameters: {
          'page[current_page]': '$page',
          'page[max_per_page]': '$pageSize',
          'order[0][field]': 'imei',
          'order[0][direction]': 'asc',
        },
      );

      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 401) throw Exception('Invalid API key');
      if (res.statusCode == 403) throw Exception('Access forbidden');
      if (res.statusCode != 200) throw Exception('API error (${res.statusCode})');

      final body = res.body.trim();
      if (body.isEmpty) throw Exception('Empty response from server');

      final data = jsonDecode(body) as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>? ?? [];

      for (final json in items) {
        final vehicle = Vehicle.fromJson(json as Map<String, dynamic>);
        if (vehicle.id.isEmpty) continue;

        // Deduplicate by name and plate number to handle tracker swaps or duplicate registrations
        final key = '${vehicle.name}_${vehicle.plateNumber}';
        final existing = uniqueVehicles[key];
        
        if (existing == null) {
          uniqueVehicles[key] = vehicle;
        } else {
          // Keep the one with the most recent timestamp
          final newTs = vehicle.position?.timestamp;
          final oldTs = existing.position?.timestamp;
          if (newTs != null && (oldTs == null || newTs.isAfter(oldTs))) {
            uniqueVehicles[key] = vehicle;
          }
        }
      }

      // Stop when this page returned fewer items than the page size
      if (items.length < pageSize) break;
      page++;
    }

    return uniqueVehicles.values.toList();
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      // Use Nominatim for free reverse geocoding
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final res = await _client.get(uri, headers: {
        'Accept-Language': 'en',
        'User-Agent': 'WalimTrackingApp/1.0',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name']?.toString() ?? 'Unknown Address';
      }
      return 'Address Unavailable';
    } catch (e) {
      return 'Geocoding Failed';
    }
  }

  bool get isAuthenticated => true;
  String get lastError => _lastError;
  void logout() {}
}
