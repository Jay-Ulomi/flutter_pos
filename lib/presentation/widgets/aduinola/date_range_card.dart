import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import 'ui.dart';

/// A chosen period; both null = all time.
class DateRangeValue {
  const DateRangeValue({this.from, this.to, this.label});
  final DateTime? from;
  final DateTime? to;

  /// Preset name ("Today", "This month"); null for a custom range.
  final String? label;

  bool get isAllTime => from == null && to == null;

  static DateTime _d(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateRangeValue today(DateTime now) =>
      DateRangeValue(from: _d(now), to: _d(now), label: 'Today');
  static DateRangeValue thisWeek(DateTime now) => DateRangeValue(
      from: _d(now).subtract(Duration(days: now.weekday - 1)), to: _d(now), label: 'This week');
  static DateRangeValue thisMonth(DateTime now) =>
      DateRangeValue(from: DateTime(now.year, now.month), to: _d(now), label: 'This month');
  static DateRangeValue lastMonth(DateTime now) => DateRangeValue(
      from: DateTime(now.year, now.month - 1),
      to: DateTime(now.year, now.month, 0),
      label: 'Last month');
  static DateRangeValue thisYear(DateTime now) =>
      DateRangeValue(from: DateTime(now.year), to: _d(now), label: 'This year');

  String describe(BuildContext context) {
    if (isAllTime) return 'All Time';
    if (label != null) return label!;
    final f = from == null ? '…' : Formatters.date(from!);
    final t = to == null ? '…' : Formatters.date(to!);
    return '$f – $t';
  }
}

/// "📅 All Time   (⟳ Change)" card from the design.
class DateRangeCard extends StatelessWidget {
  const DateRangeCard({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAllTime = true,
  });

  final DateRangeValue value;
  final ValueChanged<DateRangeValue> onChanged;
  final bool allowAllTime;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final presets = [
      if (allowAllTime) const DateRangeValue(),
      DateRangeValue.today(now),
      DateRangeValue.thisWeek(now),
      DateRangeValue.thisMonth(now),
      DateRangeValue.lastMonth(now),
      DateRangeValue.thisYear(now),
    ];
    final chosen = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in presets)
              ListTile(
                title: Text(p.describe(ctx)),
                trailing: p.label == value.label && p.isAllTime == value.isAllTime
                    ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, p),
              ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded),
              title: Text(ctx.tr('tx.date_range')),
              onTap: () => Navigator.pop(ctx, 'custom'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || chosen == null) return;
    if (chosen is DateRangeValue) {
      onChanged(chosen);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: value.from != null && value.to != null
          ? DateTimeRange(start: value.from!, end: value.to!)
          : null,
    );
    if (range != null) onChanged(DateRangeValue(from: range.start, to: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      onTap: () => _pick(context),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: cs.surfaceContainerLow, shape: BoxShape.circle),
            child: Icon(Icons.calendar_month_outlined, size: 20, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value.describe(context), style: Theme.of(context).textTheme.titleMedium),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: cs.primary,
            ),
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: Text(context.tr('sale.change')),
          ),
        ],
      ),
    );
  }
}
