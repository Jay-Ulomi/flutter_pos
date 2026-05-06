import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/sync_models.dart';

class SyncRemoteDataSource {
  final ApiClient _apiClient;

  SyncRemoteDataSource(this._apiClient);

  Future<SyncBootstrap> bootstrap({required String branchId}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.syncBootstrap,
        queryParameters: {'branchId': branchId},
      );
      return SyncBootstrap.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to bootstrap sync',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SyncDelta> delta({
    required String branchId,
    required DateTime since,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.syncDelta,
        queryParameters: {
          'branchId': branchId,
          'since': since.toUtc().toIso8601String(),
        },
      );
      return SyncDelta.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch delta',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SyncPushResult> pushSales(List<Map<String, dynamic>> sales) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.syncSales,
        data: {'sales': sales},
      );
      return SyncPushResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to push sales',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LaundrySyncPushResult> pushLaundryActions(
    List<Map<String, dynamic>> actions,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.syncLaundryActions,
        data: {'actions': actions},
      );
      return LaundrySyncPushResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to push laundry actions',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
