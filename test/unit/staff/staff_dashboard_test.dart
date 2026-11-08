import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/application/staff_dashboard_controller.dart';
import 'package:campus_incident_reporting_app/features/dashboard/domain/models/staff_dashboard_statistics.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/staff/staff_dashboard_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';

class _MockStaffAuthController extends AuthController {
  @override
  AuthState build() {
    final now = DateTime.now();
    return AuthState(
      status: AuthStatus.authenticatedStaff,
      profile: UserProfile(
        uid: 'staff-123',
        displayName: 'Jean Claude',
        email: 'j.claude@alueducation.com',
        role: UserRole.staff,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _MockStaffDashboardController extends StaffDashboardController {
  _MockStaffDashboardController(this._initialState);

  final StaffDashboardState _initialState;

  @override
  StaffDashboardState build() => _initialState;
}

List<Incident> _sampleIncidents() {
  final now = DateTime.now();
  return [
    Incident(
      id: 'inc-staff-1',
      description: 'Water pipe leaking in laboratory',
      category: IncidentCategory.waterSupply,
      building: 'Science Center',
      block: 'B',
      specificArea: 'Lab 201',
      createdBy: 'student-1',
      status: IncidentStatus.submitted,
      createdAt: now.subtract(const Duration(minutes: 30)),
      updatedAt: now.subtract(const Duration(minutes: 30)),
    ),
    Incident(
      id: 'inc-staff-2',
      description: 'Broken window latch in study room',
      category: IncidentCategory.facilities,
      building: 'Main Hall',
      block: 'A',
      specificArea: 'Study room 3',
      createdBy: 'student-2',
      status: IncidentStatus.inProgress,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
  ];
}

Widget _buildStaffDashboard({
  required StaffDashboardState dashboardState,
  GoRouter? router,
}) {
  final overrides = [
    authControllerProvider.overrideWith(() => _MockStaffAuthController()),
    staffDashboardControllerProvider.overrideWith(
      () => _MockStaffDashboardController(dashboardState),
    ),
  ];

  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const StaffDashboardScreen(),
    ),
  );
}

void main() {
  group('StaffDashboardScreen', () {
    testWidgets('renders staff profile avatar button in app bar', (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(
            statistics: StaffDashboardStatistics(
              totalIncidents: 10,
              submittedIncidents: 3,
              inProgressIncidents: 4,
              resolvedIncidents: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('Staff Admin'), findsNothing);
      expect(find.text('Campus Incident Overview'), findsOneWidget);
    });

    testWidgets('tapping profile button navigates to /staff/profile',
        (tester) async {
      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/staff',
        routes: [
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffDashboardScreen(),
          ),
          GoRoute(
            path: '/staff/profile',
            builder: (context, state) {
              pushedRoute = '/staff/profile';
              return const Scaffold(body: Text('Staff Profile View'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/staff/profile');
      expect(find.text('Staff Profile View'), findsOneWidget);
    });

    testWidgets('renders accurate incident statistics counts', (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(
            statistics: StaffDashboardStatistics(
              totalIncidents: 42,
              submittedIncidents: 12,
              inProgressIncidents: 8,
              resolvedIncidents: 22,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Awaiting Review'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('shows loading indicator while statistics are loading',
        (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(isLoading: true),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry action on failure',
        (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(
            errorMessage: 'Network timeout loading statistics',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load incident statistics'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders empty state when no incidents exist', (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(
            statistics: StaffDashboardStatistics.empty,
            recentIncidents: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No incidents reported yet'), findsOneWidget);
    });

    testWidgets('renders recent incident cards when available', (tester) async {
      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: StaffDashboardState(
            statistics: const StaffDashboardStatistics(
              totalIncidents: 2,
              submittedIncidents: 1,
              inProgressIncidents: 1,
              resolvedIncidents: 0,
            ),
            recentIncidents: _sampleIncidents(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Water pipe leaking in laboratory'), findsOneWidget);
      expect(find.text('Broken window latch in study room'), findsOneWidget);
      expect(find.text('No incidents reported yet'), findsNothing);
    });

    testWidgets('Manage Incidents card navigates to /staff/incidents',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/staff',
        routes: [
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffDashboardScreen(),
          ),
          GoRoute(
            path: '/staff/incidents',
            builder: (context, state) {
              pushedRoute = '/staff/incidents';
              return const Scaffold(body: Text('Staff Incidents View'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: const StaffDashboardState(),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      final manageBtn = find.text('Manage Campus Incidents');
      await tester.ensureVisible(manageBtn);
      await tester.tap(manageBtn);
      await tester.pumpAndSettle();

      expect(pushedRoute, '/staff/incidents');
      expect(find.text('Staff Incidents View'), findsOneWidget);
    });

    testWidgets('tapping an incident card navigates to /incident/:id',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? openedIncidentId;
      final router = GoRouter(
        initialLocation: '/staff',
        routes: [
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffDashboardScreen(),
          ),
          GoRoute(
            path: '/incident/:id',
            builder: (context, state) {
              openedIncidentId = state.pathParameters['id'];
              return Scaffold(body: Text('Detail $openedIncidentId'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _buildStaffDashboard(
          dashboardState: StaffDashboardState(
            recentIncidents: _sampleIncidents(),
          ),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      final firstCard = find.text('Water pipe leaking in laboratory');
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(openedIncidentId, 'inc-staff-1');
      expect(find.text('Detail inc-staff-1'), findsOneWidget);
    });
  });
}

