import 'dart:convert';

import '../blocs/cart/cart_state.dart';

/// Pure helpers behind checkout's server pricing, kept out of the widget so
/// they can be unit tested.
class CheckoutPricing {
  const CheckoutPricing._();

  /// Body for POST /api/pos/sales/preview, matching what checkout submits.
  static Map<String, dynamic> previewBody(CartState cart, {String? couponCode}) => {
    'items': cart.lines
        .map((l) => {
              'productId': l.product.id,
              'quantity': l.quantity,
              'unitPrice': l.effectivePrice,
              'discountAmount': l.lineDiscount,
              if (l.priceTier != null) 'priceTier': l.priceTier,
              if (l.product.variantId != null) 'variantId': l.product.variantId,
            })
        .toList(),
    'discountAmount': cart.discount,
    if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
  };

  /// Identifies a cart + coupon combination; a new key means re-price.
  static String previewKey(CartState cart, {String? couponCode}) =>
      jsonEncode(previewBody(cart, couponCode: couponCode));

  /// Currency amount to redeem from loyalty points: whole points only, capped
  /// by the customer's balance and by what is still owed.
  static double loyaltyRedeemAmount({
    required int points,
    required double pointValue,
    required double remaining,
  }) {
    if (points <= 0 || pointValue <= 0 || remaining <= 0) return 0;
    final affordablePoints = (remaining / pointValue).floor();
    final usable = points < affordablePoints ? points : affordablePoints;
    return usable * pointValue;
  }
}
