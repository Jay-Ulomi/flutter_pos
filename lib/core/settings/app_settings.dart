import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// How digits are grouped and which character separates decimals.
enum NumberStyle {
  /// 1,234,567.89
  commaDot,

  /// 1.234.567,89
  dotComma,

  /// 1 234 567.89
  spaceDot,
}

/// Device-local display and security preferences (App Settings screen).
///
/// Persisted in SharedPreferences by AppSettingsCubit; nothing here is sent
/// to the server. The app-lock PIN itself lives in secure storage, hashed —
/// only the on/off flag and timeout are kept here.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.textScale = 1.0,
    this.languageCode = 'en',
    this.datePattern = 'dd/MM/yyyy',
    this.use24Hour = true,
    this.numberStyle = NumberStyle.commaDot,
    this.currencySymbol = 'TZS',
    this.symbolAfterAmount = false,
    this.showDecimals = true,
    this.privacyMode = false,
    this.appLockEnabled = false,
    this.lockAfterMinutes = 0,
  });

  final ThemeMode themeMode;

  /// Multiplier on the system text size: 0.9 small … 1.3 extra large.
  final double textScale;

  /// 'en' or 'sw'.
  final String languageCode;
  final String datePattern;
  final bool use24Hour;
  final NumberStyle numberStyle;
  final String currencySymbol;
  final bool symbolAfterAmount;
  final bool showDecimals;

  /// Masks money amounts on screen (never on printed receipts).
  final bool privacyMode;
  final bool appLockEnabled;

  /// Minutes in the background before the lock screen shows; 0 = immediately.
  final int lockAfterMinutes;

  static const datePatterns = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'd MMM yyyy'];
  static const textScales = [0.9, 1.0, 1.15, 1.3];
  static const languages = ['en', 'sw'];
  static const lockTimeouts = [0, 1, 5, 15];

  Locale get locale => Locale(languageCode);
  String get timePattern => use24Hour ? 'HH:mm' : 'h:mm a';

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    String? languageCode,
    String? datePattern,
    bool? use24Hour,
    NumberStyle? numberStyle,
    String? currencySymbol,
    bool? symbolAfterAmount,
    bool? showDecimals,
    bool? privacyMode,
    bool? appLockEnabled,
    int? lockAfterMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      languageCode: languageCode ?? this.languageCode,
      datePattern: datePattern ?? this.datePattern,
      use24Hour: use24Hour ?? this.use24Hour,
      numberStyle: numberStyle ?? this.numberStyle,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      symbolAfterAmount: symbolAfterAmount ?? this.symbolAfterAmount,
      showDecimals: showDecimals ?? this.showDecimals,
      privacyMode: privacyMode ?? this.privacyMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      lockAfterMinutes: lockAfterMinutes ?? this.lockAfterMinutes,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        textScale,
        languageCode,
        datePattern,
        use24Hour,
        numberStyle,
        currencySymbol,
        symbolAfterAmount,
        showDecimals,
        privacyMode,
        appLockEnabled,
        lockAfterMinutes,
      ];
}
