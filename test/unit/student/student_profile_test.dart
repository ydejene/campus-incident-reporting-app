import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/profile/presentation/student_profile_screen.dart';

class MockProfileAuthController extends AuthController {
  bool signOutCalled = false;

  @override
  AuthState build() {
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'student-999',
      displayName: 'Kagabo Eric',
      email: 'e.kagabo@alustudent.com',
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
    );

    return AuthState(
      status: AuthStatus.authenticatedStudent,
      profile: profile,
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = AuthState.unauthenticated();
  }
}

void main() {
  group('StudentProfileScreen', () {
    testWidgets('renders profile details and student role badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => MockProfileAuthController()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kagabo Eric'), findsNWidgets(2)); // Header and detail row
      expect(find.text('e.kagabo@alustudent.com'), findsNWidgets(2));
      expect(find.text('Student Account'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('triggers sign out on button tap', (WidgetTester tester) async {
      final mockController = MockProfileAuthController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => mockController),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Sign Out');
      expect(signOutBtn, findsOneWidget);

      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(mockController.signOutCalled, isTrue);
    });
  });
}

