import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';
import '../../../di/injection.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/feeds/feed_cubits.dart';
import '../../widgets/aduinola/date_range_card.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/money_text.dart';
import '../transactions/transactions_screen.dart' show TransactionTile;

/// Saves export bytes to the app documents folder and returns the file.
typedef ExportSaver = Future<File> Function(DownloadedFile file);

Future<File> saveExport(DownloadedFile file) async {
  final dir = await getApplicationDocumentsDirectory();
  final out = File(p.join(dir.path, 'exports', file.fileName));
  await out.parent.create(recursive: true);
  return out.writeAsBytes(file.bytes, flush: true);
}

/// Sales report: summary cards (vs previous period), the period's sales and
/// PDF / Excel export.
class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key, this.remote, this.saver = saveExport});
  final FeedRemoteDataSource? remote;
  final ExportSaver saver;

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late final FeedRemoteDataSource _remote = widget.remote ?? sl<FeedRemoteDataSource>();
  late final TransactionsCubit _list;
  DateRangeValue _range = DateRangeValue.thisMonth(DateTime.now());
  ReportSummary? _summary;
  String? _summaryError;
  bool _busy = false;

  bool get _canViewReports => context.read<AuthBloc?>()?.state.can('view_reports') ?? true;

  @override
  void initState() {
    super.initState();
    _list = TransactionsCubit(_remote, filter: _filterFor(_range));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _list.close();
    super.dispose();
  }

  TransactionsFilter _filterFor(DateRangeValue r) =>
      TransactionsFilter(types: const {TxType.sale}, from: r.from, to: r.to);

  Future<void> _reload() async {
    final next = _filterFor(_range);
    if (next == _list.filter) {
      _list.refresh();
    } else {
      _list.setFilter(next);
    }
    if (!_canViewReports) return;
    setState(() => _summaryError = null);
    try {
      final now = DateTime.now();
      final s = await _remote.getReportSummary(
        from: _range.from ?? DateTime(2000),
        to: _range.to ?? DateTime(now.year, now.month, now.day),
      );
      if (mounted) setState(() => _summary = s);
    } on ServerException catch (e) {
      if (mounted) setState(() => _summaryError = e.message);
    } catch (_) {
      if (mounted) setState(() => _summaryError = context.tr('common.load_failed'));
    }
  }

  Map<String, dynamic> get _query {
    final now = DateTime.now();
    return {
      'from': FeedRemoteDataSource.day(_range.from ?? DateTime(2000)),
      'to': FeedRemoteDataSource.day(_range.to ?? now),
    };
  }

  Future<DownloadedFile?> _download(String format) async {
    setState(() => _busy = true);
    try {
      return await _remote.download(
        ApiConstants.exportSalesReport,
        query: {'format': format, ..._query},
        fallbackName: 'sales-report-${_query['from']}-${_query['to']}.$format',
      );
    } on ServerException catch (e) {
      _snack(e.message);
      return null;
    } catch (_) {
      if (mounted) _snack(context.tr('common.load_failed'));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), action: action));
  }

  Future<void> _save(String format) async {
    final shareLabel = context.tr('report.share');
    final file = await _download(format);
    if (file == null) return;
    final saved = await widget.saver(file);
    _snack(
      'Saved ${p.basename(saved.path)}',
      action: SnackBarAction(
        label: shareLabel,
        onPressed: () => Share.shareXFiles([XFile(saved.path, mimeType: file.mimeType)]),
      ),
    );
  }

  Future<void> _share() async {
    final file = await _download('pdf');
    if (file == null) return;
    final saved = await widget.saver(file);
    await Share.shareXFiles([XFile(saved.path, mimeType: file.mimeType)]);
  }

  Future<void> _print() async {
    final file = await _download('pdf');
    if (file == null) return;
    await Printing.layoutPdf(onLayout: (_) async => file.bytes, name: file.fileName);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: context.tr('report.title'),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: BlocBuilder<TransactionsCubit, FeedState<TransactionItem>>(
          bloc: _list,
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                DateRangeCard(
                  value: _range,
                  onChanged: (r) {
                    setState(() => _range = r);
                    _reload();
                  },
                ),
                const SizedBox(height: 12),
                if (_canViewReports) _cards(context),
                const SizedBox(height: 8),
                _exportBar(context),
                SectionLabel(context.tr('tx.title')),
                if (state.loading && state.items.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (state.error != null && state.items.isEmpty)
                  MessageView(icon: Icons.cloud_off_rounded, message: state.error!, onRetry: _reload)
                else if (state.items.isEmpty)
                  MessageView(icon: Icons.receipt_long_outlined, message: context.tr('common.nothing_here'))
                else
                  SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < state.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          TransactionTile(item: state.items[i]),
                        ],
                        if (state.hasMore)
                          TextButton(onPressed: _list.loadMore, child: const Text('Load more')),
                      ],
                    ),
                  ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(borderRadius: BorderRadius.circular(4)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cards(BuildContext context) {
    if (_summaryError != null) {
      return MessageView(icon: Icons.cloud_off_rounded, message: _summaryError!, onRetry: _reload);
    }
    final s = _summary;
    if (s == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    }
    final c = s.current;
    final prev = s.previous;
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _SummaryCard(
          key: const ValueKey('card-sales-count'),
          icon: Icons.sell_outlined,
          label: context.tr('report.sales'),
          value: Text('${c.salesCount}', style: Theme.of(context).textTheme.headlineSmall),
          change: ReportSummary.change(c.salesCount.toDouble(), prev?.salesCount.toDouble()),
        ),
        _SummaryCard(
          icon: Icons.payments_outlined,
          label: context.tr('common.amount'),
          value: MoneyText(c.salesAmount, compact: true, style: Theme.of(context).textTheme.headlineSmall),
          change: ReportSummary.change(c.salesAmount, prev?.salesAmount),
        ),
        _SummaryCard(
          icon: Icons.move_to_inbox_outlined,
          label: context.tr('report.received'),
          value: MoneyText(c.receivedAmount, compact: true, style: Theme.of(context).textTheme.headlineSmall),
          change: ReportSummary.change(c.receivedAmount, prev?.receivedAmount),
        ),
        _SummaryCard(
          icon: Icons.pending_actions_outlined,
          label: context.tr('report.unpaid'),
          value: MoneyText(c.unpaidAmount, compact: true, style: Theme.of(context).textTheme.headlineSmall),
          change: ReportSummary.change(c.unpaidAmount, prev?.unpaidAmount),
          higherIsBetter: false,
        ),
      ],
    );
  }

  Widget _exportBar(BuildContext context) {
    final actions = [
      (Icons.download_rounded, context.tr('report.download_pdf'), () => _save('pdf')),
      (Icons.print_outlined, 'Print PDF', _print),
      (Icons.table_view_outlined, context.tr('report.download_excel'), () => _save('xlsx')),
      (Icons.share_outlined, context.tr('report.share'), _share),
    ];
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _busy ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(icon, color: cs.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.change,
    this.higherIsBetter = true,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final double? change;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ch = change;
    final good = ch == null ? null : (ch >= 0) == higherIsBetter;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.surfaceContainerLow,
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const Spacer(),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
          Text(
            ch == null
                ? context.tr('report.vs_previous')
                : '${ch >= 0 ? '▲' : '▼'} ${ch.abs().toStringAsFixed(0)}% ${context.tr('report.vs_previous')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: good == null ? null : (good ? cs.primary : cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
