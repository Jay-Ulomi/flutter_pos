import 'package:intl/intl.dart';

import '../settings/app_settings.dart';

class Formatters {
  Formatters._();

  static NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final _quantityFormat = NumberFormat('#,##0.###');
  static DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static DateFormat _timeFormat = DateFormat('HH:mm');
  static NumberStyle _numberStyle = NumberStyle.commaDot;
  static String _symbol = 'TZS';
  static bool _symbolAfter = false;

  /// Applies the App Settings display preferences (number style, currency
  /// symbol and position, date/time patterns). Called by AppSettingsCubit.
  static void configure(AppSettings s) {
    _currencyFormat = NumberFormat(s.showDecimals ? '#,##0.00' : '#,##0');
    _dateFormat = DateFormat(s.datePattern);
    _timeFormat = DateFormat(s.timePattern);
    _dateTimeFormat = DateFormat('${s.datePattern} ${s.timePattern}');
    _numberStyle = s.numberStyle;
    _symbol = s.currencySymbol;
    _symbolAfter = s.symbolAfterAmount;
  }

  static String get currencySymbol => _symbol;

  /// Rewrites en-style "1,234.56" into the chosen [NumberStyle].
  static String _localize(String en) {
    switch (_numberStyle) {
      case NumberStyle.commaDot:
        return en;
      case NumberStyle.dotComma:
        return en.replaceAll(',', '\u0000').replaceAll('.', ',').replaceAll('\u0000', '.');
      case NumberStyle.spaceDot:
        return en.replaceAll(',', ' ');
    }
  }

  static String _withSymbol(String number, String? symbol) {
    final sym = symbol ?? _symbol;
    if (sym.isEmpty) return number;
    return _symbolAfter ? '$number $sym' : '$sym $number';
  }

  /// Formats amount with grouping, e.g. "2,400.00"
  static String money(double amount) {
    return _localize(_currencyFormat.format(amount));
  }

  static String currency(double amount, {String? symbol}) {
    return _withSymbol(money(amount), symbol);
  }

  static String currencyCompact(double amount, {String? symbol}) {
    if (amount >= 1000000) {
      return _withSymbol(_localize('${(amount / 1000000).toStringAsFixed(1)}M'), symbol);
    } else if (amount >= 1000) {
      return _withSymbol(_localize('${(amount / 1000).toStringAsFixed(1)}K'), symbol);
    }
    return currency(amount, symbol: symbol);
  }

  /// Privacy-mode placeholder shown instead of an amount.
  static String masked({String? symbol}) => _withSymbol('••••', symbol);

  static String quantity(double qty) {
    return _localize(_quantityFormat.format(qty));
  }

  static String date(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String dateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  static String time(DateTime dt) {
    return _timeFormat.format(dt);
  }

  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String saleNumber(String? number) {
    return number ?? '---';
  }
}
