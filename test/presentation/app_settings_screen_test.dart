import 'package:flutter/material.dart';
import 'package:flutter_pos/core/security/app_lock_service.dart';
import 'package:flutter_pos/core/settings/app_settings.dart';
import 'package:flutter_pos/core/utils/formatters.dart';
import 'package:flutter_pos/presentation/blocs/app_lock/app_lock_cubit.dart';
import 'package:flutter_pos/presentation/blocs/app_settings/app_settings_cubit.dart';
import 'package:flutter_pos/presentation/screens/settings/app_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Formatters.configure(const AppSettings()));

  testWidgets('number format and privacy mode apply immediately', (tester) async {
    usePhone(tester);
    final settings = AppSettingsCubit();
    await pumpRoutes(tester, initial: '/s', settings: settings, routes: [
      GoRoute(path: '/s', builder: (_, _) => const AppSettingsScreen()),
    ]);
    expect(find.text('TZS 1,234,567.50'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Number format'), 200);
    await tester.tap(find.text('Number format'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.234.567,89').last);
    await tester.pumpAndSettle();
    expect(settings.state.numberStyle, NumberStyle.dotComma);
    expect(find.text('TZS 1.234.567,50'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('set-privacy')), 200);
    await tester.tap(find.byKey(const ValueKey('set-privacy')));
    await tester.pumpAndSettle();
    expect(settings.state.privacyMode, isTrue);
  });

  testWidgets('turning on app lock asks for a PIN twice and stores it', (tester) async {
    usePhone(tester);
    final store = MemoryPinStore();
    final service = AppLockService(store, iterations: 10);
    final lock = AppLockCubit(service);
    final settings = AppSettingsCubit();
    await pumpRoutes(tester, initial: '/s', settings: settings, lock: lock, routes: [
      GoRoute(path: '/s', builder: (_, _) => const AppSettingsScreen()),
    ]);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('set-app-lock')), 200);
    await tester.tap(find.byKey(const ValueKey('set-app-lock')));
    await tester.pumpAndSettle();
    expect(find.text('Create a 4–6 digit PIN'), findsOneWidget);

    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.byKey(ValueKey('pin-key-$d')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('pin-key-ok')));
      await tester.pumpAndSettle();
    }

    await enter('1357');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await enter('1357');

    expect(settings.state.appLockEnabled, isTrue);
    expect(lock.state.enabled, isTrue);
    expect(await service.verify('1357'), isTrue);
    expect(store.values.values.single, isNot(contains('1357')));
  });
}
