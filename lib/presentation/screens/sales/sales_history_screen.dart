import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/sale_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/sale/sale_bloc.dart';
import '../../blocs/sale/sale_event.dart';
import '../../blocs/sale/sale_state.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_state.dart';
import '../laundry/laundry_orders_screen.dart';
import '../../widgets/aduinola/app_page.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final business = context.read<BusinessBloc>().state.selected;
    final businessType = business?.type ?? auth.selectedBusinessType ?? '';
    if (businessType.trim().toUpperCase() != 'LAUNDRY') {
      context.read<SaleBloc>().add(const SaleRecentLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final business = context.watch<BusinessBloc>().state.selected;
    final businessType = business?.type ?? auth.selectedBusinessType ?? '';
    if (businessType.trim().toUpperCase() == 'LAUNDRY') {
      return const LaundryOrdersScreen(ordersOnly: true);
    }

    return AppPage(
      title: 'Sales History',
      padBody: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () =>
              context.read<SaleBloc>().add(const SaleRecentLoadRequested()),
        ),
      ],
      body: BlocListener<SyncBloc, SyncBlocState>(
        // When the background sync flushes the queue, the pending count changes
        // but SaleBloc still holds the stale list — reload so cleared sales
        // stop showing as "Pending".
        listenWhen: (prev, curr) =>
            prev.status.pendingSalesCount != curr.status.pendingSalesCount,
        listener: (context, _) =>
            context.read<SaleBloc>().add(const SaleRecentLoadRequested()),
        child: BlocBuilder<SaleBloc, SaleState>(
          builder: (context, state) {
            if (state.status == SaleStatus.loadingRecent) {
              return const LoadingIndicator();
            }
            if (state.status == SaleStatus.error) {
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load sales',
                onRetry: () => context.read<SaleBloc>().add(
                  const SaleRecentLoadRequested(),
                ),
              );
            }
            if (state.recent.isEmpty && state.pending.isEmpty) {
              return const EmptyState(
                title: 'No sales yet',
                subtitle: 'Completed sales will appear here.',
                icon: Icons.receipt_long_outlined,
              );
            }

            // Combine pending + recent
            final pendingCount = state.pending.length;
            final recentCount = state.recent.length;
            final hasPending = pendingCount > 0;
            final hasRecent = recentCount > 0;

            final headerCount = (hasPending ? 1 : 0) + (hasRecent ? 1 : 0);
            final totalCount = pendingCount + recentCount + headerCount;

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<SaleBloc>().add(const SaleRecentLoadRequested()),
              child: ListView.builder(
                padding: AppPage.insets(context),
                itemCount: totalCount,
                itemBuilder: (context, i) {
                  // Pending header
                  if (hasPending && i == 0) {
                    return _sectionHeader(context, 'Pending ($pendingCount)');
                  }

                  final pendingStart = hasPending ? 1 : 0;
                  final pendingEnd = pendingStart + pendingCount;

                  if (i >= pendingStart && i < pendingEnd) {
                    final pending = state.pending[i - pendingStart];
                    final isLast = i == pendingEnd - 1 && !hasRecent;
                    return _SaleTile(
                      sale: pending.sale,
                      isPending: true,
                      status: pending.status.name,
                      showDivider: !isLast,
                    );
                  }

                  final completedHeaderIndex = pendingEnd;
                  if (hasRecent && i == completedHeaderIndex) {
                    return _sectionHeader(context, 'Completed ($recentCount)');
                  }

                  final recentStart =
                      completedHeaderIndex + (hasRecent ? 1 : 0);
                  final recentIndex = i - recentStart;
                  final isLast = i == totalCount - 1;
                  return _SaleTile(sale: state.recent[recentIndex], showDivider: !isLast);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// One row: same shape as [TransactionTile] in the Transactions feed \u2014 a
/// small coloured label line, the sale's title, then a summary/date line
/// on the left; amount and a status pill on the right.
class _SaleTile extends StatelessWidget {
  final Sale sale;
  final bool isPending;
  final String? status;
  final bool showDivider;

  const _SaleTile({
    required this.sale,
    this.isPending = false,
    this.status,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final saleLabel = sale.saleNumber ?? sale.clientId ?? '---';
    final itemCount = sale.items.length;
    final itemSummary = itemCount == 1
        ? sale.items.first.productName
        : '$itemCount items';
    final subtitle = [
      itemSummary,
      if (sale.createdAt != null) Formatters.dateTime(sale.createdAt!),
    ].join(' \u00B7 ');

    return Column(
      children: [
        InkWell(
          onTap: isPending
              ? null
              : () {
                  final id = sale.id ?? sale.saleNumber;
                  if (id != null) context.push('/sales/detail?saleId=$id');
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sale #$saleLabel', style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
                      const SizedBox(height: 2),
                      Text(
                        sale.customerName ?? 'Cash Sale',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(sale.totalAmount, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    if (isPending)
                      StatusPill(status ?? 'Pending', tone: PillTone.partial)
                    else if (sale.payments.isNotEmpty)
                      Text(
                        sale.payments.map((p) => p.method).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
