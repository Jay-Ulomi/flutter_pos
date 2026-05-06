import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalePayment', () {
    test('serializes reference when provided', () {
      const payment = SalePayment(
        method: 'BANK_TRANSFER',
        amount: 12500,
        reference: 'TXN-12345',
      );

      final json = payment.toJson();
      expect(json['paymentMethod'], 'BANK_TRANSFER');
      expect(json['amount'], 12500);
      expect(json['reference'], 'TXN-12345');
    });

    test('parses reference from json payload', () {
      final payment = SalePayment.fromJson(const {
        'paymentMethod': 'MOBILE_MONEY',
        'amount': 6000,
        'reference': 'MMP-998',
      });

      expect(payment.method, 'MOBILE_MONEY');
      expect(payment.amount, 6000);
      expect(payment.reference, 'MMP-998');
    });
  });
}
