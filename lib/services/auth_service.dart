import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:himatch/services/supabase_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.currentUser;
});

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.skanglers.himatch://login-callback',
    ).then((_) => _client.auth.currentSession != null
        ? AuthResponse(session: _client.auth.currentSession)
        : AuthResponse(session: null));
  }

  Future<AuthResponse> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.skanglers.himatch://login-callback',
    ).then((_) => _client.auth.currentSession != null
        ? AuthResponse(session: _client.auth.currentSession)
        : AuthResponse(session: null));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
