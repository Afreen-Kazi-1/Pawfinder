import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/storage/token_storage.dart';

void main() {
  group('TokenStorage Abstraction Tests (InMemoryTokenStorage)', () {
    late TokenStorage storage;

    setUp(() {
      storage = InMemoryTokenStorage();
    });

    test('Initial state has no tokens', () async {
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.hasAccessToken(), isFalse);
    });

    test('saveTokens stores access and refresh tokens correctly', () async {
      await storage.saveTokens(
        accessToken: 'mock_access_token_123',
        refreshToken: 'mock_refresh_token_456',
      );

      expect(await storage.getAccessToken(), 'mock_access_token_123');
      expect(await storage.getRefreshToken(), 'mock_refresh_token_456');
      expect(await storage.hasAccessToken(), isTrue);
    });

    test('clearTokens removes all stored tokens', () async {
      await storage.saveTokens(
        accessToken: 'token_to_remove',
        refreshToken: 'refresh_to_remove',
      );
      expect(await storage.hasAccessToken(), isTrue);

      await storage.clearTokens();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.hasAccessToken(), isFalse);
    });
  });
}

