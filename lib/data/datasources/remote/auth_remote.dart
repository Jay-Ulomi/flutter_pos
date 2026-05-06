import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/auth_models.dart';
import '../../models/business_models.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ContextResponse> switchContext(SwitchContextRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.switchContext,
        data: request.toJson(),
      );
      return ContextResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to switch context',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get user',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<Business>> getBusinesses() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.businesses);
      final data = response.data;
      if (data == null) return [];
      final list = data is List
          ? data
          : (data['content'] ?? data['data'] ?? []) as List;
      return list
          .map((e) => Business.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final type = e.type.name; // connectionError, receiveTimeout, etc.
      final msg =
          e.response?.data?['message'] ??
          e.message ??
          'Failed to get businesses';
      throw ServerException(
        message: '$msg [$type]',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<Branch>> getBranches(String businessId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.branches(businessId),
      );
      final data = response.data;
      if (data == null) return [];
      final list = data is List
          ? data
          : (data['content'] ?? data['data'] ?? []) as List;
      return list
          .map((e) => Branch.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final type = e.type.name;
      throw ServerException(
        message:
            '${e.response?.data?['message'] ?? e.message ?? 'Failed to get branches'} [$type]',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SubscriptionInfo?> getSubscription() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.subscriptionCurrent,
      );
      if (response.data == null) return null;
      return SubscriptionInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 404 = no subscription yet (shouldn't happen after onboarding)
      if (e.response?.statusCode == 404) return null;
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to get subscription',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<TenantFeature>> getTenantFeatures() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.tenantFeatures);
      final data = response.data;
      if (data == null) return [];
      final list = data is List
          ? data
          : (data['content'] ?? data['data'] ?? []) as List;
      return list
          .map((e) => TenantFeature.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final type = e.type.name;
      throw ServerException(
        message:
            '${e.response?.data?['message'] ?? e.message ?? 'Failed to get tenant features'} [$type]',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
