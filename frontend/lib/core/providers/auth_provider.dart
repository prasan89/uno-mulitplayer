import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the currently signed-in Firebase [User] (or null) and auth helpers.
class AuthNotifier extends AsyncNotifier<User?> {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<User?> build() async {
    // Listen to auth state changes and update Riverpod state accordingly.
    ref.onDispose(
      _auth.authStateChanges().listen((user) {
        if (state.valueOrNull != user) {
          state = AsyncData(user);
        }
      }).cancel,
    );
    return _auth.currentUser;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  bool get isLoggedIn => state.valueOrNull != null;

  /// Returns the current user's Firebase ID token.
  ///
  /// Throws a [StateError] if no user is signed in.
  Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = state.valueOrNull;
    if (user == null) {
      throw StateError('No user is currently signed in');
    }
    final token = await user.getIdToken(forceRefresh);
    if (token == null) {
      throw StateError('Failed to retrieve ID token');
    }
    return token;
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncData(credential.user);
      return credential;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Register a new account with email and password.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }
      state = AsyncData(_auth.currentUser);
      return credential;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncData(null);
    developer.log('User signed out', name: 'AuthNotifier');
  }

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update the current user's display name.
  Future<void> updateDisplayName(String displayName) async {
    final user = state.valueOrNull;
    if (user == null) throw StateError('No user is currently signed in');
    await user.updateDisplayName(displayName);
    await user.reload();
    state = AsyncData(_auth.currentUser);
  }
}

/// Riverpod provider for [AuthNotifier].
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

/// Convenience provider that exposes just the current [User].
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

/// Convenience provider that exposes whether the user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
