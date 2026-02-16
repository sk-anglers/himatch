import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unified auth state that works in both demo and Supabase modes.
enum AuthMode { none, demo, supabase }

class AuthState {
  final AuthMode mode;
  final String? userId;
  final String? displayName;

  const AuthState({
    this.mode = AuthMode.none,
    this.userId,
    this.displayName,
  });

  bool get isAuthenticated => mode != AuthMode.none;
  bool get isDemo => mode == AuthMode.demo;
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void signInDemo() {
    state = const AuthState(
      mode: AuthMode.demo,
      userId: 'local-user',
      displayName: 'デモユーザー',
    );
  }

  void signOut() {
    state = const AuthState();
  }

  // Will be extended for Supabase auth in future
  void signInWithSupabase({
    required String userId,
    required String displayName,
  }) {
    state = AuthState(
      mode: AuthMode.supabase,
      userId: userId,
      displayName: displayName,
    );
  }
}
