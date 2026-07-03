import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _businessIdKey = 'business_id';
  static const _branchIdKey = 'branch_id';
  static const _businessTypeKey = 'business_type';
  static const _userKey = 'user_json';
  static const _permissionsKey = 'permissions';

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

  Future<void> saveBusinessType(String type) => _write(_businessTypeKey, type);
  Future<String?> getBusinessType() => _read(_businessTypeKey);

  Future<void> saveUserJson(String json) => _write(_userKey, json);
  Future<String?> getUserJson() => _read(_userKey);

  /// Effective permissions for the active business, stored comma-separated so
  /// they survive an offline restart (where switch-context can't be re-fetched).
  Future<void> savePermissions(Set<String> permissions) =>
      _write(_permissionsKey, permissions.join(','));
  Future<Set<String>> getPermissions() async {
    final raw = await _read(_permissionsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((e) => e.isNotEmpty).toSet();
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[TokenManager] clearAll failed: $e');
    }
  }
}
