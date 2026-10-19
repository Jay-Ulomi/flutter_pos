import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';
import '../../../di/injection.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/feeds/feed_cubits.dart';
import '../../widgets/aduinola/date_range_card.dart';
import '../../widgets/aduinola/transaction_hub.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/money_text.dart';
import '../../widgets/aduinola/app_page.dart';
import '../../widgets/responsive_shell.dart';

/// Label key for a transaction type.
String txLabelKey(String type) => switch (TxType.fromCode(type)) {
      TxType.sale => 'tx.sale',
      TxType.paymentIn => 'tx.payment_in',
      TxType.saleReturn => 'tx.sale_return',
      TxType.quotation => 'tx.quotation',
      TxType.purchase => 'tx.purchase',
      TxType.paymentOut => 'tx.payment_out',
      TxType.purchaseReturn => 'tx.debit_note',
      TxType.expense => 'tx.expense',
      TxType.partyTransfer => 'tx.party_transfer',
      null => type,
    };

/// Unified feed of sales, payments, returns, purchases, expenses and transfers.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, this.cubit});

  /// Injected in tests.
  final TransactionsCubit? cubit;

  /// Types this user may list: everything with `view_reports`, otherwise the
  /// cashier subset (the server returns only those to them).
  static Set<TxType> allowedTypes(BuildContext context) {
    final canReports = context.read<AuthBloc>().state.can('view_reports');
    return canReports ? TxType.values.toSet() : TxType.cashierTypes;
  }

  @override
  Widget build(BuildContext context) {
    final allowed = allowedTypes(context);
    final restricted = allowed.length < TxType.values.length;
    final c = cubit;
    if (c != null) {
      if (restricted) c.setFilter(c.filter.copyWith(types: allowed));
      return BlocProvider.value(value: c..refresh(), child: _TransactionsView(allowed: allowed));
    }
    return BlocProvider(
      create: (_) => TransactionsCubit(
        sl<FeedRemoteDataSource>(),
        filter: TransactionsFilter(types: restricted ? allowed : const {}),
      )..refresh(),
      child: _TransactionsView(allowed: allowed),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView({required this.allowed});
  final Set<TxType> allowed;

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  final _search = TextEditingController();
  Timer? _debounce;
  TxStatusFilter _status = TxStatusFilter.all;
  DateRangeValue _range = const DateRangeValue();
  TxType? _type;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  TransactionsCubit get _cubit => context.read<TransactionsCubit>();

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _cubit.setFilter(_cubit.filter.copyWith(search: v));
    });
  }

  void _setRange(DateRangeValue r) {
    setState(() => _range = r);
    _cubit.setFilter(r.isAllTime
        ? _cubit.filter.copyWith(clearDates: true)
        : _cubit.filter.copyWith(from: r.from, to: r.to));
  }

  void _setType(TxType? t) {
    setState(() => _type = t);
    final restricted = widget.allowed.length < TxType.values.length;
    _cubit.setFilter(_cubit.filter.copyWith(
      types: t != null ? {t} : (restricted ? widget.allowed : {}),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final statusLabels = {
      TxStatusFilter.all: context.tr('common.all'),
      TxStatusFilter.paid: context.tr('tx.paid'),
      TxStatusFilter.unpaid: context.tr('tx.unpaid'),
      TxStatusFilter.partial: context.tr('tx.partial'),
    };
    return AppPage(
      title: context.tr('tx.title'),
      padBody: false,
      actions: [
          PopupMenuButton<TxType?>(
            tooltip: 'Filter by type',
            icon: Icon(_type == null ? Icons.tune_rounded : Icons.filter_alt_rounded),
            onSelected: _setType,
            itemBuilder: (ctx) => [
              PopupMenuItem(value: null, child: Text(ctx.tr('common.all'))),
              for (final t in TxType.values.where(widget.allowed.contains))
                PopupMenuItem(value: t, child: Text(ctx.tr(txLabelKey(t.code)))),
            ],
          ),
      ],
      actionBar: TwoActionBar(
        leftLabel: context.tr('tx.payment_in'),
        leftIcon: Icons.move_to_inbox_outlined,
        onLeft: () => context.push('/payment-in'),
        rightLabel: context.tr('tx.new_sale'),
        rightIcon: Icons.sell_outlined,
        onRight: () => context.go('/pos'),
        onPlus: () => showTransactionHub(context),
      ),
      body: BlocBuilder<TransactionsCubit, FeedState<TransactionItem>>(
        builder: (context, state) {
          final items = state.items.where(_status.accepts).toList();
          return RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) _cubit.loadMore();
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: AppPage.insets(context, top: 4, bottom: 8),
                    sliver: SliverList.list(children: [
                      SearchPill(
                        controller: _search,
                        hint: context.tr('common.search'),
                        onChanged: _onSearch,
                      ),
                      const SizedBox(height: 12),
                      DateRangeCard(value: _range, onChanged: _setRange),
                      const SizedBox(height: 12),
                    ]),
                  ),
                  SliverToBoxAdapter(
                    child: PillChips<TxStatusFilter>(
                      padding: EdgeInsets.symmetric(horizontal: AppPage.gutterOf(context)),
                      items: TxStatusFilter.values,
                      selected: _status,
                      labelOf: (s) => statusLabels[s]!,
                      onSelected: (s) => setState(() => _status = s),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (state.loading && state.items.isEmpty)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else if (state.error != null && state.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.cloud_off_rounded,
                        message: state.error!,
                        onRetry: _cubit.refresh,
                      ),
                    )
                  else if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.receipt_long_outlined,
                        message: context.tr('common.nothing_here'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: AppPage.insets(context, top: 0, bottom: 16),
                      sliver: SliverList.separated(
                        itemCount: items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return TransactionTile(item: items[i]);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One row of the feed: "Sale #12 / party / date · time" … amount + status.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});
  final TransactionItem item;

  void _open(BuildContext context) {
    switch (item.kind) {
      case TxType.sale:
        context.push('/sales/detail', extra: item.id);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = context.tr(txLabelKey(item.type));
    final title = item.partyName?.isNotEmpty == true ? item.partyName! : label;
    final number = item.number == null ? label : '$label #${item.number}';
    final outflow = item.kind?.isOutflow ?? false;
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number, style: theme.textTheme.labelSmall?.copyWith(color: cs.primary)),
                  const SizedBox(height: 2),
                  Text(title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (item.date != null)
                    Text(
                      '${Formatters.date(item.date!)}  ·  ${Formatters.time(item.date!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  item.amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: outflow ? cs.secondary : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.status != null)
                  StatusPill(_statusLabel(context, item.status!), tone: StatusPill.toneFor(item.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return context.tr('tx.paid');
      case 'UNPAID':
        return context.tr('tx.unpaid');
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
        return context.tr('tx.partial');
      case 'SETTLED':
        return context.tr('party.settled');
      default:
        final s = status.replaceAll('_', ' ').toLowerCase();
        return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    }
  }
}
