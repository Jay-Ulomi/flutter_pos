import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat('#,##0.00');
  static final _quantityFormat = NumberFormat('#,##0.###');
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFormat = DateFormat('HH:mm');

  /// Formats amount with commas, e.g. "2,400.00"
  static String money(double amount) {
    return _currencyFormat.format(amount);
  }

  static String currency(double amount, {String symbol = 'TZS'}) {
    return '$symbol ${_currencyFormat.format(amount)}';
  }

  static String currencyCompact(double amount, {String symbol = 'TZS'}) {
    if (amount >= 1000000) {
      return '$symbol ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return currency(amount, symbol: symbol);
  }

  static String quantity(double qty) {
    return _quantityFormat.format(qty);
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
