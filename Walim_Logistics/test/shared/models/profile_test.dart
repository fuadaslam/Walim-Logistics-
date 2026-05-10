import 'package:flutter_test/flutter_test.dart';
import 'package:walim_logistics/shared/models/profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    group('role parsing', () {
      test('parses role from nested roles map', () {
        final json = {
          'id': 'u1',
          'full_name': 'Alice',
          'status': 'active',
          'roles': {'name': 'Admin'},
        };
        expect(UserProfile.fromJson(json).role, 'Admin');
      });

      test('parses role from roles list with single item', () {
        final json = {
          'id': 'u1',
          'full_name': 'Bob',
          'status': 'active',
          'roles': [
            {'name': 'Supervisor'}
          ],
        };
        expect(UserProfile.fromJson(json).role, 'Supervisor');
      });

      test('parses role from role_name field when roles is absent', () {
        final json = {
          'id': 'u1',
          'full_name': 'Carol',
          'status': 'active',
          'role_name': 'Finance Manager',
        };
        expect(UserProfile.fromJson(json).role, 'Finance Manager');
      });

      test('defaults to Rider when no role data is present', () {
        final json = {'id': 'u1', 'full_name': 'Dave', 'status': 'active'};
        expect(UserProfile.fromJson(json).role, 'Rider');
      });

      test('maps Admin role_id to Admin', () {
        final json = {
          'id': 'u1',
          'full_name': 'Eve',
          'status': 'active',
          'role_id': '15931603-c3e7-488d-8d5c-6d3e5788a088',
        };
        expect(UserProfile.fromJson(json).role, 'Admin');
      });

      test('maps Supervisor role_id to Supervisor', () {
        final json = {
          'id': 'u1',
          'full_name': 'Frank',
          'status': 'active',
          'role_id': '40bb48ba-cf1a-4434-ad1d-3eeb2db1d439',
        };
        expect(UserProfile.fromJson(json).role, 'Supervisor');
      });

      test('maps HR role_id to HR', () {
        final json = {
          'id': 'u1',
          'full_name': 'Grace',
          'status': 'active',
          'role_id': '470c2b57-52ea-4669-8f34-b58d11969e7f',
        };
        expect(UserProfile.fromJson(json).role, 'HR');
      });

      test('maps Operations Manager role_id correctly', () {
        final json = {
          'id': 'u1',
          'full_name': 'Heidi',
          'status': 'active',
          'role_id': 'cf5cc7e6-1964-49c2-bb99-03aaa5068d4f',
        };
        expect(UserProfile.fromJson(json).role, 'Operations Manager');
      });

      test('maps Business Development role_id correctly', () {
        final json = {
          'id': 'u1',
          'full_name': 'Ivan',
          'status': 'active',
          'role_id': 'b715adb2-df95-4cd2-a1a6-7c36faef2276',
        };
        expect(UserProfile.fromJson(json).role, 'Business Development');
      });

      test('defaults to Rider for unknown role_id', () {
        final json = {
          'id': 'u1',
          'full_name': 'Judy',
          'status': 'active',
          'role_id': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        };
        expect(UserProfile.fromJson(json).role, 'Rider');
      });
    });

    group('basic fields', () {
      test('parses id correctly', () {
        final json = {'id': 'abc-123', 'full_name': 'Test', 'status': 'active'};
        expect(UserProfile.fromJson(json).id, 'abc-123');
      });

      test('parses full_name correctly', () {
        final json = {'id': 'u1', 'full_name': 'John Doe', 'status': 'active'};
        expect(UserProfile.fromJson(json).fullName, 'John Doe');
      });

      test('defaults fullName to "User" when full_name is missing', () {
        final json = {'id': 'u1', 'status': 'active'};
        expect(UserProfile.fromJson(json).fullName, 'User');
      });

      test('parses status correctly', () {
        final json = {'id': 'u1', 'full_name': 'Test', 'status': 'inactive'};
        expect(UserProfile.fromJson(json).status, 'inactive');
      });

      test('defaults status to active when absent', () {
        final json = {'id': 'u1', 'full_name': 'Test'};
        expect(UserProfile.fromJson(json).status, 'active');
      });
    });

    group('optional contact fields', () {
      test('parses email', () {
        final json = {
          'id': 'u1',
          'full_name': 'Karl',
          'status': 'active',
          'email': 'karl@example.com',
        };
        expect(UserProfile.fromJson(json).email, 'karl@example.com');
      });

      test('parses phone_number', () {
        final json = {
          'id': 'u1',
          'full_name': 'Laura',
          'status': 'active',
          'phone_number': '+966501234567',
        };
        expect(UserProfile.fromJson(json).phoneNumber, '+966501234567');
      });

      test('leaves email null when absent', () {
        final json = {'id': 'u1', 'full_name': 'Mike', 'status': 'active'};
        expect(UserProfile.fromJson(json).email, null);
      });
    });

    group('numeric fields', () {
      test('parses rating as double', () {
        final json = {
          'id': 'u1',
          'full_name': 'Nina',
          'status': 'active',
          'rating': 4.5,
        };
        expect(UserProfile.fromJson(json).rating, 4.5);
      });

      test('parses last_lat and last_lng as double', () {
        final json = {
          'id': 'u1',
          'full_name': 'Omar',
          'status': 'active',
          'last_lat': 24.7136,
          'last_lng': 46.6753,
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.lastLat, 24.7136);
        expect(profile.lastLng, 46.6753);
      });

      test('parses integer rating as double', () {
        final json = {
          'id': 'u1',
          'full_name': 'Paula',
          'status': 'active',
          'rating': 5,
        };
        expect(UserProfile.fromJson(json).rating, 5.0);
      });

      test('leaves rating null when absent', () {
        final json = {'id': 'u1', 'full_name': 'Quinn', 'status': 'active'};
        expect(UserProfile.fromJson(json).rating, null);
      });
    });

    group('lastLocationUpdate', () {
      test('parses ISO 8601 date string as DateTime', () {
        final dt = DateTime(2024, 6, 15, 10, 30);
        final json = {
          'id': 'u1',
          'full_name': 'Rita',
          'status': 'active',
          'last_location_update': dt.toIso8601String(),
        };
        expect(UserProfile.fromJson(json).lastLocationUpdate, isNotNull);
      });

      test('leaves lastLocationUpdate null when absent', () {
        final json = {'id': 'u1', 'full_name': 'Sam', 'status': 'active'};
        expect(UserProfile.fromJson(json).lastLocationUpdate, null);
      });

      test('leaves lastLocationUpdate null when explicitly null in json', () {
        final json = {
          'id': 'u1',
          'full_name': 'Tina',
          'status': 'active',
          'last_location_update': null,
        };
        expect(UserProfile.fromJson(json).lastLocationUpdate, null);
      });
    });

    group('group and platform fields', () {
      test('parses group_id and group_name', () {
        final json = {
          'id': 'u1',
          'full_name': 'Uma',
          'status': 'active',
          'group_id': 'g-123',
          'group_name': 'Alpha Team',
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.groupId, 'g-123');
        expect(profile.groupName, 'Alpha Team');
      });

      test('parses platform_id and platform_name', () {
        final json = {
          'id': 'u1',
          'full_name': 'Victor',
          'status': 'active',
          'platform_id': 'p-1',
          'platform_name': 'Noon',
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.platformId, 'p-1');
        expect(profile.platformName, 'Noon');
      });

      test('parses supervisor fields', () {
        final json = {
          'id': 'u1',
          'full_name': 'Wendy',
          'status': 'active',
          'supervisor_id': 'sup-1',
          'supervisor_name': 'Ahmed Ali',
          'supervisor_phone': '+966509876543',
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.supervisorId, 'sup-1');
        expect(profile.supervisorName, 'Ahmed Ali');
        expect(profile.supervisorPhone, '+966509876543');
      });

      test('parses zone_id and zone_name', () {
        final json = {
          'id': 'u1',
          'full_name': 'Xavier',
          'status': 'active',
          'zone_id': 'z-north',
          'zone_name': 'North Zone',
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.zoneId, 'z-north');
        expect(profile.zoneName, 'North Zone');
      });

      test('leaves group and platform fields null when absent', () {
        final json = {'id': 'u1', 'full_name': 'Yara', 'status': 'active'};
        final profile = UserProfile.fromJson(json);
        expect(profile.groupId, null);
        expect(profile.platformId, null);
        expect(profile.supervisorId, null);
        expect(profile.zoneId, null);
      });
    });
  });
}
