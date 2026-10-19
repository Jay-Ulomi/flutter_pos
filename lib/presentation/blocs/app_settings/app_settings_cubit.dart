import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/utils/formatters.dart';

/// Loads, applies and persists [AppSettings].
///
/// Every change also pushes the number/date/currency preferences into
/// [Formatters] so existing screens pick them up without extra plumbing.
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit() : super(const AppSettings()) {
    Formatters.configure(state);
  }

  static const _p = 'app_settings.';
  // Pre-redesign ThemeCubit key, read so an earlier choice survives.
  static const _legacyThemeKey = 'theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    const d = AppSettings();
    final theme = prefs.getString('${_p}theme') ?? prefs.getString(_legacyThemeKey);
    final loaded = AppSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => d.themeMode),
      textScale: prefs.getDouble('${_p}text_scale') ?? d.textScale,
      languageCode: prefs.getString('${_p}language') ?? d.languageCode,
      datePattern: prefs.getString('${_p}date_pattern') ?? d.datePattern,
      use24Hour: prefs.getBool('${_p}use_24h') ?? d.use24Hour,
      numberStyle: NumberStyle.values.firstWhere(
        (s) => s.name == prefs.getString('${_p}number_style'),
        orElse: () => d.numberStyle,
      ),
      currencySymbol: prefs.getString('${_p}currency_symbol') ?? d.currencySymbol,
      symbolAfterAmount: prefs.getBool('${_p}symbol_after') ?? d.symbolAfterAmount,
      showDecimals: prefs.getBool('${_p}show_decimals') ?? d.showDecimals,
      privacyMode: prefs.getBool('${_p}privacy') ?? d.privacyMode,
      appLockEnabled: prefs.getBool('${_p}app_lock') ?? d.appLockEnabled,
      lockAfterMinutes: prefs.getInt('${_p}lock_after') ?? d.lockAfterMinutes,
    );
    Formatters.configure(loaded);
    if (!isClosed) emit(loaded);
  }

  Future<void> update(AppSettings next) async {
    if (next == state) return;
    Formatters.configure(next);
    emit(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_p}theme', next.themeMode.name);
    await prefs.setDouble('${_p}text_scale', next.textScale);
    await prefs.setString('${_p}language', next.languageCode);
    await prefs.setString('${_p}date_pattern', next.datePattern);
    await prefs.setBool('${_p}use_24h', next.use24Hour);
    await prefs.setString('${_p}number_style', next.numberStyle.name);
    await prefs.setString('${_p}currency_symbol', next.currencySymbol);
    await prefs.setBool('${_p}symbol_after', next.symbolAfterAmount);
    await prefs.setBool('${_p}show_decimals', next.showDecimals);
    await prefs.setBool('${_p}privacy', next.privacyMode);
    await prefs.setBool('${_p}app_lock', next.appLockEnabled);
    await prefs.setInt('${_p}lock_after', next.lockAfterMinutes);
  }

  Future<void> togglePrivacy() => update(state.copyWith(privacyMode: !state.privacyMode));
}
