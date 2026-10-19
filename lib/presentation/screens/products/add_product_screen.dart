import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/product_models.dart';
import '../../../di/injection.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../widgets/aduinola/ui.dart';
import '../transactions/payment_forms.dart' show parseAmount;

/// "Add New Product" — basic fields; needs `manage_products`.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.remote});
  final FeedRemoteDataSource? remote;

  static const permission = 'manage_products';

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final FeedRemoteDataSource _remote = widget.remote ?? sl<FeedRemoteDataSource>();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _cost = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _tax = TextEditingController();
  String? _categoryId;
  bool _track = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _price, _cost, _sku, _barcode, _tax]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _remote.createProduct(
        name: _name.text,
        sellingPrice: parseAmount(_price.text)!,
        costPrice: parseAmount(_cost.text),
        sku: _sku.text,
        barcode: _barcode.text,
        categoryId: _categoryId,
        taxRate: parseAmount(_tax.text),
        trackInventory: _track,
      );
      if (!mounted) return;
      // Pull the new product into the offline catalogue.
      context.read<ProductBloc?>()?.add(const ProductSyncRequested());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('common.done'))));
      context.canPop() ? context.pop(true) : context.go('/products');
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.tr('common.load_failed'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  TextFormField _money(TextEditingController c, {bool required = false, Key? key}) => TextFormField(
        key: key,
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(prefixText: '${Formatters.currencySymbol} '),
        validator: (v) {
          if ((v ?? '').trim().isEmpty) return required ? context.tr('inv.price') : null;
          final a = parseAmount(v!);
          return a == null || a < 0 ? context.tr('common.amount') : null;
        },
      );

  @override
  Widget build(BuildContext context) {
    final allowed = context.select<AuthBloc?, bool>(
      (b) => b?.state.can(AddProductScreen.permission) ?? true,
    );
    final categories = context.select<ProductBloc?, List<Category>>(
      (b) => b?.state.categories ?? const [],
    );
    final cs = Theme.of(context).colorScheme;
    return GradientScaffold(
      title: context.tr('inv.add_product'),
      body: !allowed
          ? MessageView(icon: Icons.lock_outline_rounded, message: context.tr('inv.no_permission'))
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _label(context.tr('inv.product_name')),
                        TextFormField(
                          key: const ValueKey('product-name'),
                          controller: _name,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? context.tr('inv.product_name') : null,
                        ),
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label(context.tr('inv.price')),
                              _money(_price, required: true, key: const ValueKey('product-price')),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label(context.tr('inv.cost')),
                              _money(_cost),
                            ]),
                          ),
                        ]),
                        if (categories.isNotEmpty) ...[
                          _label(context.tr('inv.category')),
                          DropdownButtonFormField<String?>(
                            initialValue: _categoryId,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('—')),
                              for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                            ],
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ],
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label(context.tr('inv.sku')),
                              TextFormField(controller: _sku),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label(context.tr('inv.barcode')),
                              TextFormField(controller: _barcode, keyboardType: TextInputType.number),
                            ]),
                          ),
                        ]),
                        _label(context.tr('sale.charge_tax')),
                        TextFormField(
                          controller: _tax,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(suffixText: '%', hintText: '18'),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _track,
                          onChanged: (v) => setState(() => _track = v),
                          title: const Text('Track stock'),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_error!, style: TextStyle(color: cs.error)),
                          ),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.canPop() ? context.pop() : context.go('/products'),
                              child: Text(context.tr('common.cancel')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              key: const ValueKey('product-save'),
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Text(context.tr('common.save')),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
