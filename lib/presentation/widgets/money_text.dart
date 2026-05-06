import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String? symbol;
  final bool compact;

  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.symbol,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = compact
        ? Formatters.currencyCompact(amount, symbol: symbol ?? 'TZS')
        : Formatters.currency(amount, symbol: symbol ?? 'TZS');
    return Text(text, style: style);
  }
}
