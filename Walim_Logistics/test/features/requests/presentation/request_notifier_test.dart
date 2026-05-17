// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:walim_logistics/features/auth/data/auth_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/requests/data/request_repository.dart';
import 'package:walim_logistics/features/requests/presentation/request_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

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

UserProfile _makeProfile({String id = 'user-001'}) => UserProfile(
      id: id,
      role: 'Rider',
      fullName: 'Test Rider',
      status: 'active',
    );

void main() {
  late MockRequestRepository mockRepo;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseClient mockSupabase;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockRepo = MockRequestRepository();
    mockGoTrue = MockGoTrueClient();
    mockSupabase = MockSupabaseClient();
    mockAuthRepo = MockAuthRepository();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.currentUser).thenReturn(null);
    when(() => mockGoTrue.onAuthStateChange).thenAnswer((_) => Stream.empty());
  });

  ProviderContainer makeUserContainer({
    UserProfile? profile,
    List<Map<String, dynamic>> requests = const [],
  }) {
    when(() => mockRepo.getRequestsForProfile(any())).thenAnswer((_) async => requests);
    return ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(mockRepo),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            profile: profile,
            repo: mockAuthRepo,
            supabase: mockSupabase,
          ),
        ),
      ],
    );
  }

  ProviderContainer makePendingContainer({
    UserProfile? profile,
    List<Map<String, dynamic>> pendingRequests = const [],
  }) {
    when(() => mockRepo.getPendingRequests()).thenAnswer((_) async => pendingRequests);
    return ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(mockRepo),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            profile: profile,
            repo: mockAuthRepo,
            supabase: mockSupabase,
          ),
        ),
      ],
    );
  }

  // ─── RequestNotifier initialization ────────────────────────────────────────

  group('RequestNotifier initialization', () {
    test('sets isLoading false when no profile authenticated', () async {
      final container = makeUserContainer(profile: null);
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(requestProvider);
      expect(state.isLoading, false);
      expect(state.requests, isEmpty);
      expect(state.error, isNull);
    });

    test('does not query repository when no profile', () async {
      final container = makeUserContainer(profile: null);
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRepo.getRequestsForProfile(any()));
    });

    test('loads requests for authenticated profile', () async {
      final requests = [
        {'id': 'req-abcdefgh', 'subject': 'Leave Request', 'status': 'pending', 'type': 'leave'},
      ];
      final container = makeUserContainer(profile: _makeProfile(), requests: requests);
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(requestProvider);
      expect(state.isLoading, false);
      expect(state.requests.length, 1);
      expect(state.requests.first['subject'], 'Leave Request');
    });

    test('queries repository with correct profile id', () async {
      const profileId = 'rider-xyz-456';
      final container = makeUserContainer(profile: _makeProfile(id: profileId));
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.getRequestsForProfile(profileId)).called(1);
    });

    test('sets error when repository throws on load', () async {
      when(() => mockRepo.getRequestsForProfile(any()))
          .thenThrow(Exception('Connection timeout'));

      final container = ProviderContainer(
        overrides: [
          requestRepositoryProvider.overrideWithValue(mockRepo),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              profile: _makeProfile(),
              repo: mockAuthRepo,
              supabase: mockSupabase,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(requestProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });

  // ─── RequestNotifier.submitRequest ─────────────────────────────────────────

  group('RequestNotifier.submitRequest', () {
    test('returns false when no profile authenticated', () async {
      final container = makeUserContainer(profile: null);
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final result = await container.read(requestProvider.notifier).submitRequest(
        type: 'leave',
        subject: 'Annual Leave',
      );
      expect(result, false);
      verifyNever(() => mockRepo.createRequest(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            photoUrls: any(named: 'photoUrls'),
          ));
    });

    test('returns true on successful submission', () async {
      when(() => mockRepo.createRequest(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      final container = makeUserContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final result = await container.read(requestProvider.notifier).submitRequest(
        type: 'leave',
        subject: 'Annual Leave',
        description: 'Taking vacation',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 7),
      );
      expect(result, true);
    });

    test('calls repository with correct parameters', () async {
      when(() => mockRepo.createRequest(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      const profileId = 'rider-def-789';
      final start = DateTime(2025, 7, 1);
      final end = DateTime(2025, 7, 5);

      final container = makeUserContainer(profile: _makeProfile(id: profileId));
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      await container.read(requestProvider.notifier).submitRequest(
        type: 'equipment',
        subject: 'New Helmet',
        description: 'Damaged current helmet',
        startDate: start,
        endDate: end,
      );

      verify(() => mockRepo.createRequest(
            profileId: profileId,
            type: 'equipment',
            subject: 'New Helmet',
            description: 'Damaged current helmet',
            startDate: start,
            endDate: end,
            photoUrls: null,
          )).called(1);
    });

    test('returns false and sets error when repository throws', () async {
      when(() => mockRepo.createRequest(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            photoUrls: any(named: 'photoUrls'),
          )).thenThrow(Exception('Insert failed'));

      final container = makeUserContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      final result = await container.read(requestProvider.notifier).submitRequest(
        type: 'leave',
        subject: 'Sick Leave',
      );
      expect(result, false);
      expect(container.read(requestProvider).error, isNotNull);
      expect(container.read(requestProvider).isSubmitting, false);
    });

    test('sets submitSuccess true on successful submission', () async {
      when(() => mockRepo.createRequest(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      final container = makeUserContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      await container.read(requestProvider.notifier).submitRequest(
        type: 'leave',
        subject: 'Test Leave',
      );

      // After submitRequest calls _load() again, isSubmitting should be false
      expect(container.read(requestProvider).isSubmitting, false);
    });
  });

  // ─── RequestNotifier.cancel ─────────────────────────────────────────────────

  group('RequestNotifier.cancel', () {
    test('calls repository.cancelRequest with the request id', () async {
      when(() => mockRepo.cancelRequest(any())).thenAnswer((_) async {});

      final container = makeUserContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      await container.read(requestProvider.notifier).cancel('req-abc-12345678');

      verify(() => mockRepo.cancelRequest('req-abc-12345678')).called(1);
    });

    test('sets error when cancelRequest throws', () async {
      when(() => mockRepo.cancelRequest(any())).thenThrow(Exception('Cancel failed'));

      final container = makeUserContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(requestProvider);
      await Future.delayed(Duration.zero);

      await container.read(requestProvider.notifier).cancel('req-xyz-98765432');

      expect(container.read(requestProvider).error, isNotNull);
    });
  });

  // ─── PendingRequestNotifier ─────────────────────────────────────────────────

  group('PendingRequestNotifier initialization', () {
    test('loads all pending requests on init', () async {
      final pending = [
        {'id': 'req-pending-1', 'status': 'pending', 'subject': 'Leave Request'},
        {'id': 'req-pending-2', 'status': 'pending', 'subject': 'Equipment Request'},
      ];
      final container = makePendingContainer(profile: _makeProfile(), pendingRequests: pending);
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(pendingRequestProvider);
      expect(state.isLoading, false);
      expect(state.requests.length, 2);
    });

    test('calls getPendingRequests (not getRequestsForProfile)', () async {
      final container = makePendingContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.getPendingRequests()).called(1);
      verifyNever(() => mockRepo.getRequestsForProfile(any()));
    });

    test('sets error when getPendingRequests throws', () async {
      when(() => mockRepo.getPendingRequests()).thenThrow(Exception('Fetch failed'));

      final container = ProviderContainer(
        overrides: [
          requestRepositoryProvider.overrideWithValue(mockRepo),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              profile: _makeProfile(),
              repo: mockAuthRepo,
              supabase: mockSupabase,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(pendingRequestProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });

  // ─── PendingRequestNotifier.reviewRequest ──────────────────────────────────

  group('PendingRequestNotifier.reviewRequest', () {
    test('calls repository with requestId, status, reviewedBy, and reviewNote', () async {
      when(() => mockRepo.reviewRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            reviewNote: any(named: 'reviewNote'),
          )).thenAnswer((_) async {});

      const supervisorId = 'supervisor-001';
      final container = makePendingContainer(profile: _makeProfile(id: supervisorId));
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      await container.read(pendingRequestProvider.notifier).reviewRequest(
        requestId: 'req-abc-12345678',
        status: 'approved',
        reviewNote: 'Approved for annual leave',
      );

      verify(() => mockRepo.reviewRequest(
            requestId: 'req-abc-12345678',
            status: 'approved',
            reviewedBy: supervisorId,
            reviewNote: 'Approved for annual leave',
          )).called(1);
    });

    test('does nothing when no profile authenticated', () async {
      final container = makePendingContainer(profile: null);
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      await container.read(pendingRequestProvider.notifier).reviewRequest(
        requestId: 'req-abc-12345678',
        status: 'approved',
      );

      verifyNever(() => mockRepo.reviewRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            reviewNote: any(named: 'reviewNote'),
          ));
    });

    test('sets error when reviewRequest throws', () async {
      when(() => mockRepo.reviewRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            reviewNote: any(named: 'reviewNote'),
          )).thenThrow(Exception('Review failed'));

      final container = makePendingContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);

      await container.read(pendingRequestProvider.notifier).reviewRequest(
        requestId: 'req-xyz-98765432',
        status: 'rejected',
        reviewNote: 'Insufficient notice',
      );

      expect(container.read(pendingRequestProvider).error, isNotNull);
    });

    test('reloads pending requests after successful review', () async {
      var loadCount = 0;
      when(() => mockRepo.reviewRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            reviewNote: any(named: 'reviewNote'),
          )).thenAnswer((_) async {});
      when(() => mockRepo.getPendingRequests()).thenAnswer((_) async {
        loadCount++;
        return [];
      });

      final container = ProviderContainer(
        overrides: [
          requestRepositoryProvider.overrideWithValue(mockRepo),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              profile: _makeProfile(),
              repo: mockAuthRepo,
              supabase: mockSupabase,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(pendingRequestProvider);
      await Future.delayed(Duration.zero);
      final afterInit = loadCount;

      await container.read(pendingRequestProvider.notifier).reviewRequest(
        requestId: 'req-abc-12345678',
        status: 'approved',
      );

      expect(loadCount, greaterThan(afterInit));
    });
  });

  // ─── RequestState.copyWith ─────────────────────────────────────────────────

  group('RequestState.copyWith', () {
    test('preserves requests when not overridden', () {
      final requests = [
        {'id': 'req-abcdefgh', 'subject': 'Old Request'}
      ];
      final state = RequestState(requests: requests);
      final copied = state.copyWith(isLoading: true);
      expect(copied.requests, requests);
    });

    test('resets error to null when not provided', () {
      const state = RequestState(error: 'connection error');
      final copied = state.copyWith(isLoading: false);
      expect(copied.error, isNull);
    });

    test('resets submitSuccess to false when not provided', () {
      const state = RequestState(submitSuccess: true);
      final copied = state.copyWith(isLoading: false);
      expect(copied.submitSuccess, false);
    });

    test('default state has correct initial values', () {
      const state = RequestState();
      expect(state.requests, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSubmitting, false);
      expect(state.error, isNull);
      expect(state.submitSuccess, false);
    });

    test('updates isLoading and isSubmitting independently', () {
      const state = RequestState();
      final loading = state.copyWith(isLoading: true, isSubmitting: false);
      expect(loading.isLoading, true);
      expect(loading.isSubmitting, false);

      final submitting = state.copyWith(isLoading: false, isSubmitting: true);
      expect(submitting.isLoading, false);
      expect(submitting.isSubmitting, true);
    });
  });
}
