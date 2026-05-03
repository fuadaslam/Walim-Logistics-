class UserProfile {
  final String id;
  final String role;
  final String fullName;
  final String? phoneNumber;
  final String status;
  final String? iqamaNumber;
  final String? passportNumber;
  final String? drivingLicense;
  final String? sponsorship;
  final String? emergencyContact;
  final String? location;
  final double? rating;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastLocationUpdate;

  UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    required this.status,
    this.iqamaNumber,
    this.passportNumber,
    this.drivingLicense,
    this.sponsorship,
    this.emergencyContact,
    this.location,
    this.rating,
    this.lastLat,
    this.lastLng,
    this.lastLocationUpdate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String roleName = 'Rider';

    dynamic rolesData = json['roles'] ?? json['role_data'] ?? json['role_id'];

    if (rolesData is Map && rolesData['name'] != null) {
      roleName = rolesData['name'].toString().trim();
    } else if (rolesData is List && rolesData.isNotEmpty && rolesData[0] is Map) {
      roleName = rolesData[0]['name'].toString().trim();
    } else if (json['role_id'] != null) {
      final roleId = json['role_id'].toString().toLowerCase();
      const Map<String, String> roleMap = {
        '15931603-c3e7-488d-8d5c-6d3e5788a088': 'Admin',
        '40bb48ba-cf1a-4434-ad1d-3eeb2db1d439': 'Supervisor',
        '470c2b57-52ea-4669-8f34-b58d11969e7f': 'HR',
        '5dc57752-d71a-4f58-b169-19562466c377': 'IT_Dev',
        '61a76036-39ad-4d2a-b318-4abcd599484c': 'Leader',
        '63086983-aa27-4ddf-84a3-97c142531c17': 'Finance Manager',
        '64aa2586-a57a-4cb6-82c2-efcad4cc41a1': 'Rider',
        'b715adb2-df95-4cd2-a1a6-7c36faef2276': 'Business Development',
        'cf5cc7e6-1964-49c2-bb99-03aaa5068d4f': 'Operations Manager',
      };
      roleName = roleMap[roleId] ?? roleName;
    }

    return UserProfile(
      id: json['id'],
      role: roleName,
      fullName: json['full_name'] ?? 'User',
      phoneNumber: json['phone_number'],
      status: json['status'] ?? 'active',
      iqamaNumber: json['iqama_number'],
      passportNumber: json['passport_number'],
      drivingLicense: json['driving_license'],
      sponsorship: json['sponsorship'],
      emergencyContact: json['emergency_contact'],
      location: json['location'],
      rating: (json['rating'] as num?)?.toDouble(),
      lastLat: (json['last_lat'] as num?)?.toDouble(),
      lastLng: (json['last_lng'] as num?)?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null 
          ? DateTime.parse(json['last_location_update']) 
          : null,
    );
  }
}

