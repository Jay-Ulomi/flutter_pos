import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import '../../widgets/responsive_shell.dart';

class ShiftReportScreen extends StatefulWidget {
  final String? sessionId;
  const ShiftReportScreen({super.key, this.sessionId});

  @override
  State<ShiftReportScreen> createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  @override
  void initState() {
    super.initState();
    final id =
        widget.sessionId ?? context.read<SessionBloc>().state.current?.id;
    if (id != null) {
      context.read<SessionBloc>().add(SessionSummaryRequested(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveShell(
      appBar: AppBar(title: const Text('Shift Report (Z-Report)')),
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          final summary = state.summary;
          final session = state.current;

          if (summary == null) {
            return const LoadingIndicator(message: 'Loading report...');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Session info ──
              if (session != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Details',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Cashier',
                          session.userName ?? summary.userId ?? '—',
                        ),
                        _infoRow(
                          'Opened',
                          DateFormat.yMd().add_jm().format(session.openedAt),
                        ),
                        if (session.closedAt != null)
                          _infoRow(
                            'Closed',
                            DateFormat.yMd().add_jm().format(session.closedAt!),
                          ),
                        _infoRow('Status', session.status),
                      ],
                    ),
                  ),
                ),
              if (session == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Details',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (summary.openedAt != null)
                          _infoRow(
                            'Opened',
                            DateFormat.yMd().add_jm().format(summary.openedAt!),
                          ),
                        if (summary.closedAt != null)
                          _infoRow(
                            'Closed',
                            DateFormat.yMd().add_jm().format(summary.closedAt!),
                          ),
                        _infoRow('Status', summary.status ?? '—'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // ── Sales summary ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales Summary', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _amountRow('Total Sales', summary.totalSales.toDouble()),
                      _amountRow(
                        'Voided Sales',
                        summary.voidedSalesCount.toDouble(),
                      ),
                      _amountRow(
                        'Total Revenue',
                        summary.totalRevenue,
                        emphasize: true,
                      ),
                      const Divider(),
                      _amountRow('Cash Received', summary.totalCashReceived),
                      _amountRow('Card Received', summary.totalCardReceived),
                      _amountRow(
                        'Mobile Received',
                        summary.totalMobileReceived,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Returns & refunds ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Returns & Refunds',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _amountRow('Returns', summary.totalReturns.toDouble()),
                      _amountRow('Refunds', summary.totalRefunds),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Cash reconciliation ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Reconciliation',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (session != null)
                        _amountRow('Opening Cash', session.openingCash),
                      if (session == null)
                        _amountRow('Opening Cash', summary.openingCash),
                      _amountRow('Cash Sales', summary.totalCashReceived),
                      _amountRow('Cash In', summary.totalCashIn),
                      _amountRow('Cash Out', summary.totalCashOut),
                      _amountRow(
                        'Expected Cash',
                        summary.expectedCash,
                        emphasize: true,
                      ),
                      if (summary.closingCash != null) ...[
                        _amountRow('Counted Cash', summary.closingCash!),
                        _varianceRow(summary.cashDifference, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasize
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
          MoneyText(
            amount,
            style: emphasize
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _varianceRow(double variance, ThemeData theme) {
    final color = variance == 0
        ? theme.colorScheme.primary
        : (variance < 0 ? theme.colorScheme.error : theme.colorScheme.tertiary);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Variance',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          MoneyText(
            variance,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
