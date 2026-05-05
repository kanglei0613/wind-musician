library;

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepo = UserRepository();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Google ────────────────────────────────────────────────────────────────

  /// Sign in with Google. Creates Firestore user document on first sign-in;
  /// updates lastActiveAt on subsequent sign-ins.
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled by user');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return _upsertUser(
      userCredential.user!,
      displayNameFallback: googleUser.displayName,
    );
  }

  // ── Apple ─────────────────────────────────────────────────────────────────

  /// Sign in with Apple Sign-In.
  ///
  /// Apple Sign-In is mandatory on iOS when offering any third-party social
  /// login (App Store Review Guideline 4.8).
  ///
  /// **Simulator note — AuthorizationError 1000**: This error is a *known
  /// simulator limitation*. The iOS Simulator cannot complete Apple Sign-In
  /// unless an Apple ID is signed into the simulator under
  /// Settings → [your name]. On a real device with a signed-in Apple ID (and
  /// the Runner.entitlements `com.apple.developer.applesignin` capability
  /// present) this works correctly. There is nothing to fix in code.
  ///
  /// **Platform guard**: Apple Sign-In is iOS-only. The login UI already hides
  /// this button on Android, but this guard ensures a clear error if called
  /// from any non-iOS path rather than a native crash.
  Future<AppUser> signInWithApple() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Sign-In is only available on iOS.');
    }
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only sends fullName on the first sign-in; cache it.
    final appleDisplayName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return _upsertUser(
      userCredential.user!,
      displayNameFallback: appleDisplayName.isNotEmpty ? appleDisplayName : null,
    );
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  /// Create a new account with email and password.
  /// [displayName] is stored in Firestore (not provided by Firebase Auth).
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user!.updateDisplayName(displayName);
    return _upsertUser(
      userCredential.user!,
      displayNameFallback: displayName,
    );
  }

  /// Sign in with an existing email/password account.
  Future<AppUser> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _upsertUser(userCredential.user!);
  }

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Update display name ───────────────────────────────────────────────────

  /// Update display name in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await Future.wait([
      user.updateDisplayName(displayName),
      _userRepo.updateDisplayName(user.uid, displayName),
    ]);
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  /// Sign out from Firebase and (if applicable) Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Create the Firestore user document on first sign-in;
  /// update lastActiveAt on subsequent sign-ins.
  Future<AppUser> _upsertUser(
    User firebaseUser, {
    String? displayNameFallback,
  }) async {
    final existing = await _userRepo.getUser(firebaseUser.uid);
    if (existing == null) {
      final now = DateTime.now();
      final newUser = AppUser(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ??
            displayNameFallback ??
            firebaseUser.email ??
            '',
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        createdAt: now,
        lastActiveAt: now,
      );
      await _userRepo.createUser(newUser);
      return newUser;
    } else {
      await _userRepo.updateLastActive(firebaseUser.uid);
      return existing.copyWith(lastActiveAt: DateTime.now());
    }
  }
}
