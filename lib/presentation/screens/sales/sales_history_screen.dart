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
import '../laundry/laundry_orders_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_shell.dart';

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

    return ResponsiveShell(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<SaleBloc>().add(const SaleRecentLoadRequested()),
          ),
        ],
      ),
      child: BlocBuilder<SaleBloc, SaleState>(
        builder: (context, state) {
          if (state.status == SaleStatus.loadingRecent) {
            return const LoadingIndicator();
          }
          if (state.status == SaleStatus.error) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load sales',
              onRetry: () =>
                  context.read<SaleBloc>().add(const SaleRecentLoadRequested()),
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
            onRefresh: () async => context.read<SaleBloc>().add(
              const SaleRecentLoadRequested(),
            ),
            child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
                return _SaleCard(
                  sale: pending.sale,
                  isPending: true,
                  status: pending.status.name,
                );
              }

              final completedHeaderIndex = pendingEnd;
              if (hasRecent && i == completedHeaderIndex) {
                return _sectionHeader(context, 'Completed ($recentCount)');
              }

              final recentStart = completedHeaderIndex + (hasRecent ? 1 : 0);
              final recentIndex = i - recentStart;
              return _SaleCard(sale: state.recent[recentIndex]);
            },
          ),
          );
        },
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

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final bool isPending;
  final String? status;

  const _SaleCard({required this.sale, this.isPending = false, this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final saleLabel = sale.saleNumber ?? sale.clientId ?? '---';
    final itemCount = sale.items.length;
    final itemSummary = itemCount == 1
        ? sale.items.first.productName
        : '$itemCount items';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPending
            ? null
            : () {
                final id = sale.id ?? sale.saleNumber;
                if (id != null) context.push('/sales/detail?saleId=$id');
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPending
                      ? colors.secondaryContainer
                      : colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPending ? Icons.cloud_upload_outlined : Icons.receipt_long,
                  color: isPending
                      ? colors.onTertiaryContainer
                      : colors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Sale info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$saleLabel',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status ?? 'pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        itemSummary,
                        if (sale.customerName != null) sale.customerName!,
                        if (sale.createdAt != null)
                          Formatters.dateTime(sale.createdAt!),
                      ].join(' \u00B7 '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(sale.totalAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sale.payments.isNotEmpty)
                    Text(
                      sale.payments.map((p) => p.method).join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              if (!isPending) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
