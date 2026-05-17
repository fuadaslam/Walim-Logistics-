// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:walim_logistics/features/auth/data/auth_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/support/data/support_ticket_repository.dart';
import 'package:walim_logistics/features/support/presentation/support_ticket_notifier.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class MockSupportTicketRepository extends Mock implements SupportTicketRepository {}

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
  late MockSupportTicketRepository mockRepo;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseClient mockSupabase;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockRepo = MockSupportTicketRepository();
    mockGoTrue = MockGoTrueClient();
    mockSupabase = MockSupabaseClient();
    mockAuthRepo = MockAuthRepository();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.currentUser).thenReturn(null);
    when(() => mockGoTrue.onAuthStateChange).thenAnswer((_) => Stream.empty());
  });

  ProviderContainer makeContainer({
    UserProfile? profile,
    List<Map<String, dynamic>> tickets = const [],
  }) {
    when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);
    return ProviderContainer(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(mockRepo),
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

  // ─── Initialization ────────────────────────────────────────────────────────

  group('initialization', () {
    test('sets isLoading false when no profile authenticated', () async {
      final container = makeContainer(profile: null);
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(supportTicketProvider);
      expect(state.isLoading, false);
      expect(state.tickets, isEmpty);
      expect(state.error, isNull);
    });

    test('does not query repository when no profile', () async {
      final container = makeContainer(profile: null);
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRepo.getTicketsForProfile(any()));
    });

    test('loads tickets for authenticated profile', () async {
      final tickets = [
        {
          'id': 'ticket-abcdefgh',
          'subject': 'Login Issue',
          'status': 'open',
          'priority': 'high',
        },
      ];
      final container = makeContainer(profile: _makeProfile(), tickets: tickets);
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(supportTicketProvider);
      expect(state.isLoading, false);
      expect(state.tickets.length, 1);
      expect(state.tickets.first['subject'], 'Login Issue');
    });

    test('queries repository with the correct profile id', () async {
      const profileId = 'profile-xyz-789';
      final container = makeContainer(profile: _makeProfile(id: profileId));
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.getTicketsForProfile(profileId)).called(1);
    });

    test('sets error state when repository throws on load', () async {
      when(() => mockRepo.getTicketsForProfile(any()))
          .thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          supportTicketRepositoryProvider.overrideWithValue(mockRepo),
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

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(supportTicketProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
      expect(state.tickets, isEmpty);
    });

    test('multiple tickets are all loaded', () async {
      final tickets = List.generate(
        5,
        (i) => {'id': 'ticket-$i-abcde', 'subject': 'Issue $i', 'status': 'open'},
      );
      final container = makeContainer(profile: _makeProfile(), tickets: tickets);
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(supportTicketProvider).tickets.length, 5);
    });
  });

  // ─── createTicket ──────────────────────────────────────────────────────────

  group('createTicket', () {
    test('returns false when no profile authenticated', () async {
      final container = makeContainer(profile: null);
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final result = await container.read(supportTicketProvider.notifier).createTicket(
        subject: 'Test Subject',
        type: 'other',
        priority: 'normal',
      );
      expect(result, false);
      verifyNever(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          ));
    });

    test('returns true on successful creation', () async {
      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      final container = makeContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final result = await container
          .read(supportTicketProvider.notifier)
          .createTicket(subject: 'App crash', type: 'app_glitch', priority: 'high');
      expect(result, true);
    });

    test('calls repository with all correct parameters', () async {
      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      const profileId = 'rider-abc-001';
      final container = makeContainer(profile: _makeProfile(id: profileId));
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      await container.read(supportTicketProvider.notifier).createTicket(
        subject: 'App crash on login',
        type: 'app_glitch',
        priority: 'high',
        description: 'Crashes after entering password',
      );

      verify(() => mockRepo.createTicket(
            profileId: profileId,
            subject: 'App crash on login',
            type: 'app_glitch',
            priority: 'high',
            description: 'Crashes after entering password',
            photoUrls: null,
          )).called(1);
    });

    test('returns false and sets error when repository throws', () async {
      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenThrow(Exception('DB insert failed'));

      final container = makeContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      final result = await container.read(supportTicketProvider.notifier).createTicket(
        subject: 'Test',
        type: 'other',
        priority: 'normal',
      );
      expect(result, false);
      expect(container.read(supportTicketProvider).error, isNotNull);
      expect(container.read(supportTicketProvider).isSubmitting, false);
    });

    test('reloads tickets after successful creation', () async {
      var loadCount = 0;
      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async {
        loadCount++;
        return [];
      });

      final container = ProviderContainer(
        overrides: [
          supportTicketRepositoryProvider.overrideWithValue(mockRepo),
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

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);
      final afterInit = loadCount;

      await container.read(supportTicketProvider.notifier).createTicket(
        subject: 'Test',
        type: 'other',
        priority: 'normal',
      );

      expect(loadCount, greaterThan(afterInit),
          reason: '_load() should be called again after successful createTicket');
    });
  });

  // ─── updateStatus ──────────────────────────────────────────────────────────

  group('updateStatus', () {
    test('calls repository with ticketId, status, and resolvedBy (profile id)', () async {
      when(() => mockRepo.updateTicketStatus(
            ticketId: any(named: 'ticketId'),
            status: any(named: 'status'),
            resolvedBy: any(named: 'resolvedBy'),
          )).thenAnswer((_) async {});

      const adminId = 'admin-001';
      final container = makeContainer(profile: _makeProfile(id: adminId));
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      await container.read(supportTicketProvider.notifier).updateStatus(
        ticketId: 'ticket-abcde123',
        status: 'resolved',
      );

      verify(() => mockRepo.updateTicketStatus(
            ticketId: 'ticket-abcde123',
            status: 'resolved',
            resolvedBy: adminId,
          )).called(1);
    });

    test('sets error when repository throws during status update', () async {
      when(() => mockRepo.updateTicketStatus(
            ticketId: any(named: 'ticketId'),
            status: any(named: 'status'),
            resolvedBy: any(named: 'resolvedBy'),
          )).thenThrow(Exception('Update failed'));

      final container = makeContainer(profile: _makeProfile());
      addTearDown(container.dispose);

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);

      await container.read(supportTicketProvider.notifier).updateStatus(
        ticketId: 'ticket-456789ab',
        status: 'closed',
      );

      expect(container.read(supportTicketProvider).error, isNotNull);
    });

    test('reloads tickets after status update', () async {
      var loadCount = 0;
      when(() => mockRepo.updateTicketStatus(
            ticketId: any(named: 'ticketId'),
            status: any(named: 'status'),
            resolvedBy: any(named: 'resolvedBy'),
          )).thenAnswer((_) async {});
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async {
        loadCount++;
        return [];
      });

      final container = ProviderContainer(
        overrides: [
          supportTicketRepositoryProvider.overrideWithValue(mockRepo),
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

      container.read(supportTicketProvider);
      await Future.delayed(Duration.zero);
      final afterInit = loadCount;

      await container.read(supportTicketProvider.notifier).updateStatus(
        ticketId: 'ticket-abc12345',
        status: 'in_progress',
      );

      expect(loadCount, greaterThan(afterInit));
    });
  });

  // ─── SupportTicketState.copyWith ───────────────────────────────────────────

  group('SupportTicketState.copyWith', () {
    test('preserves tickets when not overridden', () {
      final tickets = [
        {'id': 'ticket-abcde123', 'subject': 'Old Issue'}
      ];
      final state = SupportTicketState(tickets: tickets);
      final copied = state.copyWith(isLoading: true);
      expect(copied.tickets, tickets);
    });

    test('resets error to null when not provided', () {
      const state = SupportTicketState(error: 'some error message');
      final copied = state.copyWith(isLoading: false);
      expect(copied.error, isNull);
    });

    test('resets submitSuccess to false when not provided', () {
      const state = SupportTicketState(submitSuccess: true);
      final copied = state.copyWith(isLoading: false);
      expect(copied.submitSuccess, false);
    });

    test('updates tickets when provided', () {
      const initial = SupportTicketState();
      final newTickets = [
        {'id': 'new-ticket-1', 'subject': 'New Issue'}
      ];
      final updated = initial.copyWith(tickets: newTickets);
      expect(updated.tickets, newTickets);
    });

    test('updates isSubmitting independently from isLoading', () {
      const state = SupportTicketState(isLoading: false, isSubmitting: false);
      final submitting = state.copyWith(isSubmitting: true);
      expect(submitting.isSubmitting, true);
      expect(submitting.isLoading, false);
    });

    test('default state has correct initial values', () {
      const state = SupportTicketState();
      expect(state.tickets, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSubmitting, false);
      expect(state.error, isNull);
      expect(state.submitSuccess, false);
    });
  });
}
