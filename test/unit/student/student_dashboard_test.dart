import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/presentation/student/student_home_screen.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/recent_campus_incidents_provider.dart';

class MockStudentAuthController extends AuthController {
  MockStudentAuthController({this.customProfile});

  final UserProfile? customProfile;

  @override
  AuthState build() {
    final now = DateTime.now();
    final profile = customProfile ??
        UserProfile(
          uid: 'student-123',
          displayName: 'Aline Mugisha',
          email: 'a.mugisha@alustudent.com',
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

Widget _buildHomeScreen({UserProfile? customProfile}) {
  return ProviderScope(
    overrides: [
      authControllerProvider
          .overrideWith(() => MockStudentAuthController(customProfile: customProfile)),
      recentCampusIncidentsProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const StudentHomeScreen(),
    ),
  );
}

void main() {
  group('StudentHomeScreen Dashboard', () {
    testWidgets('renders greeting, report action, shortcuts, and static sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Hello, Aline'), findsOneWidget);
      expect(find.text('Report a Campus Issue'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('Recent Campus Reports'), findsOneWidget);
      expect(find.text('How CampusCare Works'), findsOneWidget);
    });

    testWidgets('gracefully handles missing or blank display name',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final blankProfile = UserProfile(
        uid: 'student-456',
        displayName: '',
        email: 'blank@alustudent.com',
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(_buildHomeScreen(customProfile: blankProfile));
      await tester.pumpAndSettle();

      expect(find.text('Hello, ALU Student'), findsOneWidget);
      expect(find.text('Report a Campus Issue'), findsOneWidget);
      expect(find.text('Recent Campus Reports'), findsOneWidget);
    });
  });
}

