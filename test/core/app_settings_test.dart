import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/l10n/app_strings.dart';
import 'package:flutter_pos/core/settings/app_settings.dart';
import 'package:flutter_pos/core/utils/formatters.dart';
import 'package:flutter_pos/presentation/blocs/app_settings/app_settings_cubit.dart';
import 'package:flutter_pos/presentation/widgets/money_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Formatters.configure(const AppSettings());
  });
  tearDown(() => Formatters.configure(const AppSettings()));

  group('AppSettingsCubit', () {
    test('persists every preference and reloads it', () async {
      final cubit = AppSettingsCubit();
      const next = AppSettings(
        themeMode: ThemeMode.dark,
        textScale: 1.15,
        languageCode: 'sw',
        datePattern: 'yyyy-MM-dd',
        use24Hour: false,
        numberStyle: NumberStyle.dotComma,
        currencySymbol: 'TSh',
        symbolAfterAmount: true,
        showDecimals: false,
        privacyMode: true,
        appLockEnabled: true,
        lockAfterMinutes: 5,
      );
      await cubit.update(next);

      final reloaded = AppSettingsCubit();
      await reloaded.load();
      expect(reloaded.state, next);
    });

    test('keeps a theme chosen before the redesign', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final cubit = AppSettingsCubit();
      await cubit.load();
      expect(cubit.state.themeMode, ThemeMode.dark);
    });

    test('pushes number and currency preferences into Formatters', () async {
      final cubit = AppSettingsCubit();
      expect(Formatters.currency(1234567.5), 'TZS 1,234,567.50');

      await cubit.update(cubit.state.copyWith(
        numberStyle: NumberStyle.dotComma,
        currencySymbol: 'TSh',
        symbolAfterAmount: true,
      ));
      expect(Formatters.currency(1234567.5), '1.234.567,50 TSh');

      await cubit.update(cubit.state.copyWith(
        numberStyle: NumberStyle.spaceDot,
        showDecimals: false,
        symbolAfterAmount: false,
      ));
      expect(Formatters.currency(1234567), 'TSh 1 234 567');
    });

    test('applies the date and time format', () async {
      final cubit = AppSettingsCubit();
      final dt = DateTime(2026, 3, 7, 15, 5);
      await cubit.update(cubit.state.copyWith(datePattern: 'yyyy-MM-dd', use24Hour: false));
      expect(Formatters.date(dt), '2026-03-07');
      expect(Formatters.time(dt), '3:05 PM');
    });
  });

  group('privacy mode', () {
    testWidgets('MoneyText masks amounts but leaves customer-facing ones', (tester) async {
      final cubit = AppSettingsCubit();
      await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: Column(children: [
            MoneyText(2500),
            MoneyText(900, sensitive: false),
          ]),
        ),
      ));
      expect(find.text('TZS 2,500.00'), findsOneWidget);

      await cubit.togglePrivacy();
      await tester.pump();
      expect(find.text('TZS 2,500.00'), findsNothing);
      expect(find.text('TZS ••••'), findsOneWidget);
      expect(find.text('TZS 900.00'), findsOneWidget);
    });

    testWidgets('MoneyText works without an AppSettingsCubit above it', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MoneyText(10)));
      expect(find.text('TZS 10.00'), findsOneWidget);
    });
  });

  group('AppStrings', () {
    test('Swahili covers every English key', () {
      expect(AppStrings.keys('sw'), AppStrings.keys('en'));
    });

    testWidgets('tr picks the app locale and fills placeholders', (tester) async {
      late String en, sw;
      await tester.pumpWidget(Localizations(
        locale: const Locale('sw'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(builder: (context) {
          sw = context.tr('nav.home');
          en = AppStrings.of('en', 'nav.home');
          return const SizedBox();
        }),
      ));
      expect(sw, 'Nyumbani');
      expect(en, 'Home');
      expect(AppStrings.of('sw', 'missing.key'), 'missing.key');
    });
  });
}
