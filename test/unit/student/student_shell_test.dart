import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/student/student_shell_screen.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/student/student_home_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/student_browse_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/student_my_reports_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/student_report_screen.dart';
import 'package:campus_incident_reporting_app/features/profile/presentation/student_profile_screen.dart';

class MockStudentShellAuthController extends AuthController {
  @override
  AuthState build() {
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'student-shell-user',
      displayName: 'Shell Student',
      email: 'shell@alustudent.com',
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
    );

    return AuthState(
      status: AuthStatus.authenticatedStudent,
      profile: profile,
    );
  }
}

void main() {
  group('StudentShellScreen Navigation', () {
    testWidgets('renders all 5 student destinations in navigation bar',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/student',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return StudentShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/student',
                    builder: (context, state) => const StudentHomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/student/browse',
                    builder: (context, state) => const StudentBrowseScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/student/report',
                    builder: (context, state) => const StudentReportScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/student/my-reports',
                    builder: (context, state) => const StudentMyReportsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/student/profile',
                    builder: (context, state) => const StudentProfileScreen(),
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
                .overrideWith(() => MockStudentShellAuthController()),
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
          matching: find.text('Home'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Browse'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Report'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('My Reports'),
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

      // Verify initial tab is Home
      expect(find.text('Hello, Shell'), findsOneWidget);

      // Tap Browse tab in NavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Browse'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Browse Campus Incidents'), findsOneWidget);

      // Tap Report tab in NavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Report'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Report an Issue'), findsOneWidget);

      // Tap My Reports tab in NavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('My Reports'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Personal report history & tracking'), findsOneWidget);

      // Tap Profile tab in NavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account Details'), findsOneWidget);
    });
  });
}

