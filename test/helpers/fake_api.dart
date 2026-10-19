import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A recorded request.
class FakeCall {
  FakeCall(this.method, this.path, this.query, this.body);
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? body;
}

/// A reply: status + JSON body (wrapped in the ApiResponse envelope unless
/// [raw]), or bytes for downloads.
class FakeReply {
  const FakeReply(this.data, {this.status = 200, this.raw = false, this.headers = const {}});
  final Object? data;
  final int status;
  final bool raw;
  final Map<String, List<String>> headers;

  static FakeReply error(int status, String message) =>
      FakeReply({'success': false, 'message': message}, status: status, raw: true);
}

/// Dio adapter that answers from a route table and records every call, so
/// remotes and cubits are tested against the backend contract without HTTP.
class FakeApi implements HttpClientAdapter {
  final calls = <FakeCall>[];
  final _routes = <String, FakeReply Function(FakeCall)>{};

  /// Registers a reply for `METHOD /path`.
  void on(String method, String path, FakeReply Function(FakeCall call) reply) {
    _routes['$method $path'] = reply;
  }

  Dio dio() => Dio(BaseOptions(baseUrl: 'http://fake'))..httpClientAdapter = this;

  List<FakeCall> callsTo(String path) => calls.where((c) => c.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body = options.data;
    if (body is String && body.isNotEmpty) body = jsonDecode(body);
    final call = FakeCall(options.method, options.path, options.queryParameters, body);
    calls.add(call);
    final handler = _routes['${options.method} ${options.path}'];
    final reply = handler == null ? FakeReply.error(404, 'No fake for ${options.path}') : handler(call);
    if (reply.data is List<int>) {
      return ResponseBody.fromBytes(reply.data as List<int>, reply.status, headers: reply.headers);
    }
    final payload = reply.raw ? reply.data : {'success': true, 'message': 'ok', 'data': reply.data};
    return ResponseBody.fromString(
      jsonEncode(payload),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...reply.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
