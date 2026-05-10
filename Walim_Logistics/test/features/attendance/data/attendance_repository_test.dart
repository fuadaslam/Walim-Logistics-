import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/features/attendance/data/attendance_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late AttendanceRepository repository;

  setUp(() {
    repository = AttendanceRepository(MockSupabaseClient());
  });

  group('getShiftPeriod', () {
    test('returns Morning at exactly 4:00 AM (start boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 4, 0)), 'Morning');
    });

    test('returns Morning at 8:00 AM (mid range)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 8, 0)), 'Morning');
    });

    test('returns Morning at 11:59 AM (end boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 11, 59)), 'Morning');
    });

    test('returns Afternoon at exactly noon (start boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 12, 0)), 'Afternoon');
    });

    test('returns Afternoon at 2:00 PM (mid range)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 14, 0)), 'Afternoon');
    });

    test('returns Afternoon at 4:59 PM (end boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 16, 59)), 'Afternoon');
    });

    test('returns Evening at exactly 5:00 PM (start boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 17, 0)), 'Evening');
    });

    test('returns Evening at 7:00 PM (mid range)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 19, 0)), 'Evening');
    });

    test('returns Evening at 9:59 PM (end boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 21, 59)), 'Evening');
    });

    test('returns Night at exactly 10:00 PM (start boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 22, 0)), 'Night');
    });

    test('returns Night at midnight', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 0, 0)), 'Night');
    });

    test('returns Night at 2:00 AM', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 2, 0)), 'Night');
    });

    test('returns Night at 3:59 AM (end boundary)', () {
      expect(repository.getShiftPeriod(DateTime(2024, 1, 1, 3, 59)), 'Night');
    });

    test('all 24 hours map to a valid period', () {
      final validPeriods = {'Morning', 'Afternoon', 'Evening', 'Night'};
      for (int hour = 0; hour < 24; hour++) {
        final period = repository.getShiftPeriod(DateTime(2024, 1, 1, hour, 0));
        expect(validPeriods.contains(period), isTrue,
            reason: 'Hour $hour returned unexpected period: $period');
      }
    });
  });
}
