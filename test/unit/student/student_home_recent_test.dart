import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/student/student_home_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/recent_campus_incidents_provider.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';

class _MockAuthController extends AuthController {
  @override
  AuthState build() {
    final now = DateTime.now();
    return AuthState(
      status: AuthStatus.authenticatedStudent,
      profile: UserProfile(
        uid: 'student-recent-test',
        displayName: 'Test Student',
        email: 'test@alustudent.com',
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

List<Incident> _threeIncidents() {
  final now = DateTime.now();
  return [
    Incident(
      id: 'alpha',
      description: 'Broken window in lecture hall',
      category: IncidentCategory.facilities,
      building: 'Academic Block',
      block: 'A',
      specificArea: 'Room 101',
      createdBy: 'uid-a',
      status: IncidentStatus.submitted,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
    Incident(
      id: 'beta',
      description: 'Water leak near cafeteria',
      category: IncidentCategory.waterSupply,
      building: 'Main Building',
      block: 'B',
      specificArea: 'Corridor',
      createdBy: 'uid-b',
      status: IncidentStatus.underReview,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    Incident(
      id: 'gamma',
      description: 'Power outage in lab',
      category: IncidentCategory.electricity,
      building: 'Science Block',
      block: 'C',
      specificArea: 'Lab 3',
      createdBy: 'uid-c',
      status: IncidentStatus.inProgress,
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 4)),
    ),
  ];
}

/// Pumps [StudentHomeScreen] with both auth and [recentCampusIncidentsProvider] overridden.
///
/// [incidents] controls the data the provider returns.
/// [recentOverride] overrides the entire provider future when provided, taking
/// precedence over [incidents].
Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  List<Incident>? incidents,
  Future<List<Incident>> Function()? recentOverride,
  GoRouter? router,
}) async {
  final providerOverride = recentOverride != null
      ? recentCampusIncidentsProvider.overrideWith((ref) => recentOverride())
      : recentCampusIncidentsProvider.overrideWith(
          (ref) async => incidents ?? [],
        );

  if (router != null) {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _MockAuthController()),
          providerOverride,
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
  } else {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _MockAuthController()),
          providerOverride,
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StudentHomeScreen(),
        ),
      ),
    );
  }
}

void main() {
  group('Recent Campus Reports — section header', () {
    testWidgets('displays "Recent Campus Reports" heading', (tester) async {
      await _pumpHomeScreen(tester, incidents: []);
      await tester.pumpAndSettle();

      expect(find.text('Recent Campus Reports'), findsOneWidget);
    });

    testWidgets('"View all" button is present', (tester) async {
      await _pumpHomeScreen(tester, incidents: []);
      await tester.pumpAndSettle();

      expect(find.text('View all'), findsOneWidget);
    });
  });

  group('Recent Campus Reports — loading state', () {
    testWidgets('shows LinearProgressIndicator while provider is loading',
        (tester) async {
      final completer = Completer<List<Incident>>();
      await _pumpHomeScreen(
        tester,
        recentOverride: () => completer.future,
      );
      // Single pump — provider still pending.
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('Recent Campus Reports — empty state', () {
    testWidgets('shows "No campus reports yet" when no incidents exist',
        (tester) async {
      await _pumpHomeScreen(tester, incidents: []);
      await tester.pumpAndSettle();

      expect(find.text('No campus reports yet'), findsOneWidget);
    });
  });

  group('Recent Campus Reports — error state', () {
    testWidgets('shows error message and Retry button on failure',
        (tester) async {
      await _pumpHomeScreen(
        tester,
        recentOverride: () => Future.error(Exception('network error')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load recent reports'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Recent Campus Reports — data state', () {
    testWidgets('renders all three incident cards', (tester) async {
      await _pumpHomeScreen(tester, incidents: _threeIncidents());
      await tester.pumpAndSettle();

      expect(find.text('Broken window in lecture hall'), findsOneWidget);
      expect(find.text('Water leak near cafeteria'), findsOneWidget);
      expect(find.text('Power outage in lab'), findsOneWidget);
    });

    testWidgets('does not show empty-state text when incidents are present',
        (tester) async {
      await _pumpHomeScreen(tester, incidents: _threeIncidents());
      await tester.pumpAndSettle();

      expect(find.text('No campus reports yet'), findsNothing);
    });
  });

  group('Recent Campus Reports — navigation', () {
    testWidgets('"View all" navigates to /student/browse', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? pushedLocation;

      final router = GoRouter(
        initialLocation: '/student',
        routes: [
          GoRoute(
            path: '/student',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: '/student/browse',
            builder: (context, state) {
              pushedLocation = '/student/browse';
              return const Scaffold(body: Text('Browse Screen'));
            },
          ),
          GoRoute(
            path: '/student/my-reports',
            builder: (context, state) =>
                const Scaffold(body: Text('My Reports')),
          ),
          GoRoute(
            path: '/student/report',
            builder: (context, state) =>
                const Scaffold(body: Text('Report Screen')),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('Profile Screen')),
          ),
        ],
      );

      await _pumpHomeScreen(tester, incidents: [], router: router);
      await tester.pumpAndSettle();

      final viewAllFinder = find.text('View all');
      await tester.ensureVisible(viewAllFinder);
      await tester.tap(viewAllFinder);
      await tester.pumpAndSettle();

      expect(pushedLocation, '/student/browse');
      expect(find.text('Browse Screen'), findsOneWidget);
    });

    testWidgets('tapping an incident card navigates to /incident/{id}',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? navigatedPath;

      final incidents = _threeIncidents();

      final router = GoRouter(
        initialLocation: '/student',
        routes: [
          GoRoute(
            path: '/student',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: '/student/browse',
            builder: (context, state) =>
                const Scaffold(body: Text('Browse Screen')),
          ),
          GoRoute(
            path: '/student/my-reports',
            builder: (context, state) =>
                const Scaffold(body: Text('My Reports')),
          ),
          GoRoute(
            path: '/student/report',
            builder: (context, state) =>
                const Scaffold(body: Text('Report Screen')),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('Profile Screen')),
          ),
          GoRoute(
            path: '/incident/:id',
            builder: (context, state) {
              navigatedPath = '/incident/${state.pathParameters['id']}';
              return Scaffold(
                body: Text('Incident ${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      await _pumpHomeScreen(tester, incidents: incidents, router: router);
      await tester.pumpAndSettle();

      // Tap the first card — incident id 'alpha'
      final cardFinder = find.text('Broken window in lecture hall');
      await tester.ensureVisible(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(navigatedPath, '/incident/alpha');
    });
  });
}
