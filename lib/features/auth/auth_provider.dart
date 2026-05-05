library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/theme/color_mode_provider.dart';
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

  // BC-005：網路斷線時 Firestore .get() 會拋出 FirebaseException / SocketException
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  } on FirebaseException catch (e) {
    throw Exception('無法取得用戶資料（Firebase 異常）：${e.message}');
  } on SocketException {
    throw Exception('無法取得用戶資料（網路連線失敗），請確認網路後重試。');
  }
});

/// Convenience: true when a Firebase user is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// Singleton UserRepository provider.
final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());

/// Watches for login events and applies the user's saved Firestore settings
/// (language + color mode) to the local providers + SharedPreferences.
/// This makes settings sync automatically when the user signs in on a new device.
final settingsSyncProvider = Provider<void>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  userAsync.whenData((appUser) {
    if (appUser == null) return;

    // Apply language if saved in Firestore and different from current
    final firestoreLocale = appUser.language;
    if (firestoreLocale != null &&
        AppConstants.supportedLocales.contains(firestoreLocale)) {
      final current = ref.read(localeProvider);
      if (current.languageCode != firestoreLocale) {
        ref.read(localeProvider.notifier).state = Locale(firestoreLocale);
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(AppConstants.keyLocale, firestoreLocale),
        );
      }
    }

    // Apply color mode if saved in Firestore
    final fsScheme = appUser.colorScheme;
    final fsBrightness = appUser.colorBrightness;
    if (fsScheme != null || fsBrightness != null) {
      final current = ref.read(colorModeProvider);
      final newScheme = fsScheme != null
          ? AppColorScheme.values.firstWhere(
              (e) => e.name == fsScheme,
              orElse: () => current.scheme,
            )
          : current.scheme;
      final newBrightness = fsBrightness != null
          ? AppBrightness.values.firstWhere(
              (e) => e.name == fsBrightness,
              orElse: () => current.brightness,
            )
          : current.brightness;
      if (newScheme != current.scheme || newBrightness != current.brightness) {
        final newMode = ColorMode(scheme: newScheme, brightness: newBrightness);
        ref.read(colorModeProvider.notifier).state = newMode;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(AppConstants.keyColorScheme, newScheme.name);
          prefs.setString(AppConstants.keyColorBrightness, newBrightness.name);
        });
      }
    }
  });
});
