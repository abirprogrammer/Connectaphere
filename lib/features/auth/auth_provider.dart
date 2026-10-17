import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/user.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _apiClient.dio.get('${ApiConstants.profile}?user_id=$userId');
      if (response.data is Map && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']);
        state = AsyncValue.data(user);
      } else {
        await SecureStorageService.clearAll();
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      await SecureStorageService.clearAll();
      state = const AsyncValue.data(null);
    }
  }

  void updateUser(User updatedUser) {
    state = AsyncValue.data(updatedUser);
  }

  Future<String?> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'email': identifier, 'password': password},
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'];
        final user = User.fromJson(data['user']);
        await SecureStorageService.saveTokens(
          accessToken: data['access_token'] ?? 'token',
          refreshToken: data['refresh_token'] ?? 'refresh',
          userId: user.id,
        );
        state = AsyncValue.data(user);
        return null;
      }
      return response.data['message'] ?? 'Login failed';
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (e.response?.data != null && e.response?.data is Map) {
        return e.response?.data['message'] ?? 'Server error occurred';
      }
      return 'Network Error: ${e.message}';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return 'Unexpected error: $e';
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'];
        final user = User.fromJson(data['user']);
        await SecureStorageService.saveTokens(
          accessToken: data['access_token'] ?? 'token',
          refreshToken: data['refresh_token'] ?? 'refresh',
          userId: user.id,
        );
        state = AsyncValue.data(user);
        return null;
      }
      return response.data['message'] ?? 'Registration failed';
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (e.response?.data != null && e.response?.data is Map) {
        return e.response?.data['message'] ?? 'Server error occurred';
      }
      return 'Network Error: ${e.message}';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return 'Unexpected error: $e';
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorageService.clearAll();
    state = const AsyncValue.data(null);
  }
}
