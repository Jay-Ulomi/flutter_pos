import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/utils/token_manager.dart';
import '../data/datasources/local/customer_local.dart';
import '../data/datasources/local/database.dart';
import '../data/datasources/local/laundry_local.dart';
import '../data/datasources/local/product_local.dart';
import '../data/datasources/local/sale_local.dart';
import '../data/datasources/local/session_local.dart';
import '../data/datasources/remote/auth_remote.dart';
import '../data/datasources/remote/customer_remote.dart';
import '../data/datasources/remote/inventory_remote.dart';
import '../data/datasources/remote/laundry_remote.dart';
import '../data/datasources/remote/product_remote.dart';
import '../data/datasources/remote/sale_remote.dart';
import '../data/datasources/remote/session_remote.dart';
import '../data/datasources/remote/sync_remote.dart';
import '../data/datasources/remote/promotion_remote.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/customer_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../data/repositories/sale_repository_impl.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../core/services/card_terminal_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/sale_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/repositories/sync_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Safe-guard against duplicate setup calls (hot restart/tests/custom entrypoints).
  if (sl.isRegistered<AuthRepository>()) {
    return;
  }

  // Core
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => FlutterSecureStorage(
      // macOS keychain needs accessibility option to work with sandbox + ad-hoc signing
      mOptions: Platform.isMacOS
          ? const MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock,
              useDataProtectionKeyChain: false,
            )
          : const MacOsOptions(),
    ),
  );
  sl.registerLazySingleton<TokenManager>(() => TokenManager(sl()));
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(sl()));
  await sl<NetworkInfo>().initialize();

  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Remote datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<LaundryRemoteDataSource>(
    () => LaundryRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SaleRemoteDataSource>(
    () => SaleRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<PromotionRemoteDataSource>(
    () => PromotionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SessionRemoteDataSource>(
    () => SessionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSource(sl()),
  );

  // Local datasources
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSource(sl()),
  );
  sl.registerLazySingleton<SaleLocalDataSource>(
    () => SaleLocalDataSource(sl()),
  );
  sl.registerLazySingleton<LaundryLocalDataSource>(
    () => LaundryLocalDataSource(sl()),
  );
  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSource(sl()),
  );
  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<SaleRepository>(
    () => SaleRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(sl(), sl(), sl(), sl(), sl(), sl()),
  );

  // Card terminal — swap MockCardTerminalService for StripeCardTerminalService
  // (or another provider) when real hardware is available.
  sl.registerLazySingleton<CardTerminalService>(
    () => MockCardTerminalService(),
  );
}
