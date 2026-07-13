import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/dio_client.dart';
import 'core/storage.dart';
import 'features/admin/admin_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/cart/cart_repository.dart';
import 'features/catalog/catalog_repository.dart';
import 'features/factory/factory_repository.dart';
import 'features/orders/orders_repository.dart';

/// Overridden in main() once SharedPreferences is loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    storage,
    onSessionExpired: () {
      // Clear tokens and drop the session; the router redirects to login.
      storage.clear();
      ref.read(authControllerProvider.notifier).markLoggedOut();
    },
  );
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepository(ref.watch(apiClientProvider)));

final factoryRepositoryProvider =
    Provider<FactoryRepository>((ref) => FactoryRepository(ref.watch(apiClientProvider)));

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));
