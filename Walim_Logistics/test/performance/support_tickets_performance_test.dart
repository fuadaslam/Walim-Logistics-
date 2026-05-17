// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:walim_logistics/features/auth/data/auth_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/requests/presentation/request_notifier.dart';
import 'package:walim_logistics/features/support/data/support_ticket_repository.dart';
import 'package:walim_logistics/features/support/presentation/support_ticket_notifier.dart';
import 'package:walim_logistics/features/support/presentation/support_tickets_screen.dart';
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

UserProfile _makeProfile() => UserProfile(
      id: 'user-001',
      role: 'Rider',
      fullName: 'Perf Test Rider',
      status: 'active',
    );

List<Map<String, dynamic>> _generateTickets(int count) {
  final statuses = ['open', 'in_progress', 'resolved', 'closed'];
  final priorities = ['low', 'normal', 'high'];
  return List.generate(count, (i) {
    final id = 'ticket${i.toString().padLeft(12, '0')}';
    return {
      'id': id,
      'subject': 'Performance Test Issue $i',
      'description': 'Description for issue number $i with some extra text to simulate real data',
      'status': statuses[i % statuses.length],
      'priority': priorities[i % priorities.length],
      'type': 'other',
      'created_at': '2025-01-${(i % 28 + 1).toString().padLeft(2, '0')}T10:30:00Z',
      'profile_id': 'user-001',
    };
  });
}

void main() {
  late MockSupportTicketRepository mockRepo;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseClient mockSupabase;
  late MockAuthRepository mockAuthRepo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    mockRepo = MockSupportTicketRepository();
    mockGoTrue = MockGoTrueClient();
    mockSupabase = MockSupabaseClient();
    mockAuthRepo = MockAuthRepository();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.currentUser).thenReturn(null);
    when(() => mockGoTrue.onAuthStateChange).thenAnswer((_) => Stream.empty());
  });

  // ─── Dart-level benchmarks (no Flutter required) ───────────────────────────

  group('SupportTicketState performance', () {
    test('copyWith 10 000 times completes in under 1 second', () {
      final tickets = _generateTickets(500);
      final state = SupportTicketState(tickets: tickets);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        state.copyWith(isLoading: i.isEven, isSubmitting: i.isOdd);
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: '10 000 copyWith calls took ${sw.elapsedMilliseconds}ms — too slow');
    });

    test('filtering 1000 tickets by status runs 500 times in under 500ms', () {
      final tickets = _generateTickets(1000);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 500; i++) {
        tickets.where((t) => t['status'] == 'open').toList();
        tickets.where((t) => t['status'] == 'resolved').toList();
        tickets.where((t) => t['status'] == 'in_progress').toList();
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500),
          reason: '1500 filter passes on 1000 items took ${sw.elapsedMilliseconds}ms');
    });

    test('building RequestState with 1000 requests is fast', () {
      final requests = List.generate(
        1000,
        (i) => {'id': 'req${i.toString().padLeft(12, '0')}', 'status': 'pending'},
      );

      final sw = Stopwatch()..start();
      RequestState state = const RequestState();
      for (var i = 0; i < 1000; i++) {
        state = state.copyWith(requests: requests, isLoading: false);
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
      expect(state.requests.length, 1000);
    });
  });

  group('ticket data processing performance', () {
    test('counting tickets by status in large list is fast', () {
      final tickets = _generateTickets(5000);

      final sw = Stopwatch()..start();
      for (var run = 0; run < 100; run++) {
        final active = tickets
            .where((t) => t['status'] != 'resolved' && t['status'] != 'closed')
            .length;
        final resolved = tickets.where((t) => t['status'] == 'resolved').length;
        // Prevent compiler from optimizing away
        expect(active + resolved, greaterThan(0));
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: '100 count passes on 5000 tickets took ${sw.elapsedMilliseconds}ms');
    });

    test('date formatting for 1000 tickets is fast', () {
      final tickets = _generateTickets(1000);

      String formatDate(dynamic raw) {
        if (raw == null) return '';
        try {
          final dt = DateTime.parse(raw.toString()).toLocal();
          return '${dt.day} ${dt.month}, '
              '${dt.hour.toString().padLeft(2, '0')}:'
              '${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          return '';
        }
      }

      final sw = Stopwatch()..start();
      for (final ticket in tickets) {
        formatDate(ticket['created_at']);
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(200),
          reason: 'Formatting 1000 dates took ${sw.elapsedMilliseconds}ms');
    });

    test('ID substring for 1000 tickets is fast', () {
      final tickets = _generateTickets(1000);

      final sw = Stopwatch()..start();
      for (final ticket in tickets) {
        ticket['id'].toString().substring(0, 8).toUpperCase();
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  // ─── Widget-level performance ───────────────────────────────────────────────

  group('widget rendering performance', () {
    testWidgets('renders 50 ticket cards without layout overflow', (tester) async {
      final tickets = _generateTickets(50);
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(showScaffold: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the widget built without error and shows at least one ticket
      expect(find.textContaining('Performance Test Issue'), findsWidgets);
    });

    testWidgets('filter tap on 100 tickets completes within one frame', (tester) async {
      final tickets = _generateTickets(100);
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(showScaffold: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Scope to the horizontal filter tab row to avoid status chip ambiguity
      final filterRow = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      final openTab = find.descendant(of: filterRow, matching: find.text('Open'));

      final sw = Stopwatch()..start();
      await tester.tap(openTab);
      await tester.pump();
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('empty state renders quickly with large ticket count then filter', (tester) async {
      // All tickets are 'open', so tapping 'Resolved' shows empty state
      final tickets = _generateTickets(200)
          .map((t) => {...t, 'status': 'open'})
          .toList();
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(showScaffold: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final filterRow = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      await tester.tap(find.descendant(of: filterRow, matching: find.text('Resolved')));
      await tester.pump();

      expect(find.text('No tickets found'), findsOneWidget);
    });

    testWidgets('rapid filter switching does not throw', (tester) async {
      final tickets = _generateTickets(30);
      when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(showScaffold: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Scope all taps to the horizontal filter tab row
      final filterRow = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      for (final tab in ['Open', 'Resolved', 'Closed', 'In Progress', 'All']) {
        await tester.tap(find.descendant(of: filterRow, matching: find.text(tab)));
        await tester.pump();
      }

      expect(find.text('No tickets found'), findsNothing);
    });
  });
}
