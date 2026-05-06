import 'dart:async';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/token_manager.dart';

class ApiClient {
  late final Dio dio;
  final TokenManager _tokenManager;

  // ── Refresh-lock: only one refresh in flight at a time ───────────────────
  // Any request that hits 401 while a refresh is already running will wait
  // for that single refresh to finish and reuse the result.
  Completer<bool>? _refreshCompleter;

  // ── In-memory cache to avoid repeated secure-storage reads ───────────────
  String? _cachedAccessToken;
  String? _cachedBusinessId;
  String? _cachedBranchId;

  ApiClient(this._tokenManager) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── 1. Response envelope unwrapper ────────────────────────────────────
    // Backend wraps responses as { success: true, data: T }.
    // Unwrap so datasources always read response.data as the plain payload.
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final body = response.data;
          if (body is Map<String, dynamic> &&
              body.containsKey('data') &&
              body['success'] == true) {
            response.data = body['data'];
          }
          handler.next(response);
        },
      ),
    );

    // ── 2. Auth headers + 401 refresh interceptor ─────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Use cached values; warm cache from secure storage on first request
          _cachedAccessToken ??= await _tokenManager.getAccessToken();
          _cachedBusinessId  ??= await _tokenManager.getBusinessId();
          _cachedBranchId    ??= await _tokenManager.getBranchId();

          if (_cachedAccessToken != null) {
            options.headers['Authorization'] = 'Bearer $_cachedAccessToken';
          }
          if (_cachedBusinessId != null && _cachedBusinessId!.isNotEmpty) {
            options.headers['X-Business-Id'] = _cachedBusinessId;
          }
          if (_cachedBranchId != null && _cachedBranchId!.isNotEmpty) {
            options.headers['X-Branch-Id'] = _cachedBranchId;
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          // Only handle 401. Skip if this request is already a retry
          // (marked via extra) to prevent infinite loops.
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['_isRetry'] != true) {
            final refreshed = await _ensureSingleRefresh();
            if (refreshed) {
              final retryResponse = await _retryRequest(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            }
            // Refresh failed → session is dead, clear everything
            await _clearSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  // ── Ensure only one refresh runs at a time ────────────────────────────────
  // If a refresh is already in flight, wait for its result instead of
  // starting another — preventing the thundering herd problem.
  Future<bool> _ensureSingleRefresh() async {
    if (_refreshCompleter != null) {
      // Another refresh is already running — wait for it
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final result = await _tryRefreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ── Call the refresh endpoint with a separate Dio instance ────────────────
  // Uses its own Dio so the retry interceptor doesn't intercept refresh calls.
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
        ),
      ).post(ApiConstants.refreshToken, data: {'refreshToken': refreshToken});

      // Unwrap envelope if present (backend may wrap: { success, data: {...} })
      final raw = response.data;
      final body = (raw is Map<String, dynamic> &&
              raw.containsKey('data') &&
              raw['success'] == true)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final newAccess  = body['accessToken']  as String?;
      final newRefresh = body['refreshToken'] as String?;

      if (newAccess == null || newAccess.isEmpty) return false;

      await _tokenManager.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh ?? refreshToken, // keep old if not rotated
      );

      // Update in-memory cache immediately
      _cachedAccessToken = newAccess;

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Retry the original request with the new token ─────────────────────────
  Future<Response> _retryRequest(RequestOptions options) async {
    final token = await _tokenManager.getAccessToken();
    options.headers['Authorization'] = 'Bearer $token';
    // Mark as retry so the error interceptor won't loop on another 401
    options.extra['_isRetry'] = true;
    return dio.fetch(options);
  }

  // ── Clear session when refresh fails (token fully expired) ────────────────
  // Clears in-memory cache and secure storage. The router will redirect to
  // /login via AuthBloc when the next auth check finds no token.
  Future<void> _clearSession() async {
    _cachedAccessToken = null;
    _cachedBusinessId  = null;
    _cachedBranchId    = null;
    await _tokenManager.clearAll();
  }

  // ── Called by AuthBloc after context switch to warm the header cache ───────
  void updateCache({String? accessToken, String? businessId, String? branchId}) {
    if (accessToken != null) _cachedAccessToken = accessToken;
    if (businessId  != null) _cachedBusinessId  = businessId;
    if (branchId    != null) _cachedBranchId    = branchId;
  }

  // ── Called on logout to wipe the in-memory cache ─────────────────────────
  void clearCache() {
    _cachedAccessToken = null;
    _cachedBusinessId  = null;
    _cachedBranchId    = null;
  }
}
