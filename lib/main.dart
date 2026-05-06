import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_constants.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/token_manager.dart';
import 'di/injection.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/customer_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/sale_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/repositories/sync_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
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
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/routes/app_router.dart';

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

class _PosAppState extends State<PosApp> {
  final _themeCubit = ThemeCubit();
  AuthBloc? _authBloc;
  BusinessBloc? _businessBloc;
  BranchBloc? _branchBloc;
  SessionBloc? _sessionBloc;
  SyncBloc? _syncBloc;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!sl.isRegistered<AuthRepository>()) {
      await setupDependencies();
    }
    _authBloc = AuthBloc(sl<AuthRepository>(), sl<TokenManager>())
      ..add(const AuthCheckRequested());
    _businessBloc = BusinessBloc(sl<AuthRepository>());
    _branchBloc = BranchBloc(sl<AuthRepository>());
    _sessionBloc = SessionBloc(sl<SessionRepository>());
    _syncBloc = SyncBloc(
      sl<SyncRepository>(),
      sl<NetworkInfo>(),
      sl<TokenManager>(),
    );
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authBloc?.close();
    _businessBloc?.close();
    _branchBloc?.close();
    _sessionBloc?.close();
    _syncBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: _themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return FutureBuilder<void>(
            future: _bootstrapFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  home: const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
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
                child: Builder(
                  builder: (context) {
                    final router = AppRouter.build(
                      authBloc: _authBloc!,
                      businessBloc: _businessBloc!,
                      sessionBloc: _sessionBloc!,
                    );
                    return MaterialApp.router(
                      title: AppConstants.appName,
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: themeMode,
                      routerConfig: router,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
