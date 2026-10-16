import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pos/core/constants/api_constants.dart';
import 'package:flutter_pos/core/network/api_client.dart';
import 'package:flutter_pos/core/utils/token_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny local backend: records requests and answers from a handler.
class FakeBackend {
  late HttpServer server;
  final requests = <HttpRequest>[];
  final bodies = <String>[];
  late Future<void> Function(HttpRequest request, String body) handler;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(request);
      bodies.add(body);
      await handler(request, body);
    });
  }

  String get baseUrl => 'http://127.0.0.1:${server.port}';

  int countPath(String path) => requests.where((r) => r.uri.path == path).length;

  Future<void> close() => server.close(force: true);
}

Future<void> json(HttpRequest request, int status, Object body) async {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await request.response.close();
}

/// Known bug (lib/core/network/api_client.dart, onError): when the request
/// retried after a successful refresh fails again (401, 500, timeout),
/// `_retryRequest` throws inside the async interceptor, the handler is never
/// called and the caller's future never completes (UI spinner forever). Fix:
///   try { handler.resolve(await _retryRequest(error.requestOptions)); }
///   on DioException catch (retryError) { handler.next(retryError); }
///   return;
/// Remove the skips below once that is applied; both tests pass with it.

void main() {
  // No TestWidgetsFlutterBinding here: it swaps HttpClient for a stub that
  // answers 400, and these tests talk to a real local server.
  late FakeBackend backend;
  late TokenManager tokens;
  late ApiClient client;

  setUp(() async {
    backend = FakeBackend();
    await backend.start();
    dotenv.testLoad(fileInput: 'API_BASE_URL=${backend.baseUrl}');
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
      'business_id': 'biz-1',
      'branch_id': 'branch-1',
    });
    tokens = TokenManager(const FlutterSecureStorage());
    client = ApiClient(tokens);
  });
  tearDown(() => backend.close());

  test('unwraps the {success, data} envelope and sends auth + context headers', () async {
    backend.handler = (req, _) => json(req, 200, {'success': true, 'data': {'id': 'p1'}});

    final response = await client.dio.get('/api/products/p1');

    expect(response.data, {'id': 'p1'});
    final sent = backend.requests.single.headers;
    expect(sent.value('authorization'), 'Bearer old-access');
    expect(sent.value('x-business-id'), 'biz-1');
    expect(sent.value('x-branch-id'), 'branch-1');
  });

  test('a 401 refreshes the token once, retries with the new token and saves the rotated refresh token', () async {
    backend.handler = (req, body) async {
      if (req.uri.path == ApiConstants.refreshToken) {
        expect(jsonDecode(body), {'refreshToken': 'old-refresh'});
        return json(req, 200, {
          'success': true,
          'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        });
      }
      final auth = req.headers.value('authorization');
      if (auth == 'Bearer new-access') return json(req, 200, {'success': true, 'data': 'ok'});
      return json(req, 401, {'success': false, 'message': 'Unauthorized'});
    };

    final response = await client.dio.get('/api/pos/sales');

    expect(response.data, 'ok');
    expect(backend.countPath(ApiConstants.refreshToken), 1);
    expect(await tokens.getAccessToken(), 'new-access');
    expect(await tokens.getRefreshToken(), 'new-refresh');
  });

  test('simultaneous 401s share a single refresh', () async {
    backend.handler = (req, body) async {
      if (req.uri.path == ApiConstants.refreshToken) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return json(req, 200, {'accessToken': 'new-access', 'refreshToken': 'new-refresh'});
      }
      final ok = req.headers.value('authorization') == 'Bearer new-access';
      return json(req, ok ? 200 : 401, ok ? {'success': true, 'data': 'ok'} : {'message': 'Unauthorized'});
    };

    final results = await Future.wait([
      client.dio.get('/api/a'),
      client.dio.get('/api/b'),
      client.dio.get('/api/c'),
    ]);

    expect(results.map((r) => r.data), ['ok', 'ok', 'ok']);
    expect(backend.countPath(ApiConstants.refreshToken), 1);
  });

  test('when the refresh is refused, the session is cleared and the 401 surfaces', () async {
    backend.handler = (req, _) => json(req, 401, {'success': false, 'message': 'Unauthorized'});

    await expectLater(
      client.dio.get('/api/pos/sales'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );

    expect(await tokens.getAccessToken(), isNull);
    expect(await tokens.getRefreshToken(), isNull);
  });

  test('a 403 (permission refused) does not trigger a refresh', () async {
    backend.handler = (req, _) => json(req, 403, {'success': false, 'message': 'Required permission: void_sale'});

    await expectLater(client.dio.post('/api/pos/sales/s1/void'), throwsA(isA<DioException>()));

    expect(backend.countPath(ApiConstants.refreshToken), 0);
    expect(await tokens.getAccessToken(), 'old-access');
  });

  test('a retried request that still gets 401 is not refreshed again (no loop)', () async {
    backend.handler = (req, _) async {
      if (req.uri.path == ApiConstants.refreshToken) {
        return json(req, 200, {'accessToken': 'new-access', 'refreshToken': 'new-refresh'});
      }
      return json(req, 401, {'message': 'Unauthorized'});
    };

    await expectLater(
      client.dio.get('/api/pos/sales').timeout(const Duration(seconds: 5)),
      throwsA(isA<DioException>()),
    );

    expect(backend.countPath(ApiConstants.refreshToken), 1);
    expect(backend.countPath('/api/pos/sales'), 2);
  });

  test('if the retry after a refresh fails (e.g. 500), the error reaches the caller instead of hanging', () async {
    backend.handler = (req, _) async {
      if (req.uri.path == ApiConstants.refreshToken) {
        return json(req, 200, {'accessToken': 'new-access', 'refreshToken': 'new-refresh'});
      }
      final retried = req.headers.value('authorization') == 'Bearer new-access';
      return json(req, retried ? 500 : 401, {'message': retried ? 'Server error' : 'Unauthorized'});
    };

    await expectLater(
      client.dio.get('/api/pos/sales').timeout(const Duration(seconds: 5)),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 500)),
    );
  });
}
