import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _businessIdKey = 'business_id';
  static const _branchIdKey = 'branch_id';
  static const _userKey = 'user_json';

  TokenManager(this._storage);

  Future<void> _write(String key, String? value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[TokenManager] write failed for $key: $e');
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[TokenManager] read failed for $key: $e');
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _write(_accessTokenKey, accessToken);
    await _write(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() => _read(_accessTokenKey);
  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  Future<void> saveBusinessId(String id) => _write(_businessIdKey, id);
  Future<String?> getBusinessId() => _read(_businessIdKey);

  Future<void> saveBranchId(String id) => _write(_branchIdKey, id);
  Future<String?> getBranchId() => _read(_branchIdKey);

  Future<void> saveUserJson(String json) => _write(_userKey, json);
  Future<String?> getUserJson() => _read(_userKey);

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[TokenManager] clearAll failed: $e');
    }
  }
}
