import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pos/core/security/app_lock_service.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/token_manager.dart';
import 'package:flutter_pos/data/models/auth_models.dart';
import 'package:flutter_pos/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/presentation/blocs/app_lock/app_lock_cubit.dart';
import 'package:flutter_pos/presentation/blocs/app_settings/app_settings_cubit.dart';
import 'package:flutter_pos/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_pos/presentation/blocs/auth/auth_state.dart';
import 'package:flutter_pos/presentation/blocs/branch/branch_bloc.dart';
import 'package:flutter_pos/presentation/blocs/business/business_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _NoAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTokens implements TokenManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// AuthBloc pinned to a given state (no repository calls).
class TestAuthBloc extends AuthBloc {
  TestAuthBloc(AuthState initial) : super(_NoAuthRepo(), _NoTokens()) {
    emit(initial);
  }

  static TestAuthBloc signedIn({Set<String> permissions = const {'*'}}) => TestAuthBloc(AuthState(
        status: AuthStatus.authenticated,
        businessId: 'b1',
        branchId: 'br1',
        user: const User(
          id: 'u1',
          email: 'amina@shop.tz',
          firstName: 'Amina',
          lastName: 'Juma',
          role: 'tenant_owner',
        ),
        permissions: permissions,
      ));
}

/// Sets a phone-sized test surface.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [routes] under a GoRouter with the app-wide blocs the redesigned
/// screens read. Returns the router so tests can inspect the location.
Future<GoRouter> pumpRoutes(
  WidgetTester tester, {
  required String initial,
  required List<RouteBase> routes,
  AuthBloc? auth,
  AppSettingsCubit? settings,
  AppLockCubit? lock,
  Locale locale = const Locale('en'),
}) async {
  final authBloc = auth ?? TestAuthBloc.signedIn();
  final router = GoRouter(initialLocation: initial, routes: routes);
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<BusinessBloc>(create: (_) => BusinessBloc(_NoAuthRepo())),
      // Always provided app-wide in main.dart — screens (Profile's
      // business/branch rows) rely on it being here.
      BlocProvider<BranchBloc>(create: (_) => BranchBloc(_NoAuthRepo())),
      BlocProvider<AppSettingsCubit>.value(value: settings ?? AppSettingsCubit()),
      BlocProvider<AppLockCubit>.value(
        value: lock ?? AppLockCubit(AppLockService(MemoryPinStore(), iterations: 10)),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('sw')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  ));
  await tester.pump();
  return router;
}

/// A stub page that shows its own path.
GoRoute stubRoute(String path) =>
    GoRoute(path: path, builder: (_, s) => Scaffold(body: Text('stub:${s.uri}')));
