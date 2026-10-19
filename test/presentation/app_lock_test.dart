import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/security/app_lock_service.dart';
import 'package:flutter_pos/presentation/blocs/app_lock/app_lock_cubit.dart';
import 'package:flutter_pos/presentation/screens/lock/app_lock_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryPinStore store;
  late AppLockService service;

  setUp(() {
    store = MemoryPinStore();
    // Few rounds keep the tests fast; the format records the count.
    service = AppLockService(store, iterations: 10);
  });

  group('AppLockService', () {
    test('stores a salted hash, never the PIN', () async {
      await service.setPin('482913');
      final stored = store.values.values.single;
      expect(stored, isNot(contains('482913')));
      expect(stored.split('\$'), hasLength(4));
      expect(await service.verify('482913'), isTrue);
      expect(await service.verify('482914'), isFalse);
    });

    test('the same PIN hashes differently each time (random salt)', () async {
      await service.setPin('1234');
      final first = store.values.values.single;
      await service.setPin('1234');
      expect(store.values.values.single, isNot(first));
    });

    test('rejects PINs that are not 4–6 digits', () {
      expect(() => service.setPin('123'), throwsArgumentError);
      expect(() => service.setPin('12a4'), throwsArgumentError);
      expect(() => service.setPin('1234567'), throwsArgumentError);
    });

    test('PBKDF2 matches the RFC 7914 test vector', () {
      // PBKDF2-HMAC-SHA256("passwd", "salt", c=1), first 32 bytes.
      final out = AppLockService.pbkdf2('passwd'.codeUnits, 'salt'.codeUnits, 1);
      final hex = out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
    });
  });

  group('AppLockCubit', () {
    late DateTime now;
    late AppLockCubit cubit;

    setUp(() {
      now = DateTime(2026, 1, 1, 9);
      cubit = AppLockCubit(service, clock: () => now);
    });

    test('locks on start only when enabled and a PIN exists', () async {
      await cubit.init(enabled: true);
      expect(cubit.state.locked, isFalse, reason: 'no PIN set yet');
      await service.setPin('1234');
      await cubit.init(enabled: true);
      expect(cubit.state.locked, isTrue);
      await cubit.init(enabled: false);
      expect(cubit.state.locked, isFalse);
    });

    test('relocks after the background timeout', () async {
      await cubit.enable('1234');
      cubit.onBackgrounded();
      now = now.add(const Duration(minutes: 2));
      cubit.onResumed(lockAfterMinutes: 5);
      expect(cubit.state.locked, isFalse);

      cubit.onBackgrounded();
      now = now.add(const Duration(minutes: 5));
      cubit.onResumed(lockAfterMinutes: 5);
      expect(cubit.state.locked, isTrue);
    });

    test('wrong PINs count down, then a cooldown blocks entry', () async {
      await service.setPin('1234');
      await cubit.init(enabled: true);
      for (var i = 1; i < AppLockCubit.maxAttempts; i++) {
        expect(await cubit.unlock('0000'), isFalse);
        expect(cubit.state.failedAttempts, i);
      }
      expect(await cubit.unlock('0000'), isFalse);
      expect(cubit.state.retryAfter, isNotNull);
      expect(await cubit.unlock('1234'), isFalse, reason: 'still cooling down');

      now = now.add(AppLockCubit.cooldown);
      expect(await cubit.unlock('1234'), isTrue);
      expect(cubit.state.locked, isFalse);
    });

    test('disable removes the PIN', () async {
      await cubit.enable('1234');
      await cubit.disable();
      expect(await service.hasPin(), isFalse);
      expect(cubit.state.enabled, isFalse);
    });
  });

  testWidgets('lock screen unlocks with the right PIN', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await service.setPin('2468');
    final cubit = AppLockCubit(service);
    await cubit.init(enabled: true);
    var forgot = false;

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: AppLockScreen(onForgot: () => forgot = true),
      ),
    ));
    expect(find.text('Enter your PIN'), findsOneWidget);

    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.byKey(ValueKey('pin-key-$d')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('pin-key-ok')));
      await tester.pumpAndSettle();
    }

    await enter('1111');
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
    expect(cubit.state.locked, isTrue);

    await enter('2468');
    expect(cubit.state.locked, isFalse);

    await tester.tap(find.text('Forgot PIN? Sign out'));
    expect(forgot, isTrue);
  });
}
