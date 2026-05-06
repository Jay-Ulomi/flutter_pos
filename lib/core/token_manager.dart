import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _businessIdKey = 'business_id';
  static const String _branchIdKey = 'branch_id';
  static const String _userKey = 'user_data';

  TokenManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> saveBusinessId(int businessId) async {
    await _storage.write(key: _businessIdKey, value: businessId.toString());
  }

  Future<int?> getBusinessId() async {
    final value = await _storage.read(key: _businessIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> saveBranchId(int branchId) async {
    await _storage.write(key: _branchIdKey, value: branchId.toString());
  }

  Future<int?> getBranchId() async {
    final value = await _storage.read(key: _branchIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  Future<String?> getUserData() async {
    return _storage.read(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
