import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import '../../domain/services/alu_email_validator.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  AuthRepository({
    required this.firebaseAuth,
    required this.firestore,
  });

  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  User? get currentUser => firebaseAuth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return UserProfile.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile> createStudentProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      uid: uid,
      displayName: displayName.trim().isEmpty ? 'ALU Student' : displayName.trim(),
      email: ALUEmailValidator.normalize(email),
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
    );

    await firestore.collection('users').doc(uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );

    return profile;
  }

  Future<UserCredential> registerStudent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = ALUEmailValidator.normalize(email);

    if (!ALUEmailValidator.isStudentEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'ineligible-email',
        message: 'Registration is restricted to official ALU student emails (@alustudent.com).',
      );
    }

    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      await user.sendEmailVerification();
    }

    return credential;
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = ALUEmailValidator.normalize(email);

    if (!ALUEmailValidator.isEligibleEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'ineligible-email',
        message: 'Only authorized ALU emails (@alustudent.com or @alueducation.com) can sign in.',
      );
    }

    return await firebaseAuth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final GoogleSignInAccount googleAccount =
          await GoogleSignIn.instance.authenticate();

      final String email = ALUEmailValidator.normalize(googleAccount.email);

      // Verify domain before linking to Firebase session
      if (!ALUEmailValidator.isEligibleEmail(email)) {
        await GoogleSignIn.instance.signOut();
        throw FirebaseAuthException(
          code: 'ineligible-email',
          message:
              'Access denied. Please choose an authorized ALU account (@alustudent.com or @alueducation.com).',
        );
      }

      final String? idToken = googleAccount.authentication.idToken;
      final OAuthCredential credential =
          GoogleAuthProvider.credential(idToken: idToken);

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // If student signs in via Google for the first time, ensure their profile document is created
      final user = userCredential.user;
      if (user != null && ALUEmailValidator.isStudentEmail(email)) {
        final existingProfile = await fetchUserProfile(user.uid);
        if (existingProfile == null) {
          await createStudentProfile(
            uid: user.uid,
            email: email,
            displayName: user.displayName ?? googleAccount.displayName ?? 'ALU Student',
          );
        }
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    return firebaseAuth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore errors if Google Sign In was not active
    }
  }
}

