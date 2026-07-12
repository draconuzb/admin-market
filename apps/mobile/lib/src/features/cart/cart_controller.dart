import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cart.dart';
import '../../providers.dart';

/// Holds the buyer's cart. Loaded lazily; mutations update state in place.
final cartControllerProvider =
    AsyncNotifierProvider<CartController, Cart>(CartController.new);

class CartController extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() => ref.read(cartRepositoryProvider).get();

  Future<void> add(int productId, int quantity) async {
    final cart = await ref.read(cartRepositoryProvider).addItem(productId, quantity);
    state = AsyncData(cart);
  }

  Future<void> updateQty(int itemId, int quantity) async {
    final cart = await ref.read(cartRepositoryProvider).updateItem(itemId, quantity);
    state = AsyncData(cart);
  }

  Future<void> remove(int itemId) async {
    final cart = await ref.read(cartRepositoryProvider).removeItem(itemId);
    state = AsyncData(cart);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cartRepositoryProvider).get());
  }

  Future<void> clearLocal() async {
    state = AsyncData(Cart.empty());
  }
}

/// Number of distinct lines in the cart, for the bottom-nav badge.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).maybeWhen(
        data: (cart) => cart.count,
        orElse: () => 0,
      );
});
