import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/l10n/app_strings.dart';
import 'core/network/network_info.dart';
import 'core/security/app_lock_service.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/token_manager.dart';
import 'di/injection.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/customer_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/sale_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/repositories/sync_repository.dart';
import 'presentation/blocs/app_lock/app_lock_cubit.dart';
import 'presentation/blocs/app_settings/app_settings_cubit.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/branch/branch_bloc.dart';
import 'presentation/blocs/business/business_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/customer/customer_bloc.dart';
import 'presentation/blocs/customer_group/customer_group_bloc.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/sale/sale_bloc.dart';
import 'presentation/blocs/session/session_bloc.dart';
import 'presentation/blocs/held_sales/held_sales_cubit.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/sync/sync_event.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/screens/lock/app_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await setupDependencies();
  runApp(const PosApp());
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> with WidgetsBindingObserver {
  // Kept for code that still reads it; theme now comes from AppSettingsCubit.
  final _themeCubit = ThemeCubit();
  final _settingsCubit = AppSettingsCubit();
  final _lockCubit = AppLockCubit(sl.isRegistered<AppLockService>()
      ? sl<AppLockService>()
      : AppLockService(SecurePinStore()));
  AuthBloc? _authBloc;
  BusinessBloc? _businessBloc;
  BranchBloc? _branchBloc;
  SessionBloc? _sessionBloc;
  SyncBloc? _syncBloc;
  GoRouter? _router;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapFuture = _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _lockCubit.onBackgrounded();
    }
    if (state == AppLifecycleState.resumed) {
      _lockCubit.onResumed(lockAfterMinutes: _settingsCubit.state.lockAfterMinutes);
      // Flush any queued sales — covers the case where connectivity was
      // restored while the app was backgrounded (so the reconnect push never
      // fired).
      _syncBloc?.add(const SyncAutoRetryRequested());
      // Re-check subscription status — covers the case where the user paid
      // via the billing portal (opened in an external browser) while the app
      // was backgrounded, so the trial/past-due gate reflects it immediately
      // instead of only after a full app restart.
      _authBloc?.add(const AuthSubscriptionRefreshRequested());
    }
  }

  Future<void> _bootstrap() async {
    if (!sl.isRegistered<AuthRepository>()) {
      await setupDependencies();
    }
    await _settingsCubit.load();
    await _lockCubit.init(enabled: _settingsCubit.state.appLockEnabled);
    _authBloc = AuthBloc(sl<AuthRepository>(), sl<TokenManager>())
      ..add(const AuthCheckRequested());
    _businessBloc = BusinessBloc(sl<AuthRepository>());
    _branchBloc = BranchBloc(sl<AuthRepository>());
    _sessionBloc = SessionBloc(sl<SessionRepository>(), sl<SaleRepository>());
    _syncBloc = SyncBloc(
      sl<SyncRepository>(),
      sl<NetworkInfo>(),
      sl<TokenManager>(),
    );
    // Build the router once — rebuilding it on every theme/state change resets
    // navigation state and re-runs redirects.
    _router = AppRouter.build(
      authBloc: _authBloc!,
      businessBloc: _businessBloc!,
      sessionBloc: _sessionBloc!,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeCubit.close();
    _settingsCubit.close();
    _lockCubit.close();
    _authBloc?.close();
    _businessBloc?.close();
    _branchBloc?.close();
    _sessionBloc?.close();
    _syncBloc?.close();
    super.dispose();
  }

  /// MaterialApp settings shared by the boot, error and main apps.
  static const _localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  static final _supportedLocales =
      AppStrings.supported.map((c) => Locale(c)).toList();

  /// Applies the App Settings text size and draws the lock screen on top.
  Widget _appBuilder(BuildContext context, Widget? child, AppSettings settings) {
    final media = MediaQuery.of(context);
    final scaled = MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          media.textScaler.scale(1) * settings.textScale,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, lock) {
        final signedOut = context.select<AuthBloc, bool>(
          (b) => b.state.status == AuthStatus.unauthenticated,
        );
        if (!lock.locked || signedOut) return scaled;
        return Stack(
          children: [
            Offstage(child: scaled),
            AppLockScreen(
              onForgot: () async {
                await _lockCubit.reset();
                await _settingsCubit.update(
                  _settingsCubit.state.copyWith(appLockEnabled: false),
                );
                _authBloc?.add(const AuthLogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<AppSettingsCubit>.value(value: _settingsCubit),
        BlocProvider<AppLockCubit>.value(value: _lockCubit),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettings>(
        builder: (context, settings) {
          return FutureBuilder<void>(
            future: _bootstrapFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: settings.themeMode,
                  home: const _BootSplash(),
                );
              }

              if (snapshot.hasError) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: settings.themeMode,
                  home: Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to initialize app dependencies.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: _authBloc!),
                  BlocProvider<BusinessBloc>.value(value: _businessBloc!),
                  BlocProvider<BranchBloc>.value(value: _branchBloc!),
                  BlocProvider<SessionBloc>.value(value: _sessionBloc!),
                  BlocProvider<SyncBloc>.value(value: _syncBloc!),
                  BlocProvider<ProductBloc>(
                    create: (_) => ProductBloc(sl<ProductRepository>()),
                  ),
                  BlocProvider<CartBloc>(create: (_) => CartBloc()),
                  BlocProvider<HeldSalesCubit>(create: (_) => HeldSalesCubit()),
                  BlocProvider<SaleBloc>(
                    create: (_) =>
                        SaleBloc(sl<SaleRepository>(), sl<NetworkInfo>()),
                  ),
                  BlocProvider<CustomerBloc>(
                    create: (_) => CustomerBloc(sl<CustomerRepository>()),
                  ),
                  BlocProvider<CustomerGroupBloc>(
                    create: (_) => CustomerGroupBloc(sl<CustomerRepository>()),
                  ),
                ],
                child: MaterialApp.router(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: settings.themeMode,
                  locale: settings.locale,
                  supportedLocales: _supportedLocales,
                  localizationsDelegates: _localizationsDelegates,
                  builder: (context, child) =>
                      _appBuilder(context, child, settings),
                  routerConfig: _router!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shown while dependencies load: wordmark on the brand gradient.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.decor.background),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/aduinola_wordmark.png', height: 56),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
