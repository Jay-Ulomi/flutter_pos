import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/sale_models.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import 'money_text.dart';

/// "Additional Charges" block on Confirm Sale: the cart's charges with a
/// remove button each, and a pill to add one (up to [SaleCharge.maxPerSale]).
///
/// [priced] are the server-priced charges from a fresh preview, used for the
/// tax shown when available.
class AdditionalChargesSection extends StatelessWidget {
  const AdditionalChargesSection({super.key, required this.cart, this.priced = const []});

  final CartState cart;
  final List<SaleCharge> priced;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cart.charges.length; i++)
          Padding(
            key: ValueKey('charge-$i'),
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cart.charges[i].taxRate > 0
                        ? '${cart.charges[i].name} (+${Formatters.percentage(cart.charges[i].taxRate)} tax)'
                        : cart.charges[i].name,
                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                MoneyText(
                  i < priced.length ? priced[i].total : cart.charges[i].total,
                  style: textTheme.bodyMedium,
                ),
                IconButton(
                  tooltip: 'Remove charge',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                  onPressed: () => context.read<CartBloc>().add(CartChargeRemoved(i)),
                ),
              ],
            ),
          ),
        if (cart.charges.length < SaleCharge.maxPerSale)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                key: const ValueKey('add-charge'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                  side: BorderSide.none,
                ),
                onPressed: () async {
                  final charge = await showAddChargeSheet(context);
                  if (charge != null && context.mounted) {
                    context.read<CartBloc>().add(CartChargeAdded(charge));
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.tr('sale.add_charge')),
              ),
            ),
          ),
      ],
    );
  }
}

/// Name / amount / tax-rate sheet. Returns the charge, or null.
Future<SaleCharge?> showAddChargeSheet(BuildContext context) {
  return showModalBottomSheet<SaleCharge>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddChargeSheet(),
  );
}

class _AddChargeSheet extends StatefulWidget {
  const _AddChargeSheet();

  @override
  State<_AddChargeSheet> createState() => _AddChargeSheetState();
}

class _AddChargeSheetState extends State<_AddChargeSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _tax = TextEditingController(text: '0');

  static const _presets = ['Delivery', 'Packaging', 'Service', 'Installation'];

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _tax.dispose();
    super.dispose();
  }

  double? _num(String v) => double.tryParse(v.replaceAll(RegExp(r'[,\s]'), ''));

  void _save() {
    if (_form.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      SaleCharge(name: _name.text.trim(), amount: _num(_amount.text)!, taxRate: _num(_tax.text) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('sale.additional_charges'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in _presets)
                      ActionChip(label: Text(p), onPressed: () => setState(() => _name.text = p)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('charge-name'),
                  controller: _name,
                  maxLength: 100,
                  decoration: InputDecoration(hintText: context.tr('sale.charge_name'), counterText: ''),
                  validator: (v) => (v ?? '').trim().isEmpty ? context.tr('sale.charge_name') : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: const ValueKey('charge-amount'),
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: digits,
                        decoration: InputDecoration(prefixText: '${Formatters.currencySymbol} '),
                        validator: (v) {
                          final a = _num(v ?? '');
                          return a == null || a <= 0 ? context.tr('common.amount') : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _tax,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: digits,
                        decoration: InputDecoration(
                          suffixText: '%',
                          helperText: context.tr('sale.charge_tax'),
                        ),
                        validator: (v) {
                          final t = _num(v ?? '0');
                          return t == null || t < 0 || t > 100 ? '0–100' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('charge-save'),
                  onPressed: _save,
                  child: Text(context.tr('sale.add_charge')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
