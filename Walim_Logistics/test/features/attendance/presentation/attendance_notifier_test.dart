// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:walim_logistics/core/services/location_service.dart';
import 'package:walim_logistics/features/attendance/data/attendance_repository.dart';
import 'package:walim_logistics/features/attendance/presentation/attendance_notifier.dart';
import 'package:walim_logistics/features/auth/data/auth_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

/// A fake AuthNotifier that bypasses Supabase initialization and holds a preset profile.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    required UserProfile? profile,
    required MockAuthRepository repo,
    required MockSupabaseClient supabase,
  }) : super(repo, supabase) {
    if (profile != null) {
      state = AuthState(profile: profile);
    }
  }
}

UserProfile _makeProfile({String id = 'user-1'}) => UserProfile(
      id: id,
      role: 'Rider',
      fullName: 'Test Rider',
      status: 'active',
    );

void main() {
  late MockAttendanceRepository mockRepo;
  late MockLocationService mockLocationService;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseClient mockSupabase;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockRepo = MockAttendanceRepository();
    mockLocationService = MockLocationService();
    mockGoTrue = MockGoTrueClient();
    mockSupabase = MockSupabaseClient();
    mockAuthRepo = MockAuthRepository();

    // Suppress AuthNotifier._init() by making it see no current user and an empty auth stream.
    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.currentUser).thenReturn(null);
    when(() => mockGoTrue.onAuthStateChange).thenAnswer((_) => Stream.empty());

    when(() => mockLocationService.startTracking()).thenAnswer((_) async {});
    when(() => mockLocationService.stopTracking()).thenReturn(null);
  });

  ProviderContainer _makeContainer({
    UserProfile? profile,
    Map<String, dynamic>? activeShift,
    List<String> periods = const [],
  }) {
    when(() => mockRepo.getActiveShift(any())).thenAnswer((_) async => activeShift);
    when(() => mockRepo.getTodayCheckInPeriods(any())).thenAnswer((_) async => periods);

    return ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepo),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            profile: profile,
            repo: mockAuthRepo,
            supabase: mockSupabase,
          ),
        ),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
    );
  }

  group('AttendanceNotifier initialization', () {
    test('starts with default state when no profile is authenticated', () async {
      final container = _makeContainer(profile: null);
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(attendanceProvider);
      expect(state.hasActiveShift, false);
      expect(state.isCheckingIn, false);
      expect(state.error, null);
      expect(state.todayCheckIns, 0);
    });

    test('does not query the repository when no profile is authenticated', () async {
      final container = _makeContainer(profile: null);
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRepo.getActiveShift(any()));
      verifyNever(() => mockRepo.getTodayCheckInPeriods(any()));
    });

    test('hasActiveShift is false when no active shift exists', () async {
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: null,
        periods: [],
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(attendanceProvider).hasActiveShift, false);
    });

    test('hasActiveShift is true when an active shift exists', () async {
      final shiftStart = DateTime.now().subtract(const Duration(hours: 2));
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: {
          'id': 'shift-1',
          'check_in_time': shiftStart.toIso8601String(),
        },
        periods: ['Morning'],
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(attendanceProvider).hasActiveShift, true);
    });

    test('shiftStartTime is populated from active shift check_in_time', () async {
      final shiftStart = DateTime(2024, 6, 15, 8, 0).toUtc();
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: {
          'id': 'shift-1',
          'check_in_time': shiftStart.toIso8601String(),
        },
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(attendanceProvider).shiftStartTime, isNotNull);
    });

    test('todayCheckIns reflects completed periods count', () async {
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: null,
        periods: ['Morning', 'Afternoon'],
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(attendanceProvider).todayCheckIns, 2);
    });

    test('starts location tracking when an active shift exists', () async {
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: {
          'id': 'shift-1',
          'check_in_time': DateTime.now().toIso8601String(),
        },
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      verify(() => mockLocationService.startTracking()).called(1);
    });

    test('does not start location tracking when no active shift', () async {
      final container = _makeContainer(
        profile: _makeProfile(),
        activeShift: null,
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      verifyNever(() => mockLocationService.startTracking());
    });

    test('queries repository with the correct profile id', () async {
      const profileId = 'specific-profile-id';
      final container = _makeContainer(
        profile: _makeProfile(id: profileId),
        activeShift: null,
      );
      addTearDown(container.dispose);

      container.read(attendanceProvider);
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.getActiveShift(profileId)).called(1);
      verify(() => mockRepo.getTodayCheckInPeriods(profileId)).called(1);
    });
  });
}
