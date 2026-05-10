import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';
import 'api_service.dart';

final trackingProvider = ChangeNotifierProvider((ref) => TrackingProvider());

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
  String _statusFilter = '';
  String _selectedCity = 'All';
  String _activeMenu = 'Live GPS';
  final Set<String> _resolvedIncidentIds = {};
  int _consecutiveErrors = 0;

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
  String _userBranch = '';
  String _lastUpdate = 'Just now';

  List<Vehicle> get vehicles {
    List<Vehicle> filtered = _vehicles;

    if (_statusFilter.isNotEmpty && _statusFilter != 'total') {
      filtered = filtered.where((v) {
        switch (_statusFilter) {
          case 'moving':
            return v.status == 'moving';
          case 'idle':
            return v.status == 'idle';
          case 'stopped':
            if (v.status == 'stopped') return true;
            if (v.status == 'offline') {
              if (v.position == null) return true;
              final diff = DateTime.now().difference(v.position!.timestamp);
              return diff.inHours <= 48;
            }
            return false;
          case 'offline':
            if (v.status != 'offline') return false;
            if (v.position == null) return false;
            final diff = DateTime.now().difference(v.position!.timestamp);
            return diff.inHours > 48;
          case 'no_data':
            return v.position == null;
          default:
            return true;
        }
      }).toList();
    }

    if (_filter.isEmpty) return filtered;
    final q = _filter.toLowerCase();
    return filtered
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
  String get statusFilter => _statusFilter;
  String get userName => _userName;
  String get userBranch => _userBranch;
  String get lastUpdate => _lastUpdate;
  String get selectedCity => _selectedCity;
  String get activeMenu => _activeMenu;

  int get totalCount => _vehicles.length;
  int get movingCount =>
      _vehicles.where((v) => v.status == 'moving').length;
  int get idleCount => _vehicles
      .where((v) => v.status == 'idle').length;
  int get stoppedCount => _vehicles.where((v) {
        if (v.status == 'stopped') return true;
        if (v.status == 'offline') {
          if (v.position == null) return true;
          final diff = DateTime.now().difference(v.position!.timestamp);
          return diff.inHours <= 48;
        }
        return false;
      }).length;
  int get offlineCount => _vehicles.where((v) {
        if (v.status != 'offline') return false;
        if (v.position == null) return false;
        final diff = DateTime.now().difference(v.position!.timestamp);
        return diff.inHours > 48;
      }).length;
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

  void setStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setSelectedCity(String value) {
    _selectedCity = value;
    notifyListeners();
  }

  void setActiveMenu(String value) {
    _activeMenu = value;
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
      final devices = await _api.getDevices();
      
      // Fetch vehicle metadata from Supabase
      try {
        final supabase = Supabase.instance.client;
        final List<dynamic> dbVehicles = await supabase
            .from('vehicles')
            .select('plate_number, make, model, vin_number, type, assigned_profile_id, profiles(full_name, iqama_number)');
            
        final dbVehiclesMap = <String, Map<String, dynamic>>{};
        for (var v in dbVehicles) {
          final plate = v['plate_number']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
          if (plate.isNotEmpty) {
            dbVehiclesMap[plate] = v as Map<String, dynamic>;
          }
        }
        
        final mergedVehicles = devices.map((v) {
          final cleanPlate = v.plateNumber.toLowerCase().replaceAll(' ', '');
          final dbVehicle = dbVehiclesMap[cleanPlate];
          if (dbVehicle != null) {
            final profiles = dbVehicle['profiles'];
            String? riderName = v.riderName;
            String? iqamaNumber = v.iqamaNumber;
            if (profiles is Map<String, dynamic>) {
              riderName = profiles['full_name']?.toString() ?? riderName;
              iqamaNumber = profiles['iqama_number']?.toString() ?? iqamaNumber;
            } else if (profiles is List && profiles.isNotEmpty) {
              riderName = profiles[0]['full_name']?.toString() ?? riderName;
              iqamaNumber = profiles[0]['iqama_number']?.toString() ?? iqamaNumber;
            }
            return Vehicle(
              id: v.id,
              name: v.name,
              plateNumber: v.plateNumber,
              protocol: v.protocol,
              status: v.status,
              active: v.active,
              riderName: riderName,
              iqamaNumber: iqamaNumber,
              make: dbVehicle['make']?.toString() ?? '',
              model: dbVehicle['model']?.toString() ?? '',
              vin: dbVehicle['vin_number']?.toString() ?? '',
              position: v.position,
            );
          }
          return v;
        }).toList();
        
        _vehicles = mergedVehicles;
      } catch (dbError) {
        debugPrint('Error merging Supabase vehicle metadata: $dbError');
        _vehicles = devices;
      }
      
      _lastUpdate = DateFormat('HH:mm').format(DateTime.now());
      _consecutiveErrors = 0;
      _error = null;
    } catch (e) {
      _consecutiveErrors++;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Connection refused') || msg.contains('SocketException')) {
        _error = 'Proxy offline — run: dart run proxy/bin/proxy.dart';
      } else if (msg.contains('TimeoutException') || msg.contains('timed out') || msg.contains('504') || msg.contains('500')) {
        _error = 'Rakeen tracking service is temporarily unavailable. Showing last known data.';
      } else {
        _error = msg;
      }
    }
    _loading = false;
    notifyListeners();
    // Back off refresh interval after consecutive failures (max 2 min)
    if (_consecutiveErrors > 0) {
      _startRefresh();
    }
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    // Back off to 2 min after 3+ consecutive failures; normal 30s otherwise
    final interval = _consecutiveErrors >= 3
        ? const Duration(seconds: 120)
        : const Duration(seconds: 30);
    _refreshTimer = Timer.periodic(interval, (_) {
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
