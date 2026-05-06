import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Set at runtime with:
  // flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:8090
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _localFallbackBaseUrl = 'http://127.0.0.1:8090';

  // Business Admin web URL (for billing / subscription management links).
  // Set via: flutter run --dart-define=BUSINESS_ADMIN_URL=https://admin.yourapp.com
  static const String _configuredAdminUrl = String.fromEnvironment(
    'BUSINESS_ADMIN_URL',
    defaultValue: '',
  );
  static const String _localFallbackAdminUrl = 'http://127.0.0.1:5175';

  // Deployment-safe behavior:
  // - Release: API_BASE_URL must be provided.
  // - Debug/Profile: default to localhost for local development.
  static String get baseUrl {
    return resolveBaseUrl(
      envValue: dotenv.env['API_BASE_URL'],
      defineValue: _configuredBaseUrl,
      releaseMode: kReleaseMode,
    );
  }

  static String get businessAdminUrl {
    final fromEnv = _sanitizeBaseUrl(dotenv.env['BUSINESS_ADMIN_URL']);
    if (fromEnv != null) return fromEnv;
    final fromDefine = _sanitizeBaseUrl(_configuredAdminUrl);
    if (fromDefine != null) return fromDefine;
    if (kReleaseMode) {
      throw StateError(
        'Missing BUSINESS_ADMIN_URL. Set it in .env or --dart-define=BUSINESS_ADMIN_URL=https://admin.yourapp.com',
      );
    }
    return _localFallbackAdminUrl;
  }

  static String resolveBaseUrl({
    String? envValue,
    String? defineValue,
    required bool releaseMode,
  }) {
    final fromEnv = _sanitizeBaseUrl(envValue);
    if (fromEnv != null) return fromEnv;

    final fromDefine = _sanitizeBaseUrl(defineValue);
    if (fromDefine != null) return fromDefine;

    if (releaseMode) {
      throw StateError(
        'Missing API_BASE_URL. Set it in .env or --dart-define=API_BASE_URL=https://your-host',
      );
    }
    return _localFallbackBaseUrl;
  }

  static String? _sanitizeBaseUrl(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static const String apiPrefix = '/api';

  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String refreshToken =
      '$apiPrefix/auth/refresh'; // backend: /api/auth/refresh
  static const String switchContext = '$apiPrefix/auth/switch-context';
  static const String me = '$apiPrefix/auth/me';

  // Business
  static const String businesses = '$apiPrefix/businesses';
  static String branches(String businessId) =>
      '$apiPrefix/businesses/$businessId/branches';
  static const String tenantFeatures = '$apiPrefix/tenant-features';

  // Products
  static const String products = '$apiPrefix/products';
  static const String categories = '$apiPrefix/categories';
  static const String productByBarcode = '$apiPrefix/products/barcode';

  // Sales — backend controller: /api/pos/sales
  static const String sales = '$apiPrefix/pos/sales';
  static const String returns = '$apiPrefix/pos/returns';

  // Sessions — backend controller: /api/pos/sessions
  static const String sessions = '$apiPrefix/pos/sessions';
  static const String openSession = '$apiPrefix/pos/sessions/open';

  // Inventory
  static const String inventory = '$apiPrefix/inventory';
  static String stockLevels(String branchId) =>
      '$apiPrefix/inventory/branches/$branchId/stock';

  // Customers
  static const String customers = '$apiPrefix/customers';
  static const String customerGroups = '$apiPrefix/customer-groups';

  // Offline Sync
  static const String syncBootstrap = '$apiPrefix/sync/bootstrap';
  static const String syncDelta = '$apiPrefix/sync/delta';
  static const String syncSales = '$apiPrefix/sync/sales';
  static const String syncLaundryActions = '$apiPrefix/sync/laundry-actions';

  // Subscriptions
  static const String subscriptionCurrent = '$apiPrefix/subscriptions/current';

  // Laundry
  static const String laundryOrders = '$apiPrefix/laundry/orders';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
