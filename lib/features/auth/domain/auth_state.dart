import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

@immutable
class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

@immutable
class AuthState {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AuthUser user)
      : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AuthUser? user;
}