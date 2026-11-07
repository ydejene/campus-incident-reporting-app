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

    if (ALUEmailValidator.isStudentEmail(normalized)) {
      var profile = await repository.fetchUserProfile(user.uid);
      profile ??= await repository.createStudentProfile(
        uid: user.uid,
        email: normalized,
        displayName: user.displayName ?? 'ALU Student',
      );
      state = AuthState.authenticatedStudent(user: user, profile: profile);
      return;
    }

    if (ALUEmailValidator.isStaffEmail(normalized)) {
      final profile = await repository.fetchUserProfile(user.uid);
      if (profile != null && profile.role == UserRole.staff) {
        state = AuthState.authenticatedStaff(user: user, profile: profile);
      } else {
        // Staff domain email without provisioned staff profile document
        state = AuthState.staffPendingApproval(user);
      }
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
        errorMessage: _mapAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
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
        errorMessage: _mapAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
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
        errorMessage: _mapAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
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
        errorMessage: 'Unable to send verification email. Please try again later.',
      );
    }
  }

  Future<bool> checkEmailVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
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
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await ref.read(authRepositoryProvider).signOut();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _mapAuthError(FirebaseAuthException e) {
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
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact campus IT.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few moments and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

