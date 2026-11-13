import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfinder/features/authentication/data/auth_repository.dart';
import 'package:pawfinder/features/authentication/models/user_model.dart';
import 'package:pawfinder/features/authentication/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? mockUser;
  bool shouldThrow = false;
  String errorMessage = 'Error occurred';
  bool authenticated = false;

  @override
  Future<UserModel> register({required String name, required String email, required String password}) async {
    if (shouldThrow) throw Exception(errorMessage);
    final user = UserModel(
      id: 'mock-user-id',
      name: name,
      email: email,
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockUser = user;
    return user;
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (shouldThrow) throw Exception(errorMessage);
    final user = UserModel(
      id: 'mock-user-id',
      name: 'Test User',
      email: email,
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockUser = user;
    authenticated = true;
    return user;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (shouldThrow) throw Exception(errorMessage);
    return mockUser ??
        UserModel(
          id: 'mock-user-id',
          name: 'Test User',
          email: 'test@example.com',
          role: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl}) async {
    if (shouldThrow) throw Exception(errorMessage);
    final user = mockUser!.copyWith(name: name, phone: phone, profileImageUrl: profileImageUrl);
    mockUser = user;
    return user;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> logout() async {
    authenticated = false;
    mockUser = null;
  }

  @override
  Future<bool> isAuthenticated() async => authenticated;
}

void main() {
  group('AuthState Model Tests', () {
    test('AuthState initial state properties', () {
      const state = AuthState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasError, isFalse);
    });

    test('AuthState loading state properties', () {
      const state = AuthState.loading();
      expect(state.status, AuthStatus.loading);
      expect(state.isLoading, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasError, isFalse);
    });

    test('AuthState authenticated state properties', () {
      final user = UserModel(
        id: 'u-123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final state = AuthState.authenticated(user);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, equals(user));
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isTrue);
      expect(state.hasError, isFalse);
    });

    test('AuthState error state properties', () {
      const state = AuthState.error('Invalid credentials');
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Invalid credentials');
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasError, isTrue);
    });
  });

  group('AuthNotifier State Transitions', () {
    late MockAuthRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Transitions to authenticated on successful login', () async {
      final notifier = container.read(authProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await notifier.login(email: 'test@example.com', password: 'password123');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'test@example.com');
    });

    test('Transitions to error state on failed login', () async {
      final notifier = container.read(authProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 10));

      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Invalid email or password';

      final success = await notifier.login(email: 'test@example.com', password: 'wrongpassword');

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.errorMessage, contains('Invalid email or password'));
      expect(state.isAuthenticated, isFalse);
    });
  });
}
