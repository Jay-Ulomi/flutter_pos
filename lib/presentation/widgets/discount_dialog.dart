import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscountResult {
  final double value;
  final bool isPercent;
  const DiscountResult({required this.value, required this.isPercent});
}

/// Shows a dialog to apply a % or fixed discount to a cart line.
/// Returns `null` if cancelled, or a [DiscountResult].
Future<DiscountResult?> showDiscountDialog(
  BuildContext context, {
  required String productName,
  double currentDiscount = 0,
  bool currentIsPercent = false,
}) {
  return showDialog<DiscountResult>(
    context: context,
    builder: (ctx) => _DiscountDialog(
      productName: productName,
      currentDiscount: currentDiscount,
      currentIsPercent: currentIsPercent,
    ),
  );
}

class _DiscountDialog extends StatefulWidget {
  final String productName;
  final double currentDiscount;
  final bool currentIsPercent;

  const _DiscountDialog({
    required this.productName,
    required this.currentDiscount,
    required this.currentIsPercent,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late bool _isPercent = widget.currentIsPercent;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentDiscount > 0
          ? widget.currentDiscount.toStringAsFixed(
              widget.currentDiscount == widget.currentDiscount.floor() ? 0 : 2,
            )
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply() {
    final value = double.tryParse(_ctrl.text) ?? 0;
    Navigator.of(
      context,
    ).pop(DiscountResult(value: value, isPercent: _isPercent));
  }

  void _clear() {
    Navigator.of(context).pop(const DiscountResult(value: 0, isPercent: false));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Item Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Percent %')),
              ButtonSegment(value: false, label: Text('Fixed')),
            ],
            selected: {_isPercent},
            onSelectionChanged: (s) => setState(() => _isPercent = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _isPercent ? 'Discount %' : 'Discount amount',
              prefixIcon: Icon(_isPercent ? Icons.percent : Icons.attach_money),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ],
      ),
      actions: [
        if (widget.currentDiscount > 0)
          TextButton(
            onPressed: _clear,
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }
}
