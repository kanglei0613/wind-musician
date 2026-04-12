library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_user.dart';
import 'repositories/user_repository.dart';
import 'services/auth_service.dart';

/// Singleton AuthService provider.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Watches Firebase auth state. Emits null when not signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Resolves the current [AppUser] from Firestore, or null if not signed in.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.valueOrNull;
  if (firebaseUser == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .get();

  if (!doc.exists) return null;
  return AppUser.fromFirestore(doc);
});

/// Convenience: true when a Firebase user is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// Singleton UserRepository provider.
final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());
