import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/features/auth/domain/auth_state.dart';

/// TEMPORARY, local-only auth used until the backend exists (Phase 11).
/// It accepts any well-formed input, ignores the password, and keeps the
/// session in memory only. Phase 11 replaces the bodies of these methods with
/// a repository + API + secure token storage; the UI will not change.
class AuthController extends Notifier<AuthState> {
  static const _splashDuration = Duration(milliseconds: 900);
  static const _requestDelay = Duration(milliseconds: 600);

  @override
  AuthState build() {
    // Phase 11: restore the persisted session here instead.
    final timer = Timer(_splashDuration, () {
      if (state.status == AuthStatus.unknown) {
        state = const AuthState.unauthenticated();
      }
    });
    ref.onDispose(timer.cancel);
    return const AuthState.unknown();
  }

  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(_requestDelay);
    state = AuthState.authenticated(
      AuthUser(name: _nameFromEmail(email), email: email.trim()),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_requestDelay);
    state = AuthState.authenticated(
      AuthUser(name: name.trim(), email: email.trim()),
    );
  }

  void signOut() => state = const AuthState.unauthenticated();

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Owner';
    return local[0].toUpperCase() + local.substring(1);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);