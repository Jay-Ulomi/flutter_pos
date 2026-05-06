import 'dart:convert';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/token_manager.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote.dart';
import '../models/auth_models.dart';
import '../models/business_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenManager _tokenManager;
  final NetworkInfo _networkInfo;
  final ApiClient _apiClient;

  AuthRepositoryImpl(
    this._remote,
    this._tokenManager,
    this._networkInfo,
    this._apiClient,
  );

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (!_networkInfo.isConnected) {
      throw NetworkException();
    }
    final response = await _remote.login(request);
    await _tokenManager.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _tokenManager.saveUserJson(jsonEncode(response.user.toJson()));
    // Warm the in-memory header cache immediately after login
    _apiClient.updateCache(accessToken: response.accessToken);
    return response;
  }

  @override
  Future<ContextResponse> switchContext(SwitchContextRequest request) async {
    if (!_networkInfo.isConnected) {
      throw NetworkException();
    }
    final response = await _remote.switchContext(request);
    await _tokenManager.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _tokenManager.saveBusinessId(response.businessId);
    if (response.branchId != null) {
      await _tokenManager.saveBranchId(response.branchId!);
    }
    // Warm cache with new context token and headers
    _apiClient.updateCache(
      accessToken: response.accessToken,
      businessId: response.businessId,
      branchId: response.branchId,
    );
    return response;
  }

  @override
  Future<User> getCurrentUser() async {
    if (_networkInfo.isConnected) {
      try {
        final user = await _remote.getCurrentUser();
        await _tokenManager.saveUserJson(jsonEncode(user.toJson()));
        return user;
      } catch (_) {
        // Fall through to cached
      }
    }
    final cached = await _tokenManager.getUserJson();
    if (cached != null) {
      return User.fromJson(jsonDecode(cached));
    }
    throw ServerException(message: 'No user data available');
  }

  @override
  Future<List<Business>> getBusinesses() async {
    if (!_networkInfo.isConnected) {
      throw NetworkException();
    }
    return _remote.getBusinesses();
  }

  @override
  Future<List<Branch>> getBranches(String businessId) async {
    if (!_networkInfo.isConnected) {
      throw NetworkException();
    }
    return _remote.getBranches(businessId);
  }

  @override
  Future<List<TenantFeature>> getTenantFeatures() async {
    if (!_networkInfo.isConnected) {
      throw NetworkException();
    }
    return _remote.getTenantFeatures();
  }

  @override
  Future<SubscriptionInfo?> getSubscription() async {
    if (!_networkInfo.isConnected) return null; // fail silently when offline
    try {
      return await _remote.getSubscription();
    } catch (_) {
      return null; // non-fatal — app still works, just no trial UI
    }
  }

  @override
  Future<void> logout() async {
    _apiClient.clearCache(); // wipe in-memory headers immediately
    await _tokenManager.clearAll();
  }
}
