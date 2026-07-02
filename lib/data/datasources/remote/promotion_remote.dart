import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';

class CouponValidationResult {
  final String code;
  final String name;
  final String discountType; // 'PERCENTAGE' | 'FIXED_AMOUNT'
  final double discountValue;
  final double? minimumOrderAmount;

  const CouponValidationResult({
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      code: (json['couponCode'] as String? ?? '').toUpperCase(),
      name: json['name'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble(),
    );
  }

  /// Preview discount amount for a given cart subtotal.
  double calculateDiscount(double subtotal) {
    if (minimumOrderAmount != null && subtotal < minimumOrderAmount!) return 0;
    if (discountType == 'PERCENTAGE') {
      return subtotal * (discountValue / 100);
    }
    return discountValue;
  }
}

class PromotionRemoteDataSource {
  final ApiClient _apiClient;

  PromotionRemoteDataSource(this._apiClient);

  Future<CouponValidationResult> validateCoupon(String couponCode) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/promotions/validate-coupon',
        data: {'couponCode': couponCode.trim().toUpperCase()},
      );
      return CouponValidationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Invalid coupon code',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
