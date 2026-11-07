import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/user_profile.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  unverified,
  authenticatedStudent,
  authenticatedStaff,
  staffPendingApproval,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.profile,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isLoading;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial, isLoading: true);

  factory AuthState.unauthenticated([String? errorMessage]) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );

  factory AuthState.unverified(User user) => AuthState(
        status: AuthStatus.unverified,
        user: user,
      );

  factory AuthState.authenticatedStudent({
    required User user,
    required UserProfile profile,
  }) =>
      AuthState(
        status: AuthStatus.authenticatedStudent,
        user: user,
        profile: profile,
      );

  factory AuthState.authenticatedStaff({
    required User user,
    required UserProfile profile,
  }) =>
      AuthState(
        status: AuthStatus.authenticatedStaff,
        user: user,
        profile: profile,
      );

  factory AuthState.staffPendingApproval(User user) => AuthState(
        status: AuthStatus.staffPendingApproval,
        user: user,
      );

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

