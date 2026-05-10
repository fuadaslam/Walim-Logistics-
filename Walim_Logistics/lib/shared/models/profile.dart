class UserProfile {
  final String id;
  final String role;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String status;
  final String? iqamaNumber;
  final String? passportNumber;
  final String? drivingLicense;
  final String? sponsorship;
  final String? emergencyContact;
  final String? location;
  final String? avatarUrl;
  final double? rating;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastLocationUpdate;

  // Group / platform / supervisor — populated via rider_full_profile view
  final String? groupId;
  final String? groupName;
  final String? platformId;
  final String? platformName;
  final String? supervisorId;
  final String? supervisorName;
  final String? supervisorPhone;
  final String? zoneId;
  final String? zoneName;
  final String? managedPlatforms;
  final String? managedGroups;

  UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.status,
    this.iqamaNumber,
    this.passportNumber,
    this.drivingLicense,
    this.sponsorship,
    this.emergencyContact,
    this.location,
    this.avatarUrl,
    this.rating,
    this.lastLat,
    this.lastLng,
    this.lastLocationUpdate,
    this.groupId,
    this.groupName,
    this.platformId,
    this.platformName,
    this.supervisorId,
    this.supervisorName,
    this.supervisorPhone,
    this.zoneId,
    this.zoneName,
    this.managedPlatforms,
    this.managedGroups,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String roleName = 'Rider';

    dynamic rolesData = json['roles'] ?? json['role_data'] ?? json['role_id'];

    if (rolesData is Map && rolesData['name'] != null) {
      roleName = rolesData['name'].toString().trim();
    } else if (rolesData is List && rolesData.isNotEmpty && rolesData[0] is Map) {
      roleName = rolesData[0]['name'].toString().trim();
    } else if (json['role_name'] != null) {
      roleName = json['role_name'].toString().trim();
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
      email: json['email'],
      phoneNumber: json['phone_number'],
      status: json['status'] ?? 'active',
      iqamaNumber: json['iqama_number'],
      passportNumber: json['passport_number'],
      drivingLicense: json['driving_license'],
      sponsorship: json['sponsorship'],
      emergencyContact: json['emergency_contact'],
      location: json['location'],
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] as num?)?.toDouble(),
      lastLat: (json['last_lat'] as num?)?.toDouble(),
      lastLng: (json['last_lng'] as num?)?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      groupId: json['group_id'],
      groupName: json['group_name'],
      platformId: json['platform_id'],
      platformName: json['platform_name'],
      supervisorId: json['supervisor_id'],
      supervisorName: json['supervisor_name'],
      supervisorPhone: json['supervisor_phone'],
      zoneId: json['zone_id'],
      zoneName: json['zone_name'],
      managedPlatforms: json['managed_platforms'],
      managedGroups: json['managed_groups'],
    );
  }
}
