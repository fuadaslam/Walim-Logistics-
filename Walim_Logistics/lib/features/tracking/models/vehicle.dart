class Vehicle {
  final String id; // IMEI
  final String name;
  final String plateNumber;
  final String protocol;
  final String status;
  final bool active;
  final String? riderName;
  final String? iqamaNumber;
  VehiclePosition? position;

  // Retained for UI compatibility
  String get fullPlate => plateNumber.isNotEmpty ? plateNumber : '-';
  double get odometer => position?.odometer ?? 0;
  double get engineHours => 0;
  String get model => '';
  String get vin => '';

  Vehicle({
    required this.id,
    required this.name,
    this.plateNumber = '',
    this.protocol = '',
    this.status = 'unknown',
    this.active = true,
    this.riderName,
    this.iqamaNumber,
    this.position,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final imei = json['imei']?.toString() ?? '';
    final hasLocation =
        json['latitude'] != null && json['longitude'] != null;
    
    final rawName = json['name']?.toString() ?? imei;
    String plate = json['plate_number']?.toString() ?? '';

    // If plate_number is missing, try extracting it from the name
    if (plate.isEmpty || plate == 'null') {
      final parts = rawName.split(' ');
      if (parts.length >= 2) {
        // Common pattern: "1234 ABC Rider Name"
        if (RegExp(r'^\d{1,4}$').hasMatch(parts[0]) && 
            RegExp(r'^[A-Za-z]{1,3}$').hasMatch(parts[1])) {
          plate = '${parts[0]} ${parts[1]}';
        }
      }
    }

    return Vehicle(
      id: imei,
      name: rawName,
      plateNumber: plate,
      protocol: json['protocol']?.toString() ?? '',
      status: _normalizeStatus(json['status']?.toString() ?? ''),
      active: true,
      riderName: json['rider_name'] ?? json['assigned_to_name'] ?? json['full_name'],
      iqamaNumber: json['iqama_number'],
      position: hasLocation ? VehiclePosition.fromDeviceJson(json) : null,
    );
  }

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'moving':
        return 'moving';
      case 'idling':
        return 'idle';
      case 'parked':
        return 'stopped';
      case 'stopped':
        return 'stopped';
      case 'offline':
        return 'offline';
      case 'maintenance':
        return 'offline';
      case 'online':
        return 'idle';
      default:
        return status.toLowerCase();
    }
  }

  String getDisplayStatus() {
    if (status == 'offline' && position != null) {
      final diff = DateTime.now().difference(position!.timestamp);
      if (diff.inHours <= 48) return 'stopped';
    }
    return status;
  }

}

class VehiclePosition {
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final String address;
  final bool ignition;
  final bool moving;
  final double odometer;
  final double battery;
  final double power;
  final double altitude;
  final DateTime? serverTimestamp;
  final String? nearestMarker;
  final String? nearestZone;

  VehiclePosition({
    required this.lat,
    required this.lng,
    this.speed = 0,
    this.heading = 0,
    required this.timestamp,
    this.odometer = 0,
    this.battery = 0,
    this.power = 0,
    this.altitude = 0,
    this.address = '',
    this.ignition = false,
    this.moving = false,
    this.serverTimestamp,
    this.nearestMarker,
    this.nearestZone,
  });

  factory VehiclePosition.fromDeviceJson(Map<String, dynamic> json) {
    final ignitionStr = json['ignition']?.toString() ?? 'unknown';
    final speed = _parseD(json['speed']);

    DateTime timestamp = DateTime.now();
    final trackerAt = json['received_by_tracker_at'];
    final serverAt = json['received_by_server_at'];
    if (trackerAt != null) {
      timestamp = DateTime.tryParse(trackerAt.toString()) ?? DateTime.now();
    } else if (serverAt != null) {
      timestamp = DateTime.tryParse(serverAt.toString()) ?? DateTime.now();
    }

    DateTime? serverTimestamp;
    if (serverAt != null) {
      serverTimestamp = DateTime.tryParse(serverAt.toString());
    }

    return VehiclePosition(
      lat: _parseD(json['latitude']),
      lng: _parseD(json['longitude']),
      speed: speed,
      heading: _parseD(json['angle']),
      timestamp: timestamp,
      serverTimestamp: serverTimestamp,
      ignition: ignitionStr == 'on',
      moving: speed > 0,
      battery: _parseD(json['internal_voltage']),
      power: _parseD(json['external_voltage']),
      odometer: _parseD(json['odometer'] ?? json['total_distance']),
      altitude: _parseD(json['altitude']),
      address: json['address']?.toString() ?? '',
      nearestMarker: json['nearest_marker']?.toString(),
      nearestZone: json['nearest_zone']?.toString(),
    );
  }

  static double _parseD(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
