import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    test('initial state is not authenticated', () {
      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, false);
      expect(state.mode, AuthMode.none);
      expect(state.userId, isNull);
    });

    test('signInDemo sets demo mode', () {
      container.read(authNotifierProvider.notifier).signInDemo();

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, true);
      expect(state.isDemo, true);
      expect(state.mode, AuthMode.demo);
      expect(state.userId, 'local-user');
      expect(state.displayName, 'デモユーザー');
    });

    test('signOut resets to unauthenticated', () {
      container.read(authNotifierProvider.notifier).signInDemo();
      expect(container.read(authNotifierProvider).isAuthenticated, true);

      container.read(authNotifierProvider.notifier).signOut();

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, false);
      expect(state.mode, AuthMode.none);
      expect(state.userId, isNull);
    });

    test('signInWithSupabase sets supabase mode', () {
      container.read(authNotifierProvider.notifier).signInWithSupabase(
            userId: 'supabase-user-123',
            displayName: 'テストユーザー',
          );

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, true);
      expect(state.isDemo, false);
      expect(state.mode, AuthMode.supabase);
      expect(state.userId, 'supabase-user-123');
      expect(state.displayName, 'テストユーザー');
    });
  });
}
