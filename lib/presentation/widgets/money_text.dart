import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import '../blocs/app_settings/app_settings_cubit.dart';

class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String? symbol;
  final bool compact;

  /// Masked when App Settings privacy mode is on. Pass false for amounts the
  /// customer must see (e.g. the change due on the customer display).
  final bool sensitive;

  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.symbol,
    this.compact = false,
    this.sensitive = true,
  });

  @override
  Widget build(BuildContext context) {
    final masked = sensitive &&
        context.select<AppSettingsCubit?, bool>((c) => c?.state.privacyMode ?? false);
    final text = masked
        ? Formatters.masked(symbol: symbol)
        : compact
            ? Formatters.currencyCompact(amount, symbol: symbol)
            : Formatters.currency(amount, symbol: symbol);
    // Tabular (monospaced) figures so amounts align digit-for-digit in lists,
    // totals and receipts — the key legibility win for a POS.
    const tabular = [FontFeature.tabularFigures()];
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontFeatures: tabular),
    );
  }
}
