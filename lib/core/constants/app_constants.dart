import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'POS Terminal';
  static const String appVersion = '1.0.0';

  // Brand colors — delegate to BrandColors for a single source of truth.
  // Prefer reading Theme.of(context).colorScheme in widgets; keep these
  // constants only for places where no BuildContext is available.
  static const Color primaryColor = BrandColors.primary;
  static const Color secondaryColor = BrandColors.secondary;
  static const Color accentColor = BrandColors.tertiary;
  static const Color errorColor = BrandColors.error;
  static const Color successColor = BrandColors.success;
  static const Color warningColor = BrandColors.warning;

  // Sync / connectivity status
  static const Color onlineColor = BrandColors.online;
  static const Color syncingColor = BrandColors.syncing;
  static const Color offlineColor = BrandColors.offline;

  // Defaults
  static const String defaultCurrency = 'TZS';
  static const String defaultCurrencySymbol = 'TZS';

  // Pagination
  static const int defaultPageSize = 50;

  // Sync cadence
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration productCacheDuration = Duration(hours: 1);
}
