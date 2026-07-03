import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import '../../widgets/responsive_shell.dart';

class CloseSessionScreen extends StatefulWidget {
  const CloseSessionScreen({super.key});

  @override
  State<CloseSessionScreen> createState() => _CloseSessionScreenState();
}

class _CloseSessionScreenState extends State<CloseSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _useDenominations = false;
  final Map<int, int> _denomCounts = {
    50000: 0,
    20000: 0,
    10000: 0,
    5000: 0,
    2000: 0,
    1000: 0,
    500: 0,
    200: 0,
    100: 0,
    50: 0,
  };

  @override
  void initState() {
    super.initState();
    final sessionId = context.read<SessionBloc>().state.current?.id;
    if (sessionId != null) {
      context.read<SessionBloc>().add(SessionSummaryRequested(sessionId));
    }
  }

  @override
  void dispose() {
    _actualCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _actual => _useDenominations
      ? _denomTotal
      : (double.tryParse(_actualCtrl.text) ?? 0);

  double get _denomTotal =>
      _denomCounts.entries.fold(0.0, (sum, e) => sum + e.key * e.value);

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      appBar: AppBar(title: const Text('Close Session')),
      child: BlocConsumer<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state.status == SessionStatus.closed) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Session closed')));
            context.go('/session/open');
          } else if (state.status == SessionStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final session = state.current;
          if (session == null) {
            return const LoadingIndicator(message: 'Loading session...');
          }
          final summary = state.summary;
          final expected =
              summary?.expectedCash ??
              (session.openingCash + (summary?.totalCashReceived ?? 0));
          final variance = _actual - expected;
          final loading = state.status == SessionStatus.loading;
          final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          Widget summaryCard = Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row('Opening cash', session.openingCash),
                  const Divider(),
                  _row(
                    'Total revenue',
                    summary?.totalRevenue ?? 0,
                    emphasize: true,
                  ),
                  _row('Cash sales', summary?.totalCashReceived ?? 0),
                  _row('Card sales', summary?.totalCardReceived ?? 0),
                  _row('Mobile sales', summary?.totalMobileReceived ?? 0),
                  if (summary != null && summary.totalSales > 0)
                    _row('Sales count', summary.totalSales.toDouble()),
                  if (summary != null &&
                      (summary.totalReturns > 0 ||
                          summary.totalRefunds > 0)) ...[
                    const Divider(),
                    _row('Returns', summary.totalReturns.toDouble()),
                    _row('Refunds', summary.totalRefunds),
                  ],
                  const Divider(),
                  _row('Expected cash in drawer', expected, emphasize: true),
                  if (summary == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: colors.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Summary unavailable \u2014 amounts may be inaccurate offline.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );

          Widget cashCountSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Cash counted',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Total')),
                        ButtonSegment(
                          value: true,
                          label: Text('Denominations'),
                        ),
                      ],
                      selected: {_useDenominations},
                      onSelectionChanged: (s) =>
                          setState(() => _useDenominations = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_useDenominations)
                TextFormField(
                  controller: _actualCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Actual cash counted',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (_useDenominations) return null;
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 0) return 'Invalid amount';
                    return null;
                  },
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final denom in _denomCounts.keys)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'TZS ${(denom / 1000).toStringAsFixed(0)}${denom >= 1000 ? 'K' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Decrease',
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: _denomCounts[denom]! > 0
                                      ? () => setState(
                                          () => _denomCounts[denom] =
                                              _denomCounts[denom]! - 1,
                                        )
                                      : null,
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${_denomCounts[denom]}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Increase',
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _denomCounts[denom] =
                                        _denomCounts[denom]! + 1,
                                  ),
                                ),
                                const Spacer(),
                                MoneyText(
                                  (denom * _denomCounts[denom]!).toDouble(),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            MoneyText(
                              _denomTotal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

          Widget actionSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _varianceDisplay(context, variance),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: summary != null
                    ? () => context.push(
                        '/session/report?sessionId=${session.id}',
                      )
                    : null,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('View Shift Report (Z-Report)'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loading
                    ? null
                    : () {
                        if (!_useDenominations &&
                            _formKey.currentState?.validate() != true) {
                          return;
                        }
                        context.read<SessionBloc>().add(
                          SessionCloseRequested(
                            sessionId: session.id,
                            closingCash: _actual,
                            notes: _notesCtrl.text.isEmpty
                                ? null
                                : _notesCtrl.text,
                          ),
                        );
                      },
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline),
                label: const Text('Close Session'),
              ),
            ],
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: isDesktop
                      ? SingleChildScrollView(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    summaryCard,
                                    const SizedBox(height: 16),
                                    cashCountSection,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(flex: 5, child: actionSection),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            summaryCard,
                            const SizedBox(height: 16),
                            cashCountSection,
                            const SizedBox(height: 14),
                            actionSection,
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, double amount, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: emphasize
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          MoneyText(
            amount,
            style: emphasize
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _varianceDisplay(BuildContext context, double variance) {
    final theme = Theme.of(context);
    final color = variance == 0
        ? theme.colorScheme.primary
        : (variance < 0 ? theme.colorScheme.error : theme.colorScheme.tertiary);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Variance'),
          MoneyText(
            variance,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
