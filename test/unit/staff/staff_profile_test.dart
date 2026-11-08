import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/profile/presentation/staff_profile_screen.dart';

class MockStaffProfileAuthController extends AuthController {
  bool signOutCalled = false;

  @override
  AuthState build() {
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'staff-profile-100',
      displayName: 'Aline Umutoni',
      email: 'a.umutoni@alueducation.com',
      role: UserRole.staff,
      createdAt: now,
      updatedAt: now,
    );

    return AuthState(
      status: AuthStatus.authenticatedStaff,
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
  group('StaffProfileScreen', () {
    testWidgets('renders profile details and staff role badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => MockStaffProfileAuthController()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aline Umutoni'), findsNWidgets(2));
      expect(find.text('a.umutoni@alueducation.com'), findsNWidgets(2));
      expect(find.text('Staff'), findsNWidgets(2)); // Role badge + Account Details row
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(
        find.text(
          'Authorized campus staff account with access to triage reports, update resolution progress, and coordinate campus operations.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('triggers sign out on button tap', (WidgetTester tester) async {
      final mockController = MockStaffProfileAuthController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => mockController),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffProfileScreen(),
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

