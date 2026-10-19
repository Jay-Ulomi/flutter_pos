import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/app_lock/app_lock_cubit.dart';
import '../../blocs/app_settings/app_settings_cubit.dart';
import '../../widgets/aduinola/app_page.dart';
import '../../widgets/aduinola/ui.dart';
import '../lock/app_lock_screen.dart';

/// Device-only display, format and security preferences.
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppSettingsCubit>();
    return BlocBuilder<AppSettingsCubit, AppSettings>(
      builder: (context, s) {
        void set(AppSettings next) => cubit.update(next);

        String themeLabel(ThemeMode m) => switch (m) {
              ThemeMode.light => context.tr('settings.light'),
              ThemeMode.dark => context.tr('settings.dark'),
              ThemeMode.system => context.tr('settings.system'),
            };
        String scaleLabel(double v) => switch (v) {
              0.9 => 'Small',
              1.0 => 'Normal',
              1.15 => 'Large',
              _ => 'Extra large',
            };
        const langNames = {'en': 'English', 'sw': 'Kiswahili'};
        String numberLabel(NumberStyle n) => switch (n) {
              NumberStyle.commaDot => '1,234,567.89',
              NumberStyle.dotComma => '1.234.567,89',
              NumberStyle.spaceDot => '1 234 567.89',
            };
        String lockLabel(int m) =>
            m == 0 ? context.tr('settings.immediately') : context.tr('settings.minutes', {'n': m});
        final sample = DateTime(2026, 2, 26, 16, 20);

        return AppPage(
          title: context.tr('settings.title'),
          padBody: false,
          body: _SectionColumns(
            children: [
              SectionLabel(context.tr('settings.appearance')),
              _Group(children: [
                _ChoiceRow<ThemeMode>(
                  key: const ValueKey('set-theme'),
                  icon: Icons.contrast_rounded,
                  label: context.tr('settings.theme'),
                  value: s.themeMode,
                  options: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
                  labelOf: themeLabel,
                  onChanged: (v) => set(s.copyWith(themeMode: v)),
                ),
                _ChoiceRow<double>(
                  icon: Icons.format_size_rounded,
                  label: context.tr('settings.text_size'),
                  value: s.textScale,
                  options: AppSettings.textScales,
                  labelOf: scaleLabel,
                  onChanged: (v) => set(s.copyWith(textScale: v)),
                ),
                _ChoiceRow<String>(
                  key: const ValueKey('set-language'),
                  icon: Icons.translate_rounded,
                  label: context.tr('settings.language'),
                  value: s.languageCode,
                  options: AppSettings.languages,
                  labelOf: (c) => langNames[c] ?? c,
                  onChanged: (v) => set(s.copyWith(languageCode: v)),
                ),
              ]),
              SectionLabel(context.tr('settings.formats')),
              _Group(children: [
                _ChoiceRow<String>(
                  icon: Icons.event_outlined,
                  label: context.tr('settings.date_format'),
                  value: s.datePattern,
                  options: AppSettings.datePatterns,
                  labelOf: (p) => DateFormat(p).format(sample),
                  onChanged: (v) => set(s.copyWith(datePattern: v)),
                ),
                _ChoiceRow<bool>(
                  icon: Icons.schedule_rounded,
                  label: context.tr('settings.time_format'),
                  value: s.use24Hour,
                  options: const [true, false],
                  labelOf: (v) => v ? '${context.tr('settings.24h')} (16:20)' : '${context.tr('settings.12h')} (4:20 PM)',
                  onChanged: (v) => set(s.copyWith(use24Hour: v)),
                ),
                _ChoiceRow<NumberStyle>(
                  icon: Icons.pin_outlined,
                  label: context.tr('settings.number_format'),
                  value: s.numberStyle,
                  options: NumberStyle.values,
                  labelOf: numberLabel,
                  onChanged: (v) => set(s.copyWith(numberStyle: v)),
                ),
              ]),
              SectionLabel(context.tr('settings.currency')),
              _Group(children: [
                ListTile(
                  leading: const Icon(Icons.attach_money_rounded),
                  title: Text(context.tr('settings.currency_symbol')),
                  trailing: Text(s.currencySymbol, style: Theme.of(context).textTheme.titleMedium),
                  onTap: () async {
                    final v = await _askSymbol(context, s.currencySymbol);
                    if (v != null) set(s.copyWith(currencySymbol: v));
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.swap_horiz_rounded),
                  title: Text(context.tr('settings.symbol_after')),
                  value: s.symbolAfterAmount,
                  onChanged: (v) => set(s.copyWith(symbolAfterAmount: v)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.exposure_rounded),
                  title: Text(context.tr('settings.show_decimals')),
                  value: s.showDecimals,
                  onChanged: (v) => set(s.copyWith(showDecimals: v)),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(context.tr('settings.preview')),
                  trailing: Text(
                    Formatters.currency(1234567.5),
                    key: const ValueKey('currency-preview'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ]),
              SectionLabel(context.tr('settings.privacy')),
              _Group(children: [
                SwitchListTile(
                  key: const ValueKey('set-privacy'),
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: Text(context.tr('settings.privacy_mode')),
                  subtitle: Text(context.tr('settings.privacy_mode_sub')),
                  value: s.privacyMode,
                  onChanged: (v) => set(s.copyWith(privacyMode: v)),
                ),
                SwitchListTile(
                  key: const ValueKey('set-app-lock'),
                  secondary: const Icon(Icons.lock_outline_rounded),
                  title: Text(context.tr('settings.app_lock')),
                  subtitle: Text(context.tr('settings.app_lock_sub')),
                  value: s.appLockEnabled,
                  onChanged: (v) => _toggleLock(context, s, v),
                ),
                if (s.appLockEnabled) ...[
                  _ChoiceRow<int>(
                    icon: Icons.timer_outlined,
                    label: context.tr('settings.lock_after'),
                    value: s.lockAfterMinutes,
                    options: AppSettings.lockTimeouts,
                    labelOf: lockLabel,
                    onChanged: (v) => set(s.copyWith(lockAfterMinutes: v)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: Text(context.tr('settings.change_pin')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final pin = await showCreatePinSheet(context);
                      if (pin != null && context.mounted) await context.read<AppLockCubit>().enable(pin);
                    },
                  ),
                ],
              ]),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLock(BuildContext context, AppSettings s, bool on) async {
    final settings = context.read<AppSettingsCubit>();
    final lock = context.read<AppLockCubit>();
    if (on) {
      final pin = await showCreatePinSheet(context);
      if (pin == null) return;
      await lock.enable(pin);
      await settings.update(settings.state.copyWith(appLockEnabled: true));
    } else {
      await lock.disable();
      await settings.update(settings.state.copyWith(appLockEnabled: false));
    }
  }

  Future<String?> _askSymbol(BuildContext context, String current) {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('settings.currency_symbol')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl, maxLength: 6, autofocus: true),
            Wrap(
              spacing: 8,
              children: [
                for (final sym in const ['TZS', 'TSh', 'KES', 'UGX', 'USD', r'$'])
                  ActionChip(label: Text(sym), onPressed: () => Navigator.pop(ctx, sym)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
  }
}

/// Lays (label, group) pairs out full width: one column on phones, two
/// side by side from 900 px.
class _SectionColumns extends StatelessWidget {
  const _SectionColumns({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      for (var i = 0; i + 1 < children.length; i += 2)
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [children[i], children[i + 1]]),
    ];
    return ListView(
      padding: AppPage.insets(context, top: 0),
      children: [
        LayoutBuilder(builder: (context, c) {
          final cols = responsiveColumns(c.maxWidth, max: 2);
          final w = (c.maxWidth - 16 * (cols - 1)) / cols;
          return Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [for (final s in sections) SizedBox(width: w, child: s)],
          );
        }),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// "Label …… Value ›" row that opens a picker sheet.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(labelOf(value), style: TextStyle(color: cs.onSurfaceVariant)),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () async {
        final picked = await showModalBottomSheet<T>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(labelOf(o)),
                    trailing: o == value ? Icon(Icons.check_rounded, color: cs.primary) : null,
                    onTap: () => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
