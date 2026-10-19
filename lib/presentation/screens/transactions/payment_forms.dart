import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';
import '../../../di/injection.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/money_text.dart';
import '../parties/party_picker_sheet.dart';

/// Payment methods accepted for Payment In (backend free text, max 30).
const paymentMethods = {
  'CASH': 'Cash',
  'MOBILE_MONEY': 'Mobile money',
  'CARD': 'Card',
  'BANK_TRANSFER': 'Bank transfer',
};

double? parseAmount(String text) =>
    double.tryParse(text.replaceAll(RegExp(r'[,\s ]'), ''));

/// Largest amount a party-to-party transfer may move (null = not allowed).
///
/// Mirrors the server rules: customer→customer and supplier→supplier move up
/// to the source's open balance; customer→supplier (contra) is capped by both
/// what the customer owes us and what we owe the supplier; supplier→customer,
/// the same party, or a settled source are refused.
double? transferLimit(PartySummary from, PartySummary to) {
  if (from.type == to.type && from.id == to.id) return null;
  final owes = from.type == PartyType.customer
      ? (from.direction == BalanceDirection.receivable ? from.balance : 0.0)
      : (from.direction == BalanceDirection.payable ? from.balance : 0.0);
  if (owes <= 0) return null;
  switch ((from.type, to.type)) {
    case (PartyType.customer, PartyType.customer):
    case (PartyType.supplier, PartyType.supplier):
      return owes;
    case (PartyType.customer, PartyType.supplier):
      final weOwe = to.direction == BalanceDirection.payable ? to.balance : 0.0;
      return weOwe <= 0 ? null : (owes < weOwe ? owes : weOwe);
    case (PartyType.supplier, PartyType.customer):
      return null;
  }
}

class _FormShell extends StatelessWidget {
  const _FormShell({required this.title, required this.children, required this.onSave, required this.saving});
  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: title,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: children),
          ),
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/transactions'),
                  child: Text(context.tr('common.cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('form-save'),
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(context.tr('common.save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fieldLabel(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );

class _PartyField extends StatelessWidget {
  const _PartyField({required this.party, required this.hint, required this.onTap, this.fieldKey});
  final PartySummary? party;
  final String hint;
  final VoidCallback onTap;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final p = party;
    return SoftCard(
      key: fieldKey,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          p == null
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: const Icon(Icons.person_search_outlined),
                )
              : InitialsAvatar(p.name),
          const SizedBox(width: 12),
          Expanded(
            child: p == null
                ? Text(hint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                      Wrap(children: [
                        Text(
                          '${p.direction == BalanceDirection.payable ? context.tr('party.to_pay') : context.tr('party.to_receive')}: ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        MoneyText(p.balance, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ],
                  ),
          ),
          const Icon(Icons.unfold_more_rounded),
        ],
      ),
    );
  }
}

Future<DateTime?> _pickDate(BuildContext context, DateTime current) => showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime.now(),
    );

Widget _dateField(BuildContext context, DateTime date, ValueChanged<DateTime> onPicked) => SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () async {
        final d = await _pickDate(context, date);
        if (d != null) onPicked(d);
      },
      child: Row(children: [
        Expanded(child: Text(Formatters.date(date))),
        const Icon(Icons.calendar_month_outlined, size: 20),
      ]),
    );

TextFormField _amountField(TextEditingController c, {String? Function(String?)? validator}) => TextFormField(
      key: const ValueKey('amount-field'),
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(prefixText: '${Formatters.currencySymbol} '),
      validator: validator,
    );

// ---------------------------------------------------------------------------
// Payment In
// ---------------------------------------------------------------------------

/// Receive money from a customer against one of their open receivables.
class PaymentInScreen extends StatefulWidget {
  const PaymentInScreen({super.key, this.remote});
  final FeedRemoteDataSource? remote;

  @override
  State<PaymentInScreen> createState() => _PaymentInScreenState();
}

class _PaymentInScreenState extends State<PaymentInScreen> {
  late final FeedRemoteDataSource _remote = widget.remote ?? sl<FeedRemoteDataSource>();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  PartySummary? _customer;
  List<ReceivableItem>? _receivables;
  ReceivableItem? _receivable;
  String _method = 'CASH';
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _loadingReceivables = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final p = await showPartyPicker(
      context,
      remote: _remote,
      type: PartyType.customer,
      where: (p) => p.direction == BalanceDirection.receivable,
    );
    if (p == null || !mounted) return;
    setState(() {
      _customer = p;
      _receivables = null;
      _receivable = null;
      _loadingReceivables = true;
      _error = null;
    });
    try {
      final list = await _remote.getOpenReceivables(p.id);
      if (!mounted) return;
      setState(() {
        _receivables = list;
        _receivable = list.isEmpty ? null : list.first;
        if (_receivable != null) _amount.text = Formatters.money(_receivable!.balance).replaceAll(',', '');
      });
    } on ServerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('common.load_failed'));
    } finally {
      if (mounted) setState(() => _loadingReceivables = false);
    }
  }

  Future<void> _save() async {
    if (_receivable == null) {
      setState(() => _error = context.tr('party.select'));
      return;
    }
    if (_form.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _remote.recordPaymentIn(
        receivableId: _receivable!.id,
        amount: parseAmount(_amount.text)!,
        date: _date,
        method: _method,
        reference: _reference.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('common.done'))));
      context.canPop() ? context.pop(true) : context.go('/transactions');
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.tr('common.load_failed'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _FormShell(
      title: context.tr('tx.payment_in'),
      saving: _saving,
      onSave: _save,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(context, context.tr('party.customer')),
              _PartyField(
                fieldKey: const ValueKey('pick-customer'),
                party: _customer,
                hint: context.tr('party.select'),
                onTap: _pickCustomer,
              ),
              if (_loadingReceivables)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              if (_receivables != null && _receivables!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(context.tr('common.nothing_here'), style: theme.textTheme.bodySmall),
                ),
              if (_receivables != null && _receivables!.length > 1) ...[
                _fieldLabel(context, 'Invoice'),
                DropdownButtonFormField<ReceivableItem>(
                  initialValue: _receivable,
                  isExpanded: true,
                  items: [
                    for (final r in _receivables!)
                      DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.dueDate == null ? '' : '${Formatters.date(r.dueDate!)}  ·  '}'
                          '${Formatters.currency(r.balance)}',
                        ),
                      ),
                  ],
                  onChanged: (r) => setState(() {
                    _receivable = r;
                    if (r != null) _amount.text = Formatters.money(r.balance).replaceAll(',', '');
                  }),
                ),
              ],
              _fieldLabel(context, context.tr('common.amount')),
              _amountField(_amount, validator: (v) {
                final a = parseAmount(v ?? '');
                if (a == null || a <= 0) return context.tr('common.amount');
                final max = _receivable?.balance;
                if (max != null && a > max + 0.001) return '≤ ${Formatters.currency(max)}';
                return null;
              }),
              _fieldLabel(context, context.tr('sale.payment_mode')),
              DropdownButtonFormField<String>(
                initialValue: _method,
                items: [
                  for (final e in paymentMethods.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'CASH'),
              ),
              _fieldLabel(context, context.tr('common.date')),
              _dateField(context, _date, (d) => setState(() => _date = d)),
              _fieldLabel(context, context.tr('common.notes')),
              TextFormField(controller: _reference, maxLength: 255),
              if (_error != null)
                Text(_error!, key: const ValueKey('form-error'), style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Party to Party transfer
// ---------------------------------------------------------------------------

/// Move an outstanding balance from one party to another.
class PartyTransferScreen extends StatefulWidget {
  const PartyTransferScreen({super.key, this.remote});
  final FeedRemoteDataSource? remote;

  @override
  State<PartyTransferScreen> createState() => _PartyTransferScreenState();
}

class _PartyTransferScreenState extends State<PartyTransferScreen> {
  late final FeedRemoteDataSource _remote = widget.remote ?? sl<FeedRemoteDataSource>();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  PartySummary? _from;
  PartySummary? _to;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _limit => _from == null || _to == null ? null : transferLimit(_from!, _to!);

  Future<void> _pickFrom() async {
    final p = await showPartyPicker(
      context,
      remote: _remote,
      // Only parties with something to move.
      where: (p) =>
          (p.type == PartyType.customer && p.direction == BalanceDirection.receivable) ||
          (p.type == PartyType.supplier && p.direction == BalanceDirection.payable),
    );
    if (p == null || !mounted) return;
    setState(() {
      _from = p;
      if (_to != null && transferLimit(p, _to!) == null) _to = null;
      _error = null;
    });
  }

  Future<void> _pickTo() async {
    final from = _from;
    if (from == null) return _pickFrom();
    final p = await showPartyPicker(
      context,
      remote: _remote,
      // Suppliers can only pass to suppliers.
      type: from.type == PartyType.supplier ? PartyType.supplier : null,
      where: (p) => transferLimit(from, p) != null,
    );
    if (p == null || !mounted) return;
    setState(() {
      _to = p;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_from == null || _to == null) {
      setState(() => _error = context.tr('party.select'));
      return;
    }
    if (_form.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _remote.createTransfer(
        from: _from!,
        to: _to!,
        amount: parseAmount(_amount.text)!,
        date: _date,
        notes: _notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('common.done'))));
      context.canPop() ? context.pop(true) : context.go('/transactions');
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.tr('common.load_failed'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = _limit;
    return _FormShell(
      title: context.tr('tx.party_transfer'),
      saving: _saving,
      onSave: _save,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(context, context.tr('common.from')),
              _PartyField(
                fieldKey: const ValueKey('pick-from'),
                party: _from,
                hint: context.tr('party.select'),
                onTap: _pickFrom,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.south_rounded),
              ),
              _fieldLabel(context, context.tr('common.to')),
              _PartyField(
                fieldKey: const ValueKey('pick-to'),
                party: _to,
                hint: context.tr('party.select'),
                onTap: _pickTo,
              ),
              _fieldLabel(context, context.tr('common.amount')),
              _amountField(_amount, validator: (v) {
                final a = parseAmount(v ?? '');
                if (a == null || a <= 0) return context.tr('common.amount');
                if (limit != null && a > limit + 0.001) return '≤ ${Formatters.currency(limit)}';
                return null;
              }),
              if (limit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Text(
                    'Up to ${Formatters.currency(limit)}'
                    '${_from?.type == PartyType.customer && _to?.type == PartyType.supplier ? ' (the smaller of what the customer owes and what you owe the supplier)' : ''}',
                    key: const ValueKey('transfer-limit'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              _fieldLabel(context, context.tr('common.date')),
              _dateField(context, _date, (d) => setState(() => _date = d)),
              _fieldLabel(context, context.tr('common.notes')),
              TextFormField(controller: _notes, maxLines: 3, minLines: 2),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, key: const ValueKey('form-error'), style: TextStyle(color: theme.colorScheme.error)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
