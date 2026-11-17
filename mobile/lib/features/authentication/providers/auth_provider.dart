import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        errorMessage = message;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

class AuthNotifier extends Notifier<AuthState> {
  final AuthRepository? _repoOverride;

  AuthNotifier([this._repoOverride]);

  AuthRepository get _repository => _repoOverride ?? ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(() => checkAuthStatus());
    return const AuthState.initial();
  }

  Future<void> checkAuthStatus() async {
    try {
      final hasToken = await _repository.isAuthenticated();
      if (!ref.mounted) return;
      if (!hasToken) {
        state = const AuthState.unauthenticated();
        return;
      }

      state = const AuthState.loading();
      final user = await _repository.getCurrentUser();
      if (!ref.mounted) return;
      state = AuthState.authenticated(user);
    } catch (_) {
      if (ref.mounted) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      if (!ref.mounted) return false;
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString());
      }
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      await _repository.register(name: name, email: email, password: password);
      if (!ref.mounted) return false;
      // Auto login upon successful registration
      final user = await _repository.login(email: email, password: password);
      if (!ref.mounted) return false;
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString());
      }
      return false;
    }
  }

  void setUser(UserModel user) {
    state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _repository.logout();
    } finally {
      if (ref.mounted) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<bool> updateProfile({String? name, String? phone, String? profileImageUrl}) async {
    if (state.user == null) return false;
    try {
      final updated = await _repository.updateProfile(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      if (!ref.mounted) return false;
      state = AuthState.authenticated(updated);
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString());
      }
      return false;
    }
  }
}

// Dependency Injection Providers
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(apiClient: client, tokenStorage: storage);
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
