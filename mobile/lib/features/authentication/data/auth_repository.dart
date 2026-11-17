import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> getCurrentUser();

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  Future<bool> isAuthenticated();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenStorage,
  });

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Fetch user profile after storing tokens
    return await getCurrentUser();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get(ApiConstants.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;

    final response = await apiClient.put(
      ApiConstants.me,
      data: data,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> logout() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await apiClient.post(
          ApiConstants.logout,
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Continue clearing local tokens even if network fails
      }
    }
    await tokenStorage.clearTokens();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await tokenStorage.hasAccessToken();
  }
}

