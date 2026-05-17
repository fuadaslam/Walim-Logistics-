// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:walim_logistics/features/auth/data/auth_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
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

UserProfile _makeProfile({String id = 'user-001'}) => UserProfile(
      id: id,
      role: 'Rider',
      fullName: 'Test Rider',
      status: 'active',
    );

Map<String, dynamic> _makeTicket({
  String id = 'abcdefgh12345678',
  String subject = 'Test Issue',
  String status = 'open',
  String priority = 'normal',
  String? description,
}) =>
    {
      'id': id,
      'subject': subject,
      'status': status,
      'priority': priority,
      'description': description ?? 'Issue description here',
      'type': 'other',
      'created_at': '2025-01-15T10:30:00Z',
      'profile_id': 'user-001',
    };

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

  Widget buildWidget({
    List<Map<String, dynamic>> tickets = const [],
    UserProfile? profile,
  }) {
    when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => tickets);
    return ProviderScope(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(mockRepo),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            profile: profile ?? _makeProfile(),
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
    );
  }

  // ─── Rendering ─────────────────────────────────────────────────────────────

  group('rendering', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // No exception = pass
    });

    testWidgets('shows New Ticket button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Ticket'), findsOneWidget);
    });

    testWidgets('shows filter tab labels', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      // "Resolved" appears in both the stats card and the filter tab
      expect(find.text('Resolved'), findsWidgets);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('shows empty state when no tickets', (tester) async {
      await tester.pumpWidget(buildWidget(tickets: []));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No tickets found'), findsOneWidget);
    });

    testWidgets('shows ticket subject when tickets are present', (tester) async {
      final tickets = [
        _makeTicket(subject: 'App is crashing on launch'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('App is crashing on launch'), findsOneWidget);
    });

    testWidgets('shows all tickets in the list', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'First Issue'),
        _makeTicket(id: 'bbbbbbbb22222222', subject: 'Second Issue'),
        _makeTicket(id: 'cccccccc33333333', subject: 'Third Issue'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First Issue'), findsOneWidget);
      expect(find.text('Second Issue'), findsOneWidget);
      expect(find.text('Third Issue'), findsOneWidget);
    });
  });

  // ─── Stats row ─────────────────────────────────────────────────────────────

  group('stats row', () {
    testWidgets('shows correct total ticket count', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', status: 'open'),
        _makeTicket(id: 'bbbbbbbb22222222', status: 'resolved'),
        _makeTicket(id: 'cccccccc33333333', status: 'in_progress'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      // Total count: "3"
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('shows zero counts when no tickets', (tester) async {
      await tester.pumpWidget(buildWidget(tickets: []));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0'), findsWidgets);
    });
  });

  // ─── Filter tabs ───────────────────────────────────────────────────────────
  //
  // Filter tabs live inside the only horizontal SingleChildScrollView on the
  // screen.  Using an ancestor-scoped finder avoids ambiguity with:
  //   • "Resolved" / "Open" labels in the stats cards
  //   • "Open" / "Resolved" / "Closed" status chips on ticket cards
  //
  Finder filterTab(String label) => find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
        ),
        matching: find.text(label),
      );

  group('filter tabs', () {
    testWidgets('tapping Open filter shows only open tickets', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'Open Ticket', status: 'open'),
        _makeTicket(id: 'bbbbbbbb22222222', subject: 'Resolved Ticket', status: 'resolved'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(filterTab('Open'));
      await tester.pump();

      expect(find.text('Open Ticket'), findsOneWidget);
      expect(find.text('Resolved Ticket'), findsNothing);
    });

    testWidgets('tapping Resolved filter shows only resolved tickets', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'Active Ticket', status: 'open'),
        _makeTicket(id: 'bbbbbbbb22222222', subject: 'Done Ticket', status: 'resolved'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(filterTab('Resolved'));
      await tester.pump();

      expect(find.text('Done Ticket'), findsOneWidget);
      expect(find.text('Active Ticket'), findsNothing);
    });

    testWidgets('All filter shows all tickets', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'Open Ticket', status: 'open'),
        _makeTicket(id: 'bbbbbbbb22222222', subject: 'Resolved Ticket', status: 'resolved'),
        _makeTicket(id: 'cccccccc33333333', subject: 'Closed Ticket', status: 'closed'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      // All is the default — all tickets should be visible
      expect(find.text('Open Ticket'), findsOneWidget);
      expect(find.text('Resolved Ticket'), findsOneWidget);
      expect(find.text('Closed Ticket'), findsOneWidget);
    });

    testWidgets('shows empty state when filter matches no tickets', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'Open Ticket', status: 'open'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap "Resolved" filter — no resolved tickets exist
      await tester.tap(filterTab('Resolved'));
      await tester.pump();

      expect(find.text('No tickets found'), findsOneWidget);
      expect(find.text('Open Ticket'), findsNothing);
    });

    testWidgets('switching filters back to All shows all tickets again', (tester) async {
      final tickets = [
        _makeTicket(id: 'aaaaaaaa11111111', subject: 'Open Ticket', status: 'open'),
        _makeTicket(id: 'bbbbbbbb22222222', subject: 'Resolved Ticket', status: 'resolved'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(filterTab('Open'));
      await tester.pump();
      expect(find.text('Resolved Ticket'), findsNothing);

      await tester.tap(filterTab('All'));
      await tester.pump();

      expect(find.text('Open Ticket'), findsOneWidget);
      expect(find.text('Resolved Ticket'), findsOneWidget);
    });
  });

  // ─── Ticket card details ────────────────────────────────────────────────────

  group('ticket card', () {
    testWidgets('shows ticket ID (first 8 chars uppercased)', (tester) async {
      final tickets = [
        _makeTicket(id: 'abcdef1234567890', subject: 'UI Bug'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      // First 8 chars of 'abcdef1234567890' uppercased = 'ABCDEF12'
      expect(find.textContaining('ABCDEF12'), findsOneWidget);
    });

    testWidgets('shows View Conversation button for each ticket', (tester) async {
      final tickets = [
        _makeTicket(id: 'abcdef1234567890', subject: 'Issue One'),
      ];
      await tester.pumpWidget(buildWidget(tickets: tickets));
      await tester.pump(const Duration(milliseconds: 100));

      // On narrow screen: "Conversation"; on wide: "View Conversation"
      expect(
        find.textContaining('Conversation'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
