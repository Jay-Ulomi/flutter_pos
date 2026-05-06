import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/network_info.dart';
import '../../../core/utils/laundry_receipt_pdf.dart';
import '../../../data/datasources/remote/laundry_remote.dart';
import '../../../data/datasources/local/laundry_local.dart';
import '../../../data/models/business_models.dart';
import '../../../data/models/customer_models.dart';
import '../../../data/models/laundry_models.dart';
import '../../../data/models/product_models.dart';
import '../../../data/models/sync_models.dart';
import '../../../di/injection.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_event.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_shell.dart';
import '../../widgets/customer_picker_sheet.dart';
import '../../../core/utils/formatters.dart';

const String _priceTierNormal = 'NORMAL';
const String _priceTierExpress = 'EXPRESS';
const List<String> _supportedPriceTiers = <String>[
  _priceTierNormal,
  _priceTierExpress,
];
const List<LaundryPaymentMethod> _supportedLaundryPaymentMethods =
    <LaundryPaymentMethod>[
      LaundryPaymentMethod.cash,
      LaundryPaymentMethod.card,
      LaundryPaymentMethod.mobileMoney,
      LaundryPaymentMethod.bankTransfer,
    ];

class LaundryOrdersScreen extends StatefulWidget {
  const LaundryOrdersScreen({super.key, this.ordersOnly = false});

  final bool ordersOnly;

  @override
  State<LaundryOrdersScreen> createState() => _LaundryOrdersScreenState();
}

class _LaundryOrdersScreenState extends State<LaundryOrdersScreen> {
  static const Uuid _uuid = Uuid();
  final LaundryRemoteDataSource _remote = sl<LaundryRemoteDataSource>();
  final LaundryLocalDataSource _laundryLocal = sl<LaundryLocalDataSource>();
  final ProductRepository _productRepository = sl<ProductRepository>();
  final NetworkInfo _networkInfo = sl<NetworkInfo>();
  final _searchCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  final _ticketItemsScrollCtrl = ScrollController();
  Customer? _selectedCustomer;

  bool _loading = true;
  String? _error;
  LaundryPage _page = const LaundryPage();
  int _pageIndex = 0;
  final int _pageSize = 15;
  LaundryOrderStatus? _status;
  List<Product> _products = const [];
  DateTime? _dueDate;
  List<_DraftLaundryItem> _draftItems = const [];
  bool _submittingTicket = false;
  bool _receiptBusy = false;
  String _selectedPriceTier = _priceTierNormal;
  LaundryPaymentMethod _initialPaymentMethod = LaundryPaymentMethod.cash;
  final _initialPaymentReferenceCtrl = TextEditingController();
  LaundryOrder? _createdTicketForPrint;

  @override
  void initState() {
    super.initState();
    _draftItems = const [];
    _load();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _productSearchCtrl.dispose();
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    _initialPaymentReferenceCtrl.dispose();
    _ticketItemsScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      var products = await _productRepository.getProducts();
      products = products.where((p) => p.isActive).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() => _products = products);
    } catch (_) {
      // Ignore here to keep orders usable even when product fetch fails.
    }
  }

  Future<void> _load() async {
    final branchId = context.read<AuthBloc>().state.branchId;
    if (branchId == null || branchId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No branch selected.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _remote.getOrders(
        branchId: branchId,
        status: _status,
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        page: _pageIndex,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createTicket() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active products found. Create laundry products first.',
          ),
        ),
      );
      return;
    }

    final request = await showDialog<_CreateLaundryTicketData>(
      context: context,
      builder: (_) => _CreateLaundryTicketDialog(
        products: _products,
        initialPriceTier: _selectedPriceTier,
        initialPaymentMethod: _initialPaymentMethod,
      ),
    );
    if (request == null || !mounted) return;

    await _submitTicket(request);
  }

  Future<void> _submitTicket(_CreateLaundryTicketData request) async {
    if (!mounted) return;

    LaundryOrder? createdOrder;
    final clientId = _uuid.v4();
    final createOrderPayload = <String, dynamic>{
      'clientId': clientId,
      if (request.customerId != null && request.customerId!.isNotEmpty)
        'customerId': request.customerId,
      if (request.customerName.trim().isNotEmpty)
        'customerName': request.customerName.trim(),
      if (request.customerPhone.trim().isNotEmpty)
        'customerPhone': request.customerPhone.trim(),
      if (request.dueDateIso != null) 'dueDate': request.dueDateIso,
      if (request.notes.trim().isNotEmpty) 'notes': request.notes.trim(),
      'paidAmount': request.paidAmount,
      if (request.paidAmount > 0) 'paymentMethod': request.paymentMethod,
      if (request.paidAmount > 0 && request.paymentReference.trim().isNotEmpty)
        'paymentReference': request.paymentReference.trim(),
      'items': request.items,
    };

    if (_networkInfo.isConnected) {
      try {
        createdOrder = await _remote.createOrder(
          clientId: clientId,
          customerId: request.customerId,
          customerName: request.customerName,
          customerPhone: request.customerPhone,
          dueDateIso: request.dueDateIso,
          notes: request.notes,
          paidAmount: request.paidAmount,
          paymentMethod: request.paidAmount > 0 ? request.paymentMethod : null,
          paymentReference: request.paidAmount > 0
              ? request.paymentReference
              : null,
          items: request.items,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laundry ticket created.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
    } else {
      await _queueLaundryAction(
        actionType: LaundrySyncActionType.createOrder,
        payload: {'createOrder': createOrderPayload},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offline: laundry ticket queued. It will sync automatically.',
          ),
        ),
      );
    }

    _pageIndex = 0;
    await _load();
    if (!mounted) return;
    if (createdOrder != null) {
      final isWide = MediaQuery.of(context).size.width >= 1100;
      if (!widget.ordersOnly && isWide) {
        setState(() => _createdTicketForPrint = createdOrder);
      } else {
        context.push('/laundry/receipt', extra: createdOrder);
      }
    }
  }

  String? get _cashierName {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return null;
    final full = '${user.firstName} ${user.lastName}'.trim();
    return full.isEmpty ? user.email : full;
  }

  Future<Uint8List> _buildLaundryPdfBytes(LaundryOrder order) async {
    final businessState = context.read<BusinessBloc>().state;
    final authState = context.read<AuthBloc>().state;
    final business = businessState.selected;

    final branchId = authState.branchId;
    Branch? branch;
    if (business != null && branchId != null) {
      for (final b in business.branches) {
        if (b.id == branchId) {
          branch = b;
          break;
        }
      }
    }

    return buildLaundryReceiptPdf(
      order,
      businessName: business?.name,
      branchName: branch?.name,
      businessAddress: business?.address,
      businessPhone: business?.phone,
      tinNumber: business?.tinNumber,
      cashierName: _cashierName,
    );
  }

  Future<void> _onPrintCreatedTicket(LaundryOrder order) async {
    setState(() => _receiptBusy = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => _buildLaundryPdfBytes(order),
        name: 'laundry-${order.ticketNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) setState(() => _receiptBusy = false);
    }
  }

  Future<void> _onShareCreatedTicket(LaundryOrder order) async {
    setState(() => _receiptBusy = true);
    try {
      final bytes = await _buildLaundryPdfBytes(order);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'laundry-${order.ticketNumber}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _receiptBusy = false);
    }
  }

  String? _productNameById(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p.name;
    }
    return null;
  }

  Product? _productById(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  double get _draftTotal {
    return _draftItems.fold<double>(0, (sum, item) {
      final qty = double.tryParse(item.quantity) ?? 0;
      final price = double.tryParse(item.unitPrice) ?? 0;
      return sum + (qty * price);
    });
  }

  void _applyPriceTier(String tier) {
    if (!_supportedPriceTiers.contains(tier)) return;
    setState(() {
      _selectedPriceTier = tier;
      _draftItems = _draftItems.map((item) {
        if (item.productId.isEmpty) return item;
        final product = _productById(item.productId);
        if (product == null) return item;
        return item.copyWith(
          unitPrice: product
              .priceForTier(_selectedPriceTier)
              .toStringAsFixed(2),
        );
      }).toList();
    });
  }

  void _addDraftProduct(Product product) {
    final tierPrice = product
        .priceForTier(_selectedPriceTier)
        .toStringAsFixed(2);
    setState(() {
      final index = _draftItems.indexWhere((e) => e.productId == product.id);
      if (index >= 0) {
        final existing = _draftItems[index];
        final qty = (double.tryParse(existing.quantity) ?? 0) + 1;
        _draftItems[index] = existing.copyWith(
          quantity: qty.toStringAsFixed(0),
        );
      } else {
        _draftItems = [
          ..._draftItems,
          _DraftLaundryItem(
            productId: product.id,
            quantity: '1',
            unitPrice: tierPrice,
          ),
        ];
      }
    });
    _scrollTicketItemsToBottom();
  }

  void _removeDraftItem(int index) {
    setState(() {
      if (index < 0 || index >= _draftItems.length) return;
      _draftItems = List.of(_draftItems)..removeAt(index);
    });
  }

  void _changeDraftQuantity(int index, double delta) {
    if (index < 0 || index >= _draftItems.length) return;
    final item = _draftItems[index];
    final current = double.tryParse(item.quantity) ?? 0;
    final next = current + delta;
    if (next <= 0) {
      _removeDraftItem(index);
      return;
    }
    setState(() {
      _draftItems[index] = item.copyWith(
        quantity: next % 1 == 0
            ? next.toStringAsFixed(0)
            : next.toStringAsFixed(2),
      );
    });
  }

  void _scrollTicketItemsToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_ticketItemsScrollCtrl.hasClients) return;
      final max = _ticketItemsScrollCtrl.position.maxScrollExtent;
      _ticketItemsScrollCtrl.animateTo(
        max,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submitDraftTicket() async {
    if (_submittingTicket) return;
    if (_draftItems.where((e) => e.productId.isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product.')),
      );
      return;
    }

    final paidAmount = double.tryParse(_paidCtrl.text.trim());
    if (paidAmount == null || paidAmount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid paid amount.')));
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final item in _draftItems) {
      if (item.productId.isEmpty) continue;
      final qty = double.tryParse(item.quantity);
      final price = double.tryParse(item.unitPrice);
      if (qty == null || qty <= 0 || price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid quantity or price in items.')),
        );
        return;
      }
      items.add({
        'productId': item.productId,
        'quantity': qty,
        'unitPrice': price,
        if (item.notes.trim().isNotEmpty) 'notes': item.notes.trim(),
      });
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product.')),
      );
      return;
    }

    setState(() => _submittingTicket = true);
    try {
      await _submitTicket(
        _CreateLaundryTicketData(
          customerId: _selectedCustomer?.id,
          customerName: _customerCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          dueDateIso: _dueDate != null
              ? '${_dueDate!.year.toString().padLeft(4, '0')}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
              : null,
          notes: _notesCtrl.text.trim(),
          paidAmount: paidAmount,
          paymentMethod: laundryPaymentMethodToApi(_initialPaymentMethod),
          paymentReference: _initialPaymentReferenceCtrl.text.trim(),
          items: items,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedCustomer = null;
        _customerCtrl.clear();
        _phoneCtrl.clear();
        _notesCtrl.clear();
        _paidCtrl.text = '0';
        _initialPaymentReferenceCtrl.clear();
        _dueDate = null;
        _draftItems = const [];
      });
    } finally {
      if (mounted) setState(() => _submittingTicket = false);
    }
  }

  Future<void> _pickCustomerForDraft() async {
    final picked = await showCustomerPickerSheet(context);
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.isWalkIn) {
        _selectedCustomer = null;
        _customerCtrl.clear();
        _phoneCtrl.clear();
        return;
      }

      final customer = picked.customer!;
      _selectedCustomer = customer;
      _customerCtrl.text = customer.name;
      _phoneCtrl.text = customer.phone ?? '';
    });
  }

  Future<void> _recordPayment(LaundryOrder order) async {
    final payment = await showDialog<_LaundryPaymentData>(
      context: context,
      builder: (_) => _PaymentDialog(order: order),
    );
    if (payment == null || !mounted) return;

    if (_networkInfo.isConnected) {
      try {
        await _remote.recordPayment(
          orderId: order.id,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          reference: payment.reference,
          notes: payment.notes,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment recorded.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
    } else {
      await _queueLaundryAction(
        actionType: LaundrySyncActionType.recordPayment,
        orderId: order.id,
        payload: {
          'payment': {
            'amount': payment.amount,
            'paymentMethod': payment.paymentMethod,
            if (payment.reference.trim().isNotEmpty)
              'reference': payment.reference.trim(),
            if (payment.notes.trim().isNotEmpty) 'notes': payment.notes.trim(),
          },
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline: payment queued. It will sync automatically.'),
        ),
      );
    }

    if (mounted) {
      await _load();
    }
  }

  Future<void> _showOrderDetails(LaundryOrder order) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _LaundryOrderDetailsDialog(order: order),
    );
  }

  Future<void> _moveStatus(LaundryOrder order, LaundryOrderStatus next) async {
    if (_networkInfo.isConnected) {
      try {
        await _remote.updateStatus(orderId: order.id, status: next);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${order.ticketNumber} moved to ${_statusLabel(next)}',
            ),
          ),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    await _queueLaundryAction(
      actionType: LaundrySyncActionType.updateStatus,
      orderId: order.id,
      payload: {
        'statusUpdate': {'status': _statusLabel(next)},
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offline: status update queued (${_statusLabel(next)}). It will sync automatically.',
        ),
      ),
    );
  }

  Future<void> _queueLaundryAction({
    required LaundrySyncActionType actionType,
    String? orderId,
    required Map<String, dynamic> payload,
  }) async {
    final localId = _uuid.v4();
    final clientOpId = _uuid.v4();
    await _laundryLocal.savePendingAction(
      PendingLaundrySyncAction(
        localId: localId,
        clientOpId: clientOpId,
        actionType: actionType,
        orderId: orderId,
        payload: payload,
        createdAt: DateTime.now(),
        status: SyncItemStatus.pending,
      ),
    );
    if (_networkInfo.isConnected) {
      if (!mounted) return;
      context.read<SyncBloc>().add(const SyncPushRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ordersOnly) {
      return ResponsiveShell(
        appBar: AppBar(
          title: const Text('Laundry Tickets'),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        child: _buildOrdersPane(context),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 1100;
    return ResponsiveShell(
      appBar: AppBar(
        title: const Text('POS • Laundry'),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: _createTicket,
              icon: const Icon(Icons.add),
              label: const Text('New Ticket'),
            ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _buildProductPickerPane(context)),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 430,
                  child: _createdTicketForPrint != null
                      ? _buildCreatedTicketPane(
                          context,
                          _createdTicketForPrint!,
                        )
                      : _buildTicketBuilderPane(
                          context,
                          includeProductPicker: false,
                        ),
                ),
              ],
            )
          : _buildTicketBuilderPane(context),
    );
  }

  Widget _buildOrdersPane(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search ticket / customer / phone',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _pageIndex = 0;
                        _load();
                      },
                    ),
                  ),
                  onSubmitted: (_) {
                    _pageIndex = 0;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<LaundryOrderStatus?>(
                value: _status,
                hint: const Text('Status'),
                items: <DropdownMenuItem<LaundryOrderStatus?>>[
                  const DropdownMenuItem<LaundryOrderStatus?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...LaundryOrderStatus.values.map(
                    (s) => DropdownMenuItem<LaundryOrderStatus?>(
                      value: s,
                      child: Text(_statusLabel(s)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _status = value);
                  _pageIndex = 0;
                  _load();
                },
              ),
            ],
          ),
        ),
        if (_loading) const Expanded(child: LoadingIndicator()),
        if (!_loading && _error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (!_loading && _error == null && _page.content.isEmpty)
          const Expanded(
            child: EmptyState(
              title: 'No laundry orders',
              subtitle: 'Create a new ticket to start laundry workflow.',
              icon: Icons.local_laundry_service_outlined,
            ),
          ),
        if (!_loading && _error == null && _page.content.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _page.content.length,
              itemBuilder: (_, i) {
                final order = _page.content[i];
                final due = order.dueDate != null
                    ? Formatters.date(order.dueDate!)
                    : '-';
                final next = _nextStatuses(order.status);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.ticketNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Customer: ${order.customerName ?? '-'} ${order.customerPhone ?? ''}',
                        ),
                        Text('Due: $due'),
                        const SizedBox(height: 6),
                        Text(
                          'Total: ${Formatters.currency(order.totalAmount)}  Paid: ${Formatters.currency(order.paidAmount)}  Balance: ${Formatters.currency(order.balanceAmount)}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...next.map(
                              (s) => OutlinedButton(
                                onPressed: () => _moveStatus(order, s),
                                child: Text(_statusLabel(s)),
                              ),
                            ),
                            if (order.balanceAmount > 0)
                              ElevatedButton.icon(
                                onPressed: () => _recordPayment(order),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Payment'),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => _showOrderDetails(order),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('Details'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Page ${_page.number + 1} / ${_page.totalPages == 0 ? 1 : _page.totalPages}  •  Total ${_page.totalElements}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                onPressed: _page.number > 0
                    ? () {
                        setState(() => _pageIndex -= 1);
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: (_page.number + 1) < _page.totalPages
                    ? () {
                        setState(() => _pageIndex += 1);
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductPickerPane(BuildContext context) {
    final theme = Theme.of(context);
    final filteredProducts = _products.where((p) {
      final q = _productSearchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.sku ?? '').toLowerCase().contains(q) ||
          (p.barcode ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                controller: _productSearchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Price tier:'),
                  const SizedBox(width: 8),
                  ..._supportedPriceTiers.map((tier) {
                    final selected = tier == _selectedPriceTier;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tier),
                        selected: selected,
                        onSelected: (_) => _applyPriceTier(tier),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (_, i) {
              final p = filteredProducts[i];
              final displayPrice = p.priceForTier(_selectedPriceTier);
              return Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _addDraftProduct(p),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedPriceTier.toLowerCase()} • ${Formatters.currency(displayPrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if ((p.sku ?? '').isNotEmpty)
                          Text(
                            p.sku!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketBuilderPane(
    BuildContext context, {
    bool includeProductPicker = true,
  }) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          if (includeProductPicker)
            Expanded(child: _buildProductPickerPane(context)),
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            avatar: Icon(
                              _selectedCustomer != null
                                  ? Icons.person
                                  : Icons.person_outline,
                              size: 18,
                            ),
                            label: Text(
                              _selectedCustomer?.name ??
                                  'Walk-in (no customer)',
                            ),
                            onPressed: _pickCustomerForDraft,
                            onDeleted: _selectedCustomer != null
                                ? () => setState(() {
                                    _selectedCustomer = null;
                                    _customerCtrl.clear();
                                    _phoneCtrl.clear();
                                  })
                                : null,
                            deleteIcon: _selectedCustomer != null
                                ? const Icon(Icons.close, size: 16)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _customerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer phone',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dueDate == null
                                    ? 'No due date'
                                    : 'Due: ${Formatters.date(_dueDate!)}',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 1),
                                  lastDate: DateTime(now.year + 5),
                                  initialDate: _dueDate ?? now,
                                );
                                if (picked != null) {
                                  setState(() => _dueDate = picked);
                                }
                              },
                              child: const Text('Pick date'),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _paidCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Initial paid amount',
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _initialPaymentReferenceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Initial payment reference',
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<LaundryPaymentMethod>(
                          initialValue: _initialPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Initial payment method',
                          ),
                          items: _supportedLaundryPaymentMethods
                              .map(
                                (method) =>
                                    DropdownMenuItem<LaundryPaymentMethod>(
                                      value: method,
                                      child: Text(_paymentMethodLabel(method)),
                                    ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _initialPaymentMethod = value);
                          },
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Text(
                        'Ticket Items',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_draftItems.length} item(s)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _draftItems.isEmpty
                      ? Center(
                          child: Text(
                            'No items yet. Tap a product card to add.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: _ticketItemsScrollCtrl,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          itemCount: _draftItems.length,
                          itemBuilder: (_, i) {
                            final item = _draftItems[i];
                            final name =
                                _productNameById(item.productId) ??
                                'Unknown product';
                            final qty = double.tryParse(item.quantity) ?? 0;
                            final unitPrice =
                                double.tryParse(item.unitPrice) ?? 0;
                            final lineTotal = qty * unitPrice;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${Formatters.currency(unitPrice)} each',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          Text(
                                            'Line: ${Formatters.currency(lineTotal)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Decrease',
                                      onPressed: () =>
                                          _changeDraftQuantity(i, -1),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        qty % 1 == 0
                                            ? qty.toStringAsFixed(0)
                                            : qty.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Increase',
                                      onPressed: () =>
                                          _changeDraftQuantity(i, 1),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () => _removeDraftItem(i),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total: ${Formatters.currency(_draftTotal)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submittingTicket ? null : _submitDraftTicket,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        _submittingTicket ? 'Saving...' : 'Create Ticket',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedTicketPane(BuildContext context, LaundryOrder order) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 52,
                      ),
                      const SizedBox(height: 8),
                      Text('Ticket Created', style: theme.textTheme.titleLarge),
                      Text(
                        order.ticketNumber,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (order.createdAt != null)
                        Text(
                          Formatters.dateTime(order.createdAt!),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.itemName} × ${Formatters.quantity(item.quantity)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(Formatters.currency(item.lineTotal)),
                              ],
                            ),
                          ),
                        const Divider(),
                        _amountRow(context, 'Total', order.totalAmount, true),
                        _amountRow(context, 'Paid', order.paidAmount, false),
                        _amountRow(
                          context,
                          'Balance',
                          order.balanceAmount,
                          false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _receiptBusy
                            ? null
                            : () => _onPrintCreatedTicket(order),
                        icon: _receiptBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: const Text('Print'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _receiptBusy
                            ? null
                            : () => _onShareCreatedTicket(order),
                        icon: _receiptBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      setState(() => _createdTicketForPrint = null),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Ticket'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    double amount,
    bool emphasize,
  ) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}

List<LaundryOrderStatus> _nextStatuses(LaundryOrderStatus status) {
  switch (status) {
    case LaundryOrderStatus.received:
      return const [LaundryOrderStatus.washing, LaundryOrderStatus.canceled];
    case LaundryOrderStatus.washing:
      return const [LaundryOrderStatus.ironing, LaundryOrderStatus.canceled];
    case LaundryOrderStatus.ironing:
      return const [LaundryOrderStatus.ready, LaundryOrderStatus.canceled];
    case LaundryOrderStatus.ready:
      return const [LaundryOrderStatus.collected];
    case LaundryOrderStatus.collected:
      return const [];
    case LaundryOrderStatus.canceled:
      return const [];
  }
}

String _statusLabel(LaundryOrderStatus status) {
  switch (status) {
    case LaundryOrderStatus.received:
      return 'RECEIVED';
    case LaundryOrderStatus.washing:
      return 'WASHING';
    case LaundryOrderStatus.ironing:
      return 'IRONING';
    case LaundryOrderStatus.ready:
      return 'READY';
    case LaundryOrderStatus.collected:
      return 'COLLECTED';
    case LaundryOrderStatus.canceled:
      return 'CANCELED';
  }
}

String _paymentMethodLabel(LaundryPaymentMethod method) {
  switch (method) {
    case LaundryPaymentMethod.cash:
      return 'CASH';
    case LaundryPaymentMethod.card:
      return 'CARD';
    case LaundryPaymentMethod.mobileMoney:
      return 'MOBILE MONEY';
    case LaundryPaymentMethod.bankTransfer:
      return 'BANK TRANSFER';
  }
}

class _StatusChip extends StatelessWidget {
  final LaundryOrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    if (status == LaundryOrderStatus.received) {
      bg = colors.primaryContainer;
      fg = colors.onPrimaryContainer;
    } else if (status == LaundryOrderStatus.washing) {
      bg = colors.tertiaryContainer;
      fg = colors.onTertiaryContainer;
    } else if (status == LaundryOrderStatus.ironing) {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    } else if (status == LaundryOrderStatus.ready) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (status == LaundryOrderStatus.collected) {
      bg = Colors.blueGrey.shade100;
      fg = Colors.blueGrey.shade900;
    } else {
      bg = colors.errorContainer;
      fg = colors.onErrorContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _CreateLaundryTicketDialog extends StatefulWidget {
  final List<Product> products;
  final String initialPriceTier;
  final LaundryPaymentMethod initialPaymentMethod;

  const _CreateLaundryTicketDialog({
    required this.products,
    required this.initialPriceTier,
    required this.initialPaymentMethod,
  });

  @override
  State<_CreateLaundryTicketDialog> createState() =>
      _CreateLaundryTicketDialogState();
}

class _CreateLaundryTicketDialogState
    extends State<_CreateLaundryTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  final _paymentReferenceCtrl = TextEditingController();
  DateTime? _dueDate;
  Customer? _selectedCustomer;
  bool _saving = false;
  late String _selectedPriceTier;
  late LaundryPaymentMethod _paymentMethod;

  List<_DraftLaundryItem> _items = [const _DraftLaundryItem()];

  @override
  void initState() {
    super.initState();
    _selectedPriceTier = _supportedPriceTiers.contains(widget.initialPriceTier)
        ? widget.initialPriceTier
        : _priceTierNormal;
    _paymentMethod = widget.initialPaymentMethod;
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    _paymentReferenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) return;

    setState(() => _saving = true);
    final items = _items
        .map(
          (e) => {
            'productId': e.productId,
            'quantity': double.parse(e.quantity),
            'unitPrice': double.parse(e.unitPrice),
            if (e.notes.trim().isNotEmpty) 'notes': e.notes.trim(),
          },
        )
        .toList();

    if (!mounted) return;
    Navigator.of(context).pop(
      _CreateLaundryTicketData(
        customerId: _selectedCustomer?.id,
        customerName: _customerCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        dueDateIso: _dueDate != null
            ? '${_dueDate!.year.toString().padLeft(4, '0')}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
            : null,
        notes: _notesCtrl.text.trim(),
        paidAmount: double.tryParse(_paidCtrl.text.trim()) ?? 0,
        paymentMethod: laundryPaymentMethodToApi(_paymentMethod),
        paymentReference: _paymentReferenceCtrl.text.trim(),
        items: items,
      ),
    );
  }

  Product? _productById(String productId) {
    for (final p in widget.products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  void _applyPriceTier(String tier) {
    if (!_supportedPriceTiers.contains(tier)) return;
    setState(() {
      _selectedPriceTier = tier;
      _items = _items.map((item) {
        if (item.productId.isEmpty) return item;
        final product = _productById(item.productId);
        if (product == null) return item;
        return item.copyWith(
          unitPrice: product
              .priceForTier(_selectedPriceTier)
              .toStringAsFixed(2),
        );
      }).toList();
    });
  }

  Future<void> _pickCustomer() async {
    final picked = await showCustomerPickerSheet(context);
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.isWalkIn) {
        _selectedCustomer = null;
        _customerCtrl.clear();
        _phoneCtrl.clear();
        return;
      }

      final customer = picked.customer!;
      _selectedCustomer = customer;
      _customerCtrl.text = customer.name;
      _phoneCtrl.text = customer.phone ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Laundry Ticket'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: Icon(
                      _selectedCustomer != null
                          ? Icons.person
                          : Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(
                      _selectedCustomer?.name ?? 'Walk-in (no customer)',
                    ),
                    onPressed: _pickCustomer,
                    onDeleted: _selectedCustomer != null
                        ? () => setState(() {
                            _selectedCustomer = null;
                            _customerCtrl.clear();
                            _phoneCtrl.clear();
                          })
                        : null,
                    deleteIcon: _selectedCustomer != null
                        ? const Icon(Icons.close, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerCtrl,
                  decoration: const InputDecoration(labelText: 'Customer name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer phone',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'No due date'
                            : 'Due: ${Formatters.date(_dueDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 5),
                          initialDate: _dueDate ?? now,
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      child: const Text('Pick date'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial paid amount',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final amount = double.tryParse((v ?? '').trim());
                    if (amount == null || amount < 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LaundryPaymentMethod>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Initial payment method',
                  ),
                  items: _supportedLaundryPaymentMethods
                      .map(
                        (method) => DropdownMenuItem<LaundryPaymentMethod>(
                          value: method,
                          child: Text(_paymentMethodLabel(method)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _paymentMethod = value);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paymentReferenceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial payment reference',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Price tier:'),
                    const SizedBox(width: 8),
                    ..._supportedPriceTiers.map((tier) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tier),
                          selected: _selectedPriceTier == tier,
                          onSelected: (_) => _applyPriceTier(tier),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) => _itemEditor(index)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _items = [..._items, const _DraftLaundryItem()],
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Create'),
        ),
      ],
    );
  }

  Widget _itemEditor(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: item.productId.isEmpty ? null : item.productId,
            decoration: const InputDecoration(labelText: 'Product'),
            items: widget.products
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(p.name),
                  ),
                )
                .toList(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (value) {
              if (value == null) return;
              final selected = widget.products.firstWhere((p) => p.id == value);
              _items[index] = _items[index].copyWith(
                productId: value,
                unitPrice: selected
                    .priceForTier(_selectedPriceTier)
                    .toStringAsFixed(2),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final qty = double.tryParse((v ?? '').trim());
                    if (qty == null || qty <= 0) return 'Invalid';
                    return null;
                  },
                  onChanged: (v) =>
                      _items[index] = _items[index].copyWith(quantity: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice,
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final price = double.tryParse((v ?? '').trim());
                    if (price == null || price < 0) return 'Invalid';
                    return null;
                  },
                  onChanged: (v) =>
                      _items[index] = _items[index].copyWith(unitPrice: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.notes,
                  decoration: const InputDecoration(labelText: 'Item notes'),
                  onChanged: (v) =>
                      _items[index] = _items[index].copyWith(notes: v),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_items.length == 1) return;
                  setState(() {
                    _items = List.of(_items)..removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftLaundryItem {
  final String productId;
  final String quantity;
  final String unitPrice;
  final String notes;

  const _DraftLaundryItem({
    this.productId = '',
    this.quantity = '1',
    this.unitPrice = '0',
    this.notes = '',
  });

  _DraftLaundryItem copyWith({
    String? productId,
    String? quantity,
    String? unitPrice,
    String? notes,
  }) {
    return _DraftLaundryItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final LaundryOrder order;

  const _PaymentDialog({required this.order});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _LaundryOrderDetailsDialog extends StatelessWidget {
  final LaundryOrder order;

  const _LaundryOrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Ticket Details • ${order.ticketNumber}'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${order.customerName ?? '-'}'),
              Text('Phone: ${order.customerPhone ?? '-'}'),
              Text('Status: ${_statusLabel(order.status)}'),
              const SizedBox(height: 12),
              Text(
                'Items',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.itemName)),
                      Text(
                        '${Formatters.quantity(item.quantity)} x ${Formatters.currency(item.unitPrice)}',
                      ),
                      const SizedBox(width: 8),
                      Text(Formatters.currency(item.lineTotal)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Payment History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (order.payments.isEmpty)
                const Text('No payments recorded yet.')
              else
                ...order.payments.map((payment) {
                  final when = payment.paymentDate ?? payment.createdAt;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_paymentMethodLabel(payment.paymentMethod)} • ${Formatters.currency(payment.amount)}',
                    ),
                    subtitle: Text(
                      '${when != null ? Formatters.dateTime(when) : '-'}  ${payment.reference?.trim().isNotEmpty == true ? ' • Ref: ${payment.reference!.trim()}' : ''}',
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amountCtrl;
  final TextEditingController _referenceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _saving = false;
  LaundryPaymentMethod _paymentMethod = LaundryPaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.order.balanceAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    setState(() => _saving = true);
    if (!mounted) return;
    Navigator.of(context).pop(
      _LaundryPaymentData(
        amount: amount,
        paymentMethod: laundryPaymentMethodToApi(_paymentMethod),
        reference: _referenceCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payment • ${widget.order.ticketNumber}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance: ${Formatters.currency(widget.order.balanceAmount)}'),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<LaundryPaymentMethod>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: _supportedLaundryPaymentMethods
                  .map(
                    (method) => DropdownMenuItem<LaundryPaymentMethod>(
                      value: method,
                      child: Text(_paymentMethodLabel(method)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _referenceCtrl,
              decoration: const InputDecoration(labelText: 'Payment reference'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Record'),
        ),
      ],
    );
  }
}

class _CreateLaundryTicketData {
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String? dueDateIso;
  final String notes;
  final double paidAmount;
  final String paymentMethod;
  final String paymentReference;
  final List<Map<String, dynamic>> items;

  const _CreateLaundryTicketData({
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.dueDateIso,
    required this.notes,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentReference,
    required this.items,
  });
}

class _LaundryPaymentData {
  final double amount;
  final String paymentMethod;
  final String reference;
  final String notes;

  const _LaundryPaymentData({
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.notes,
  });
}
