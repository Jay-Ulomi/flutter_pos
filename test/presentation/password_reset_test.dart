import 'package:flutter/material.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/datasources/remote/password_reset_remote.dart';
import 'package:flutter_pos/data/models/auth_models.dart';
import 'package:flutter_pos/presentation/blocs/password_reset/password_reset_cubit.dart';
import 'package:flutter_pos/presentation/screens/auth/forgot_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

void main() {
  late FakeApi api;
  late PasswordResetCubit cubit;

  setUp(() {
    api = FakeApi()
      ..on('POST', '/api/auth/forgot-password', (_) => const FakeReply(null))
      ..on('POST', '/api/auth/verify-reset-otp', (c) {
        final code = (c.body as Map)['code'];
        return code == '123456'
            ? const FakeReply({'resetToken': 'tok-1'})
            : FakeReply.error(400, 'Invalid or expired code');
      })
      ..on('POST', '/api/auth/reset-password', (_) => const FakeReply(null));
    cubit = PasswordResetCubit(PasswordResetRemoteDataSource(api.dio()));
  });

  group('LoginRequest', () {
    test('sends `login`, plus `email` only for addresses', () {
      expect(LoginRequest(email: 'amina', password: 'x').toJson(),
          {'login': 'amina', 'password': 'x'});
      expect(LoginRequest(email: 'a@shop.tz', password: 'x').toJson(),
          {'login': 'a@shop.tz', 'email': 'a@shop.tz', 'password': 'x'});
    });
  });

  group('PasswordResetCubit', () {
    test('walks email → code → password against the contract', () async {
      await cubit.requestCode(' owner@shop.tz ');
      expect(cubit.state.step, ResetStep.code);
      expect(api.calls.last.body, {'email': 'owner@shop.tz', 'method': 'OTP'});

      await cubit.verify('123456');
      expect(cubit.state.step, ResetStep.password);
      expect(cubit.state.resetToken, 'tok-1');

      await cubit.setPassword('NewPassw0rd', 'NewPassw0rd');
      expect(cubit.state.step, ResetStep.done);
      expect(api.calls.last.body, {'token': 'tok-1', 'newPassword': 'NewPassw0rd'});
    });

    test('shows the server message for a wrong code and stays on the code step', () async {
      await cubit.requestCode('owner@shop.tz');
      await cubit.verify('000000');
      expect(cubit.state.step, ResetStep.code);
      expect(cubit.state.error, 'Invalid or expired code');
    });

    test('validates locally before calling the server', () async {
      await cubit.requestCode('not-an-email');
      expect(cubit.state.error, 'auth.invalid_email');
      expect(api.calls, isEmpty);

      await cubit.requestCode('owner@shop.tz');
      await cubit.verify('12');
      expect(cubit.state.error, 'auth.enter_code');

      await cubit.verify('123456');
      await cubit.setPassword('short', 'short');
      expect(cubit.state.error, 'auth.password_short');
      await cubit.setPassword('LongEnough1', 'Different1');
      expect(cubit.state.error, 'auth.passwords_mismatch');
      expect(api.callsTo('/api/auth/reset-password'), isEmpty);
    });

    test('resend waits for the timer', () async {
      var now = DateTime(2026, 1, 1, 9);
      cubit = PasswordResetCubit(PasswordResetRemoteDataSource(api.dio()), clock: () => now);
      await cubit.requestCode('owner@shop.tz');
      await cubit.resend();
      expect(api.callsTo('/api/auth/forgot-password'), hasLength(1));
      now = now.add(PasswordResetCubit.resendDelay);
      await cubit.resend();
      expect(api.callsTo('/api/auth/forgot-password'), hasLength(2));
      expect(cubit.state.codesSent, 2);
    });
  });

  testWidgets('OTP screen: six boxes, resend timer, then new password', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: ForgotPasswordScreen(cubit: cubit),
    ));

    await tester.enterText(find.byKey(const ValueKey('reset-email')), 'owner@shop.tz');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('otp-box-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('resend-timer')), findsOneWidget);
    expect(find.textContaining('We sent a 6-digit code to owner@shop.tz'), findsOneWidget);

    // Typing all six digits submits automatically.
    await tester.enterText(find.byKey(const ValueKey('otp-input')), '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('new-password')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('new-password')), 'NewPassw0rd');
    await tester.enterText(find.byKey(const ValueKey('confirm-password')), 'Mismatch99');
    await tester.tap(find.text('Set password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('confirm-password')), 'NewPassw0rd');
    await tester.tap(find.text('Set password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Password changed'), findsOneWidget);
  });
}
