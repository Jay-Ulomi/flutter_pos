import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/product_models.dart';
import '../cart/cart_state.dart';

class HeldSale extends Equatable {
  final String id;
  final String label;
  final List<CartLine> lines;
  final double discount;
  final String? customerId;
  final String? customerName;
  final DateTime heldAt;

  const HeldSale({
    required this.id,
    required this.label,
    required this.lines,
    this.discount = 0,
    this.customerId,
    this.customerName,
    required this.heldAt,
  });

  int get itemCount => lines.length;

  double get total {
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.lineSubtotal);
    final tax = lines.fold(0.0, (sum, l) => sum + l.lineTax);
    return subtotal + tax - discount;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'lines': lines.map(_lineToJson).toList(),
    'discount': discount,
    'customerId': customerId,
    'customerName': customerName,
    'heldAt': heldAt.toIso8601String(),
  };

  factory HeldSale.fromJson(Map<String, dynamic> json) {
    return HeldSale(
      id: json['id'] as String,
      label: json['label'] as String,
      lines: (json['lines'] as List).map(_lineFromJson).toList(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      heldAt: DateTime.parse(json['heldAt'] as String),
    );
  }

  static Map<String, dynamic> _lineToJson(CartLine l) => {
    'product': {
      'id': l.product.id,
      'name': l.product.name,
      'sellingPrice': l.product.sellingPrice,
      'taxRate': l.product.taxRate,
      'barcode': l.product.barcode,
      'sku': l.product.sku,
    },
    'quantity': l.quantity,
    'discount': l.discount,
    'isPercentDiscount': l.isPercentDiscount,
  };

  static CartLine _lineFromJson(dynamic json) {
    final p = json['product'] as Map<String, dynamic>;
    return CartLine(
      product: Product(
        id: p['id'] as String,
        name: p['name'] as String,
        sellingPrice: (p['sellingPrice'] as num).toDouble(),
        taxRate: (p['taxRate'] as num?)?.toDouble(),
        barcode: p['barcode'] as String?,
        sku: p['sku'] as String?,
      ),
      quantity: (json['quantity'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      isPercentDiscount: json['isPercentDiscount'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id];
}

class HeldSalesCubit extends Cubit<List<HeldSale>> {
  HeldSalesCubit() : super(const []) {
    _load();
  }

  static const _key = 'held_sales';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = <HeldSale>[];
      for (final e in decoded) {
        // Skip individual corrupt/schema-drifted entries instead of losing all.
        try {
          if (e is Map<String, dynamic>) list.add(HeldSale.fromJson(e));
        } catch (_) {}
      }
      emit(list);
    } catch (_) {
      // Corrupt blob — reset rather than crash on every launch.
      await prefs.remove(_key);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> hold(CartState cart, {String? label}) async {
    if (cart.isEmpty) return;
    final sale = HeldSale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label:
          label ??
          (cart.lines.length == 1
              ? cart.lines.first.product.name
              : '${cart.lines.length} items'),
      lines: cart.lines,
      discount: cart.discount,
      customerId: cart.selectedCustomerId,
      customerName: cart.selectedCustomerName,
      heldAt: DateTime.now(),
    );
    emit([...state, sale]);
    await _persist();
  }

  Future<void> remove(String id) async {
    emit(state.where((h) => h.id != id).toList());
    await _persist();
  }
}
