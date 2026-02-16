import 'package:flutter_test/flutter_test.dart';
import 'package:himatch/models/user.dart';

void main() {
  group('AppUser', () {
    test('fromJson creates user correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'display_name': 'テストユーザー',
        'email': 'test@example.com',
        'avatar_url': 'https://example.com/avatar.png',
        'auth_provider': 'apple',
        'auth_provider_id': 'apple_user_123',
        'timezone': 'Asia/Tokyo',
        'privacy_default': 'friends',
      };

      final user = AppUser.fromJson(json);

      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.displayName, 'テストユーザー');
      expect(user.email, 'test@example.com');
      expect(user.authProvider, 'apple');
      expect(user.timezone, 'Asia/Tokyo');
      expect(user.privacyDefault, 'friends');
    });

    test('toJson produces correct keys', () {
      const user = AppUser(
        id: 'test-id',
        displayName: 'テスト',
        authProvider: 'google',
        authProviderId: 'google_123',
      );

      final json = user.toJson();

      expect(json['display_name'], 'テスト');
      expect(json['auth_provider'], 'google');
      expect(json['auth_provider_id'], 'google_123');
      expect(json['timezone'], 'Asia/Tokyo');
      expect(json['privacy_default'], 'friends');
    });

    test('copyWith works correctly', () {
      const user = AppUser(
        id: 'test-id',
        displayName: 'Before',
        authProvider: 'apple',
        authProviderId: 'apple_123',
      );

      final updated = user.copyWith(displayName: 'After');

      expect(updated.displayName, 'After');
      expect(updated.id, 'test-id');
    });
  });
}
