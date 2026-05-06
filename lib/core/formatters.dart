import 'package:intl/intl.dart';
import 'app_constants.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: AppConstants.decimalPlaces,
  );

  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  static final _receiptDateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String time(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String receiptDate(DateTime dateTime) {
    return _receiptDateFormat.format(dateTime);
  }

  static String quantity(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
