import 'package:flutter_pos/core/constants/api_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConstants.resolveBaseUrl', () {
    test('uses .env value first', () {
      final baseUrl = ApiConstants.resolveBaseUrl(
        envValue: 'http://10.10.10.5:8090/',
        defineValue: 'http://192.168.1.50:8090',
        releaseMode: false,
      );

      expect(baseUrl, 'http://10.10.10.5:8090');
    });

    test('uses --dart-define value when .env is missing', () {
      final baseUrl = ApiConstants.resolveBaseUrl(
        envValue: null,
        defineValue: 'http://192.168.1.50:8090/',
        releaseMode: false,
      );

      expect(baseUrl, 'http://192.168.1.50:8090');
    });

    test('uses local fallback in non-release when config is missing', () {
      final baseUrl = ApiConstants.resolveBaseUrl(
        envValue: null,
        defineValue: null,
        releaseMode: false,
      );

      expect(baseUrl, 'http://127.0.0.1:8090');
    });

    test('throws in release when config is missing', () {
      expect(
        () => ApiConstants.resolveBaseUrl(
          envValue: null,
          defineValue: null,
          releaseMode: true,
        ),
        throwsStateError,
      );
    });
  });
}
