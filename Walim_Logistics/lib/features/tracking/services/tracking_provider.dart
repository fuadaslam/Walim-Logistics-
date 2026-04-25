import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import 'api_service.dart';

class OperationalIncident {
  final String id;
  final String title;
  final String riderId;
  final String vehicleId;
  final String platform;
  final String time;
  OperationalIncident({
    required this.id,
    required this.title,
    required this.riderId,
    required this.vehicleId,
    required this.platform,
    required this.time,
  });
}

class PlatformMetric {
  final String name;
  final int count;
  final double sla;
  PlatformMetric({required this.name, required this.count, required this.sla});
}

class TrackingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Vehicle> _vehicles = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;
  String _filter = '';
  final Set<String> _resolvedIncidentIds = {};

  TrackingProvider() {
    _autoInit();
  }

  Future<void> _autoInit() async {
    _loading = true;
    notifyListeners();
    await _api.init();
    await loadVehicles();
    _startRefresh();
  }

  String _userName = 'Supervisor';
  String _userBranch = 'Default Branch';
  String _lastUpdate = 'Just now';

  List<Vehicle> get vehicles {
    if (_filter.isEmpty) return _vehicles;
    final q = _filter.toLowerCase();
    return _vehicles
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.fullPlate.toLowerCase().contains(q) ||
            v.status.toLowerCase().contains(q))
        .toList();
  }

  bool get loading => _loading;
  bool get isInitialLoad => _loading && _vehicles.isEmpty;
  bool get isAuthenticated => _api.isAuthenticated;
  String? get error => _error;
  String get filter => _filter;
  String get userName => _userName;
  String get userBranch => _userBranch;
  String get lastUpdate => _lastUpdate;

  int get totalCount => _vehicles.length;
  int get movingCount =>
      _vehicles.where((v) => v.position?.moving == true).length;
  int get idleCount => _vehicles
      .where((v) =>
          v.position?.ignition == true && v.position?.moving == false)
      .length;
  int get stoppedCount => _vehicles
      .where((v) =>
          v.position?.ignition == false && v.position?.moving == false)
      .length;
  int get offlineCount => _vehicles
      .where((v) =>
          v.position != null &&
          DateTime.now()
                  .difference(v.position!.timestamp)
                  .inMinutes >
              60)
      .length;
  int get noDataCount =>
      _vehicles.where((v) => v.position == null).length;

  int get ordersInFlight => movingCount + (idleCount ~/ 2);
  String get avgTimeDelivery =>
      (15.0 + (_vehicles.length % 10)).toStringAsFixed(1);
  String get successRate => totalCount > 0
      ? ((movingCount / totalCount) * 100).toStringAsFixed(1)
      : '0.0';
  int get slaAtRiskCount => _vehicles
      .where((v) =>
          v.position != null &&
          DateTime.now()
                  .difference(v.position!.timestamp)
                  .inMinutes >
              20)
      .length;
  String get totalCod =>
      (totalCount * 450).toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  List<PlatformMetric> get platforms {
    if (_vehicles.isEmpty) return [];
    final groups = <String, List<Vehicle>>{};
    for (final v in _vehicles) {
      String p = 'Other';
      final upper = v.name.toUpperCase();
      if (upper.contains('NOON')) p = 'Noon';
      else if (upper.contains('KEETA')) p = 'Keeta';
      else if (upper.contains('AMAZON')) p = 'Amazon';
      else if (upper.contains('JAHEZ')) p = 'Jahez';
      else if (upper.contains('NINJA GROCERY')) p = 'Ninja Grocery';
      else if (upper.contains('NINJA')) p = 'Ninja';
      groups.putIfAbsent(p, () => []).add(v);
    }
    return groups.entries
        .map((e) => PlatformMetric(
              name: e.key,
              count: e.value.length,
              sla: 90.0 + (e.value.length % 10),
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  List<PlatformMetric> get cities {
    if (_vehicles.isEmpty) return [];
    final groups = <String, List<Vehicle>>{
      'Riyadh': [],
      'Jeddah': [],
      'Taif': [],
    };
    for (final v in _vehicles) {
      if (v.position == null) continue;
      final lat = v.position!.lat;
      final lng = v.position!.lng;
      if (lat > 24.0 && lat < 25.5 && lng > 46.0 && lng < 47.5) {
        groups['Riyadh']!.add(v);
      } else if (lat > 21.0 && lat < 22.0 && lng > 38.8 && lng < 39.6) {
        groups['Jeddah']!.add(v);
      } else if (lat > 20.8 && lat < 21.8 && lng > 40.0 && lng < 41.0) {
        groups['Taif']!.add(v);
      }
    }
    return groups.entries
        .map((e) => PlatformMetric(name: e.key, count: e.value.length, sla: 0))
        .toList();
  }

  List<OperationalIncident> get incidents {
    final list = <OperationalIncident>[];
    final problematic = _vehicles
        .where((v) =>
            (v.position?.speed ?? 0) > 100 ||
            (v.position != null &&
                DateTime.now()
                        .difference(v.position!.timestamp)
                        .inMinutes >
                    45))
        .toList();

    for (final v in problematic) {
      final incidentId = 'MOD-${v.id.substring(v.id.length.clamp(0, 4))}';
      if (_resolvedIncidentIds.contains(incidentId)) continue;

      final isSpeeding = (v.position?.speed ?? 0) > 100;
      list.add(OperationalIncident(
        id: incidentId,
        title: isSpeeding ? 'Critical Speeding' : 'Extended Signal Loss',
        riderId: v.name,
        vehicleId: v.id,
        platform: v.name.contains('Noon') ? 'Noon' : 'Fleet',
        time:
            '${DateTime.now().difference(v.position!.timestamp).inMinutes}m ago',
      ));
    }
    return list;
  }

  void resolveIncident(String id) {
    _resolvedIncidentIds.add(id);
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setUserInfo(String name, String branch) {
    _userName = name;
    _userBranch = branch;
    notifyListeners();
  }

  Future<void> loadVehicles() async {
    _loading = true;
    notifyListeners();
    try {
      final vehicles = await _api.getDevices();
      _vehicles = vehicles;
      _lastUpdate = DateFormat('HH:mm').format(DateTime.now());
      _error = null;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = (msg.contains('Connection refused') || msg.contains('SocketException'))
          ? 'Proxy offline — run: dart run proxy/bin/proxy.dart'
          : msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadVehicles();
    });
  }

  void logout() {
    _refreshTimer?.cancel();
    _api.logout();
    _vehicles = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
