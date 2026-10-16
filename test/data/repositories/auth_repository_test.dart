import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pos/core/error/exceptions.dart';
import 'package:flutter_pos/core/network/api_client.dart';
import 'package:flutter_pos/core/network/network_info.dart';
import 'package:flutter_pos/core/utils/token_manager.dart';
import 'package:flutter_pos/data/datasources/remote/auth_remote.dart';
import 'package:flutter_pos/data/models/auth_models.dart';
import 'package:flutter_pos/data/repositories/auth_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNetwork implements NetworkInfo {
  bool online = true;
  @override
  bool get isConnected => online;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRemote implements AuthRemoteDataSource {
  int logoutCalls = 0;
  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (request.password != 'right') {
      throw ServerException(message: 'Invalid email or password', statusCode: 401);
    }
    return AuthResponse(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      user: User(id: 'u1', email: request.email, firstName: 'Cash', lastName: 'Ier', role: 'USER'),
      businesses: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #logout) {
      logoutCalls++;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late FakeNetwork network;
  late FakeAuthRemote remote;
  late TokenManager tokens;
  late AuthRepositoryImpl repo;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://127.0.0.1:1');
    FlutterSecureStorage.setMockInitialValues({});
    network = FakeNetwork();
    remote = FakeAuthRemote();
    tokens = TokenManager(const FlutterSecureStorage());
    repo = AuthRepositoryImpl(remote, tokens, network, ApiClient(tokens));
  });

  test('login stores both tokens and the user', () async {
    await repo.login(LoginRequest(email: 'cashier@shop.tz', password: 'right'));

    expect(await tokens.getAccessToken(), 'access-1');
    expect(await tokens.getRefreshToken(), 'refresh-1');
    final user = jsonDecode((await tokens.getUserJson())!) as Map<String, dynamic>;
    expect(user['email'], 'cashier@shop.tz');
  });

  test('login while offline fails fast without calling the server or storing anything', () async {
    network.online = false;

    await expectLater(
      repo.login(LoginRequest(email: 'cashier@shop.tz', password: 'right')),
      throwsA(isA<NetworkException>()),
    );
    expect(await tokens.getAccessToken(), isNull);
  });

  test('a rejected login stores nothing', () async {
    await expectLater(
      repo.login(LoginRequest(email: 'cashier@shop.tz', password: 'wrong')),
      throwsA(isA<ServerException>()),
    );
    expect(await tokens.getAccessToken(), isNull);
  });

  test('logout wipes every stored token and context', () async {
    await repo.login(LoginRequest(email: 'cashier@shop.tz', password: 'right'));
    await tokens.saveBusinessId('biz-1');

    await repo.logout();

    expect(await tokens.getAccessToken(), isNull);
    expect(await tokens.getRefreshToken(), isNull);
    expect(await tokens.getBusinessId(), isNull);
  });

  test(
    'logout tells the server, so the session is revoked there too',
    () async {
      await repo.login(LoginRequest(email: 'cashier@shop.tz', password: 'right'));

      await repo.logout();

      expect(remote.logoutCalls, 1);
    },
  );
}
