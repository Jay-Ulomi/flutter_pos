import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomItemResult {
  final String name;
  final double price;
  final double quantity;
  const CustomItemResult({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

Future<CustomItemResult?> showCustomItemDialog(BuildContext context) {
  return showDialog<CustomItemResult>(
    context: context,
    builder: (_) => const _CustomItemDialog(),
  );
}

class _CustomItemDialog extends StatefulWidget {
  const _CustomItemDialog();

  @override
  State<_CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<_CustomItemDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CustomItemResult(
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid price';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add to Cart')),
      ],
    );
  }
}
