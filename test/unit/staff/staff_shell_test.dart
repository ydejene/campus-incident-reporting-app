import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_incident_reporting_app/app/router/app_router.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/application/staff_dashboard_controller.dart';
import 'package:campus_incident_reporting_app/features/dashboard/domain/models/staff_dashboard_statistics.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/staff/staff_shell_screen.dart';

class MockStaffShellAuthController extends AuthController {
  @override
  AuthState build() {
    final now = DateTime.now();
    return AuthState(
      status: AuthStatus.authenticatedStaff,
      profile: UserProfile(
        uid: 'staff-shell-1',
        displayName: 'Jean Claude',
        email: 'j.claude@alueducation.com',
        role: UserRole.staff,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class MockStudentAuthControllerForStaffShell extends AuthController {
  @override
  AuthState build() {
    final now = DateTime.now();
    return AuthState(
      status: AuthStatus.authenticatedStudent,
      profile: UserProfile(
        uid: 'student-shell-user',
        displayName: 'Student Jane',
        email: 'jane@alustudent.com',
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class MockEmptyStaffDashboardController extends StaffDashboardController {
  @override
  StaffDashboardState build() {
    return const StaffDashboardState(
      statistics: StaffDashboardStatistics(
        totalIncidents: 0,
        submittedIncidents: 0,
        inProgressIncidents: 0,
        resolvedIncidents: 0,
      ),
    );
  }
}

void main() {
  group('StaffShellScreen Navigation', () {
    testWidgets('renders all 3 staff destinations in navigation bar and switches tabs',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/staff',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return StaffShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/staff',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Staff Dashboard Content')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/staff/incidents',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Staff Incidents Content')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/staff/profile',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Staff Profile Content')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => MockStaffShellAuthController()),
            staffDashboardControllerProvider
                .overrideWith(() => MockEmptyStaffDashboardController()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Dashboard'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Incidents'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );

      // Initially on Dashboard
      expect(find.text('Staff Dashboard Content'), findsOneWidget);

      // Tap Incidents tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Incidents'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Incidents Content'), findsOneWidget);

      // Tap Profile tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Profile Content'), findsOneWidget);

      // Tap Dashboard tab to return
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Dashboard'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Dashboard Content'), findsOneWidget);
    });

    testWidgets('student attempting to access /staff is redirected to /student',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => MockStudentAuthControllerForStaffShell()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Student starts on /student
      expect(router.routeInformationProvider.value.uri.path, '/student');

      // Attempt navigating directly to /staff
      router.go('/staff');
      await tester.pumpAndSettle();

      // Guard redirects back to /student
      expect(router.routeInformationProvider.value.uri.path, '/student');
    });

    testWidgets('staff attempting to access /student is redirected to /staff',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => MockStaffShellAuthController()),
          staffDashboardControllerProvider
              .overrideWith(() => MockEmptyStaffDashboardController()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Staff starts on /staff
      expect(router.routeInformationProvider.value.uri.path, '/staff');

      // Attempt navigating to /student
      router.go('/student');
      await tester.pumpAndSettle();

      // Guard redirects back to /staff
      expect(router.routeInformationProvider.value.uri.path, '/staff');
    });
  });
}

