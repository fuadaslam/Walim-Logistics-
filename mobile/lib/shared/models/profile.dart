class UserProfile {
  final String id;
  final String role;
  final String fullName;
  final String? phoneNumber;
  final String status;

  UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print('DEBUG: UserProfile.fromJson input: $json');
    
    String roleName = 'Rider';
    
    // 1. Try to get role from joined data (roles table)
    dynamic rolesData = json['roles'] ?? json['role_data'] ?? json['role_id'];
    
    if (rolesData is Map && rolesData['name'] != null) {
      roleName = rolesData['name'].toString().trim();
    } else if (rolesData is List && rolesData.isNotEmpty && rolesData[0] is Map) {
      roleName = rolesData[0]['name'].toString().trim();
    } 
    // 2. Fallback: Map known UUIDs if join failed
    else if (json['role_id'] != null) {
      final roleId = json['role_id'].toString().toLowerCase();
      // Map based on the IDs seen in the Supabase screenshot
      final Map<String, String> roleMap = {
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
      
      if (roleMap.containsKey(roleId)) {
        roleName = roleMap[roleId]!;
        print('DEBUG: Resolved role from UUID fallback: $roleName');
      }
    }

    print('DEBUG: Final resolved role name: $roleName');

    return UserProfile(
      id: json['id'],
      role: roleName,
      fullName: json['full_name'] ?? 'User',
      phoneNumber: json['phone_number'],
      status: json['status'] ?? 'active',
    );
  }
}
