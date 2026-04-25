class Vehicle {
  final String id; // IMEI
  final String name;
  final String plateNumber;
  final String protocol;
  final String status;
  final bool active;
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
    this.position,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final imei = json['imei']?.toString() ?? '';
    final hasLocation =
        json['latitude'] != null && json['longitude'] != null;

    return Vehicle(
      id: imei,
      name: json['name']?.toString() ?? imei,
      plateNumber: json['plate_number']?.toString() ?? '',
      protocol: json['protocol']?.toString() ?? '',
      status: _normalizeStatus(json['status']?.toString() ?? ''),
      active: true,
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

  VehiclePosition({
    required this.lat,
    required this.lng,
    this.speed = 0,
    this.heading = 0,
    required this.timestamp,
    this.odometer = 0,
    this.battery = 0,
    this.power = 0,
    this.address = '',
    this.ignition = false,
    this.moving = false,
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

    return VehiclePosition(
      lat: _parseD(json['latitude']),
      lng: _parseD(json['longitude']),
      speed: speed,
      heading: _parseD(json['angle']),
      timestamp: timestamp,
      ignition: ignitionStr == 'on',
      moving: speed > 0,
      battery: _parseD(json['internal_voltage']),
      power: _parseD(json['external_voltage']),
    );
  }

  static double _parseD(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
