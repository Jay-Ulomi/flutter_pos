import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/feed_models.dart';

/// [ApiClient] already strips `{success, data}`; a bare Dio (tests) does not.
Object? unwrapEnvelope(Object? body) {
  if (body is Map && body['success'] == true && body.containsKey('data')) {
    return body['data'];
  }
  return body;
}

/// A downloaded export (PDF / Excel).
class DownloadedFile {
  const DownloadedFile({required this.bytes, required this.fileName, required this.mimeType});
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

/// Server feeds for the redesigned screens: transactions, parties, transfers,
/// report summary, receivables (Payment In) and file exports.
class FeedRemoteDataSource {
  FeedRemoteDataSource(this._dio);

  factory FeedRemoteDataSource.fromClient(ApiClient client) => FeedRemoteDataSource(client.dio);

  final Dio _dio;
  static final _day = DateFormat('yyyy-MM-dd');

  static String day(DateTime d) => _day.format(d);

  Future<PageResult<TransactionItem>> getTransactions({
    Set<TxType> types = const {},
    DateTime? from,
    DateTime? to,
    String? search,
    PartyType? partyType,
    String? partyId,
    int page = 0,
    int size = 30,
  }) async {
    final res = await _get(ApiConstants.transactions, {
      if (types.isNotEmpty) 'types': types.map((t) => t.code).join(','),
      if (from != null) 'from': day(from),
      if (to != null) 'to': day(to),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (partyType != null) 'partyType': partyType.code,
      'partyId': ?partyId,
      'page': page,
      'size': size,
    }, 'Could not load transactions');
    return PageResult.parse(res, TransactionItem.fromJson);
  }

  Future<PageResult<PartySummary>> getParties({
    PartyType? type,
    String? search,
    int page = 0,
    int size = 30,
  }) async {
    final res = await _get(ApiConstants.parties, {
      'type': type?.code ?? 'ALL',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': page,
      'size': size,
    }, 'Could not load parties');
    return PageResult.parse(res, PartySummary.fromJson);
  }

  /// Creates a customer or supplier with the basic fields.
  Future<void> createParty({
    required PartyType type,
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    await _send(
      () => _dio.post(
        type == PartyType.customer ? ApiConstants.customers : ApiConstants.suppliers,
        data: {
          'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        },
      ),
      'Could not save the party',
    );
  }

  Future<void> createTransfer({
    required PartySummary from,
    required PartySummary to,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    await _send(
      () => _dio.post(ApiConstants.partyTransfers, data: {
        'from': {'type': from.type.code, 'id': from.id},
        'to': {'type': to.type.code, 'id': to.id},
        'amount': amount,
        'date': day(date),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
      'Could not save the transfer',
    );
  }

  Future<ReportSummary> getReportSummary({required DateTime from, required DateTime to}) async {
    final res = await _get(
      ApiConstants.reportSummary,
      {'from': day(from), 'to': day(to)},
      'Could not load the report',
    );
    return ReportSummary.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Open receivables (balance > 0) for a customer, oldest first.
  Future<List<ReceivableItem>> getOpenReceivables(String customerId) async {
    final res = await _get(
      '${ApiConstants.apiPrefix}/accounting/receivables',
      {'customerId': customerId, 'size': 100, 'sort': 'createdAt,asc'},
      'Could not load what this customer owes',
    );
    return PageResult.parse(res, ReceivableItem.fromJson)
        .items
        .where((r) => r.balance > 0)
        .toList();
  }

  Future<void> recordPaymentIn({
    required String receivableId,
    required double amount,
    required DateTime date,
    required String method,
    String? reference,
  }) async {
    await _send(
      () => _dio.post(ApiConstants.receivablePayments(receivableId), data: {
        'amount': amount,
        'paymentDate': day(date),
        'paymentMethod': method,
        if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
      }),
      'Could not record the payment',
    );
  }

  /// Creates a product (needs `manage_products`).
  Future<void> createProduct({
    required String name,
    required double sellingPrice,
    double? costPrice,
    String? sku,
    String? barcode,
    String? categoryId,
    double? taxRate,
    bool trackInventory = true,
  }) async {
    await _send(
      () => _dio.post(ApiConstants.products, data: {
        'name': name.trim(),
        'sellingPrice': sellingPrice,
        'costPrice': ?costPrice,
        if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
        if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        'categoryId': ?categoryId,
        'taxRate': ?taxRate,
        'trackInventory': trackInventory,
      }),
      'Could not save the product',
    );
  }

  /// Downloads an export. [format] is `pdf` or `xlsx`.
  Future<DownloadedFile> download(
    String path, {
    Map<String, dynamic> query = const {},
    required String fallbackName,
  }) async {
    try {
      final res = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes, headers: {'Accept': '*/*'}),
      );
      final disposition = res.headers.value('content-disposition') ?? '';
      final match = RegExp(r'filename\*?="?([^";]+)"?').firstMatch(disposition);
      final type = res.headers.value('content-type') ?? 'application/octet-stream';
      return DownloadedFile(
        bytes: Uint8List.fromList(res.data ?? const []),
        fileName: match?.group(1) ?? fallbackName,
        mimeType: type.split(';').first,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: 'Could not download the file',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Object?> _get(String path, Map<String, dynamic> query, String fallback) async {
    final res = await _send(() => _dio.get(path, queryParameters: query), fallback);
    return unwrapEnvelope(res.data);
  }

  Future<Response> _send(Future<Response> Function() call, String fallback) async {
    try {
      return await call();
    } on DioException catch (e) {
      final body = e.response?.data;
      throw ServerException(
        message: body is Map && body['message'] is String ? body['message'] as String : fallback,
        statusCode: e.response?.statusCode,
      );
    }
  }
}
