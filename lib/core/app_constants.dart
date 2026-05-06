import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'POS Terminal';
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';
  static const int decimalPlaces = 2;
  static const double defaultTaxRate = 0.16;
  static const int lowStockThreshold = 10;
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Colors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF00897B);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color surfaceColor = Color(0xFFF5F5F5);

  // Sync status colors
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color syncingColor = Color(0xFFFF9800);
  static const Color offlineColor = Color(0xFFF44336);
}
