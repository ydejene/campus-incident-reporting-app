import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_role.dart';
import '../domain/services/alu_email_validator.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<User?>? _authSubscription;

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);

    _authSubscription?.cancel();
    _authSubscription = repository.authStateChanges.listen((user) {
      _handleUserChanged(user);
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return AuthState.initial();
  }

  Future<void> _handleUserChanged(User? user) async {
    if (user == null) {
      state = AuthState.unauthenticated();
      return;
    }

    final email = user.email ?? '';
    final normalized = ALUEmailValidator.normalize(email);

    if (!ALUEmailValidator.isEligibleEmail(normalized)) {
      await ref.read(authRepositoryProvider).signOut();
      state = AuthState.unauthenticated(
        'Access denied: Only official ALU accounts (@alustudent.com or @alueducation.com) are permitted.',
      );
      return;
    }

    // Gated by email verification
    if (!user.emailVerified) {
      state = AuthState.unverified(user);
      return;
    }

    state = state.copyWith(isLoading: true);
    final repository = ref.read(authRepositoryProvider);

    try {
      // Force refresh ID token so Firebase Security Rules receive the updated email_verified: true claim
      await user.getIdToken(true);

      if (ALUEmailValidator.isStudentEmail(normalized)) {
        var profile = await repository.fetchUserProfile(user.uid).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Connection timeout: Unable to reach Firestore database.'),
        );
        profile ??= await repository.createStudentProfile(
          uid: user.uid,
          email: normalized,
          displayName: user.displayName ?? 'ALU Student',
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Connection timeout: Unable to reach Firestore database.'),
        );
        state = AuthState.authenticatedStudent(user: user, profile: profile);
        return;
      }

      if (ALUEmailValidator.isStaffEmail(normalized)) {
        final profile = await repository.fetchUserProfile(user.uid).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Connection timeout: Unable to reach Firestore database.'),
        );
        if (profile != null && profile.role == UserRole.staff) {
          state = AuthState.authenticatedStaff(user: user, profile: profile);
        } else {
          // Staff domain email without provisioned staff profile document
          state = AuthState.staffPendingApproval(user);
        }
        return;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return;
    }

    state = AuthState.unauthenticated();
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email: email,
            password: password,
          );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> registerStudent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).registerStudent(
            email: email,
            password: password,
            displayName: displayName,
          );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential =
          await ref.read(authRepositoryProvider).signInWithGoogle();
      if (credential == null) {
        // User canceled sign in
        state = state.copyWith(isLoading: false);
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  Future<bool> checkEmailVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final verified =
          await ref.read(authRepositoryProvider).reloadAndCheckVerification();
      if (verified) {
        final user = ref.read(authRepositoryProvider).currentUser;
        await _handleUserChanged(user);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Email is not verified yet. Please check your inbox and click the link.',
        );
      }
      return verified;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await ref.read(authRepositoryProvider).signOut();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _cleanErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return _mapAuthError(error);
    }

    final str = error.toString().toLowerCase();

    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('failed to connect') ||
        str.contains('googleapis') ||
        str.contains('network_error') ||
        str.contains('unreachable')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }
    if (str.contains('permission-denied') || str.contains('insufficient permissions')) {
      return 'Access denied. You do not have permission to perform this operation.';
    }
    if (str.contains('timeout')) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }
    if (str.contains('user-not-found') ||
        str.contains('wrong-password') ||
        str.contains('invalid-credential')) {
      return 'Incorrect email or password. Please check your details and try again.';
    }
    if (str.contains('email-already-in-use')) {
      return 'An account already exists with this email. Please sign in instead.';
    }
    if (str.contains('not_found') || str.contains('database')) {
      return 'Database service unavailable. Please try again in a few moments.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  String _mapAuthError(FirebaseAuthException e) {
    final msgLower = (e.message ?? '').toLowerCase();

    // Catch network / socket drops embedded inside FirebaseAuthException
    if (e.code == 'network-request-failed' ||
        msgLower.contains('failed to connect') ||
        msgLower.contains('googleapis') ||
        msgLower.contains('socketexception') ||
        msgLower.contains('unreachable') ||
        msgLower.contains('network_error') ||
        msgLower.contains('timeout') ||
        (e.message != null && e.message!.contains('['))) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }

    switch (e.code) {
      case 'ineligible-email':
        return e.message ?? 'Ineligible email domain.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 8 characters.';
      case 'invalid-email':
        return 'The email format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact campus IT.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few moments and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
