import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';

void main() {
  group('AuthState', () {
    test('initial factory sets initial status and loading', () {
      final state = AuthState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.isLoading, isTrue);
      expect(state.user, isNull);
      expect(state.profile, isNull);
    });

    test('unauthenticated factory sets status and optional error', () {
      final state = AuthState.unauthenticated('Invalid credentials');
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Invalid credentials');
      expect(state.isLoading, isFalse);
    });

    test('authenticatedStudent factory binds user profile correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'user-001',
        displayName: 'John Student',
        email: 'john@alustudent.com',
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      );

      final state = AuthState(
        status: AuthStatus.authenticatedStudent,
        profile: profile,
      );

      expect(state.status, AuthStatus.authenticatedStudent);
      expect(state.profile?.role, UserRole.student);
      expect(state.profile?.email, 'john@alustudent.com');
    });

    test('authenticatedStaff factory binds staff role correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'staff-001',
        displayName: 'Dr. Facilitator',
        email: 'facilitator@alueducation.com',
        role: UserRole.staff,
        createdAt: now,
        updatedAt: now,
      );

      final state = AuthState(
        status: AuthStatus.authenticatedStaff,
        profile: profile,
      );

      expect(state.status, AuthStatus.authenticatedStaff);
      expect(state.profile?.role, UserRole.staff);
    });

    test('unverified and staffPendingApproval factory states', () {
      final unverifiedState = AuthState(
        status: AuthStatus.unverified,
      );
      expect(unverifiedState.status, AuthStatus.unverified);

      final pendingState = AuthState(
        status: AuthStatus.staffPendingApproval,
      );
      expect(pendingState.status, AuthStatus.staffPendingApproval);
    });

    test('copyWith updates state attributes immutably', () {
      final state = AuthState.initial();
      final updated = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Connection lost',
      );

      expect(updated.status, AuthStatus.unauthenticated);
      expect(updated.isLoading, isFalse);
      expect(updated.errorMessage, 'Connection lost');
      expect(state.status, AuthStatus.initial);
    });
  });
}

