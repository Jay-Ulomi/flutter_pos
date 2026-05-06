import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/session_models.dart';

class SessionRemoteDataSource {
  final ApiClient _apiClient;

  SessionRemoteDataSource(this._apiClient);

  Future<CashSession> openSession(OpenSessionRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.openSession,
        data: request.toJson(),
      );
      return CashSession.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to open session',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CashSession> closeSession(CloseSessionRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.sessions}/${request.sessionId}/close',
        data: request.toJson(),
      );
      return CashSession.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to close session',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CashSession?> getCurrentSession() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sessions}/active',
      );
      return CashSession.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get session',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ShiftSummary> getSessionSummary(String sessionId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sessions}/$sessionId/summary',
      );
      return ShiftSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get summary',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
