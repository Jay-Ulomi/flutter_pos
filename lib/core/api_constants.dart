class ApiConstants {
  ApiConstants._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static String get baseUrl => _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : 'https://pos.chita.co.tz/api';

  // Auth
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Business
  static const String businesses = '/businesses';
  static const String switchContext = '/auth/switch-context';

  // Branches
  static String branches(int businessId) => '/businesses/$businessId/branches';

  // Products
  static String products(int businessId) => '/businesses/$businessId/products';
  static String productByBarcode(int businessId, String barcode) =>
      '/businesses/$businessId/products/barcode/$barcode';

  // Categories
  static String categories(int businessId) =>
      '/businesses/$businessId/categories';

  // Sales
  static String sales(int businessId) => '/businesses/$businessId/sales';
  static String saleById(int businessId, int saleId) =>
      '/businesses/$businessId/sales/$saleId';
  static String saleByNumber(int businessId, String saleNumber) =>
      '/businesses/$businessId/sales/number/$saleNumber';
  static String saleReceipt(int businessId, int saleId) =>
      '/businesses/$businessId/sales/$saleId/receipt';
  static String saleReturn(int businessId, int saleId) =>
      '/businesses/$businessId/sales/$saleId/return';

  // Cash Sessions
  static String sessions(int businessId, int branchId) =>
      '/businesses/$businessId/branches/$branchId/sessions';
  static String activeSession(int businessId, int branchId) =>
      '/businesses/$businessId/branches/$branchId/sessions/active';
  static String closeSession(int businessId, int branchId, int sessionId) =>
      '/businesses/$businessId/branches/$branchId/sessions/$sessionId/close';
  static String cashMovement(int businessId, int branchId, int sessionId) =>
      '/businesses/$businessId/branches/$branchId/sessions/$sessionId/movements';
  static String shiftSummary(int businessId, int branchId, int sessionId) =>
      '/businesses/$businessId/branches/$branchId/sessions/$sessionId/summary';

  // Inventory / Stock
  static String inventory(int businessId, int branchId) =>
      '/businesses/$businessId/branches/$branchId/inventory';

  // Customers
  static String customers(int businessId) =>
      '/businesses/$businessId/customers';
}
