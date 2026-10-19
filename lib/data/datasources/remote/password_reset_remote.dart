import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import 'feed_remote.dart' show unwrapEnvelope;

/// Forgot-password by emailed 6-digit code: request → verify → set password.
class PasswordResetRemoteDataSource {
  PasswordResetRemoteDataSource(this._dio);

  /// Built from [ApiClient] in the app; tests pass a Dio with a fake adapter.
  factory PasswordResetRemoteDataSource.fromClient(ApiClient client) =>
      PasswordResetRemoteDataSource(client.dio);

  final Dio _dio;

  /// Always succeeds for well-formed input (the server never says whether the
  /// account exists).
  Future<void> requestCode(String email) async {
    await _call(
      () => _dio.post(ApiConstants.forgotPassword, data: {'email': email.trim(), 'method': 'OTP'}),
      'Could not send the code',
    );
  }

  /// Exchanges the code for a short-lived reset token.
  Future<String> verifyCode(String email, String code) async {
    final res = await _call(
      () => _dio.post(ApiConstants.verifyResetOtp, data: {'email': email.trim(), 'code': code}),
      'Invalid or expired code',
    );
    final data = unwrapEnvelope(res.data);
    final token = data is Map ? data['resetToken'] as String? : null;
    if (token == null || token.isEmpty) {
      throw ServerException(message: 'Invalid or expired code');
    }
    return token;
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _call(
      () => _dio.post(ApiConstants.resetPassword, data: {'token': token, 'newPassword': newPassword}),
      'Could not change the password',
    );
  }

  Future<Response> _call(Future<Response> Function() send, String fallback) async {
    try {
      return await send();
    } on DioException catch (e) {
      final body = e.response?.data;
      throw ServerException(
        message: body is Map && body['message'] is String ? body['message'] as String : fallback,
        statusCode: e.response?.statusCode,
      );
    }
  }
}
