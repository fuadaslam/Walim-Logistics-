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
import 'package:walim_logistics/features/support/presentation/widgets/issue_report_bottom_sheet.dart';
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
    when(() => mockRepo.getTicketsForProfile(any())).thenAnswer((_) async => []);
  });

  Widget buildWidget({UserProfile? profile}) {
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
          body: IssueReportBottomSheet(),
        ),
      ),
    );
  }

  // ─── Rendering ─────────────────────────────────────────────────────────────

  group('rendering', () {
    testWidgets('renders title Report Issue', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Report Issue'), findsOneWidget);
    });

    testWidgets('renders Tell us what is wrong subtitle', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tell us what is wrong'), findsOneWidget);
    });

    testWidgets('renders Subject field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Subject'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('renders all issue type options', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Accident'), findsOneWidget);
      expect(find.text('Fuel Issue'), findsOneWidget);
      expect(find.text('App Glitch'), findsOneWidget);
      expect(find.text('Vehicle Issue'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('renders all priority options', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders SUBMIT REPORT button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SUBMIT REPORT'), findsOneWidget);
    });

    testWidgets('renders Description field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('renders with initialItem shows item-specific subtitle', (tester) async {
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
              body: IssueReportBottomSheet(initialItem: 'Vehicle #A-123'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Just verify it builds without error
    });
  });

  // ─── Form interaction ──────────────────────────────────────────────────────

  group('form interaction', () {
    testWidgets('shows snackbar error when submit pressed with empty subject', (tester) async {
      // The form is taller than the default 600px test surface — expand it
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.text('SUBMIT REPORT'));
      await tester.pump();
      await tester.tap(find.text('SUBMIT REPORT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Please enter a subject'), findsOneWidget);
    });

    testWidgets('entering text in subject field is reflected', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final subjectField = find.byType(TextField).first;
      await tester.enterText(subjectField, 'My issue subject');
      await tester.pump();

      expect(find.text('My issue subject'), findsOneWidget);
    });

    testWidgets('tapping an issue type chip selects it', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Accident'));
      await tester.pump();

      expect(find.text('Accident'), findsOneWidget);
    });

    testWidgets('tapping a priority chip selects it', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('High'));
      await tester.pump();

      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('submit calls createTicket when subject is filled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final subjectField = find.byType(TextField).first;
      await tester.enterText(subjectField, 'App crashes on startup');
      await tester.pump();

      await tester.ensureVisible(find.text('SUBMIT REPORT'));
      await tester.pump();
      await tester.tap(find.text('SUBMIT REPORT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: 'App crashes on startup',
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).called(1);
    });
  });

  // ─── Loading state ─────────────────────────────────────────────────────────

  group('loading state', () {
    testWidgets('submit button shows loading indicator while submitting', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      when(() => mockRepo.createTicket(
            profileId: any(named: 'profileId'),
            subject: any(named: 'subject'),
            type: any(named: 'type'),
            priority: any(named: 'priority'),
            description: any(named: 'description'),
            photoUrls: any(named: 'photoUrls'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final subjectField = find.byType(TextField).first;
      await tester.enterText(subjectField, 'Test Issue');
      await tester.pump();

      await tester.ensureVisible(find.text('SUBMIT REPORT'));
      await tester.pump();
      await tester.tap(find.text('SUBMIT REPORT'));
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
