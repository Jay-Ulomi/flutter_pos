import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pos/core/constants/api_constants.dart';
import 'package:flutter_pos/core/error/exceptions.dart';
import 'package:flutter_pos/core/network/api_client.dart';
import 'package:flutter_pos/core/utils/token_manager.dart';
import 'package:flutter_pos/data/datasources/local/product_local.dart';
import 'package:flutter_pos/data/datasources/remote/sale_remote.dart';
import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  group('SaleRemoteDataSource.preview', () {
    late HttpServer server;
    late List<String> bodies;
    late int status;
    late Object reply;
    late SaleRemoteDataSource remote;

    setUp(() async {
      bodies = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        bodies.add(await utf8.decoder.bind(request).join());
        request.response
          ..statusCode = status
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(reply));
        await request.response.close();
      });
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://127.0.0.1:${server.port}');
      FlutterSecureStorage.setMockInitialValues({});
      remote = SaleRemoteDataSource(ApiClient(TokenManager(const FlutterSecureStorage())));
    });

    tearDown(() => server.close(force: true));

    test('posts the cart and returns the server pricing', () async {
      status = 200;
      reply = {
        'success': true,
        'data': {
          'subtotal': 2000,
          'discountAmount': 200,
          'taxAmount': 324,
          'totalAmount': 2124,
          'appliedPromotions': [
            {'name': 'Ten percent', 'couponCode': 'SAVE10', 'discountAmount': 200},
          ],
        },
      };

      final preview = await remote.preview({
        'items': [
          {'productId': 'p1', 'quantity': 2},
        ],
        'couponCode': 'SAVE10',
      });

      expect(preview.totalAmount, 2124);
      expect(preview.hasCoupon('SAVE10'), isTrue);
      expect(jsonDecode(bodies.single)['couponCode'], 'SAVE10');
      expect(ApiConstants.salesPreview, endsWith('/pos/sales/preview'));
    });

    test('an invalid coupon surfaces the server message', () async {
      status = 400;
      reply = {'success': false, 'message': 'Coupon SAVE10 has expired'};

      expect(
        () => remote.preview({
          'items': [
            {'productId': 'p1', 'quantity': 1},
          ],
          'couponCode': 'SAVE10',
        }),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'Coupon SAVE10 has expired')
            .having((e) => e.statusCode, 'status', 400)),
      );
    });
  });

  test('the offline product cache keeps tax exemption and tier prices', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);
    final local = ProductLocalDataSource(db);

    await local.cacheProducts(const [
      Product(id: 'p1', name: 'Bread', sellingPrice: 500, taxRate: 18, taxable: false),
      Product(
        id: 'p2',
        name: 'Widget',
        sellingPrice: 1000,
        taxRate: 18,
        tierPrices: {'NORMAL': 1000, 'WHOLESALE': 800},
      ),
    ]);

    final cached = {for (final p in await local.getProducts()) p.id: p};
    expect(cached['p1']!.taxable, isFalse);
    expect(cached['p2']!.taxable, isTrue);
    expect(cached['p2']!.priceForTier('WHOLESALE'), 800);
  });
}
