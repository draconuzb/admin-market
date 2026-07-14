import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../models/catalog.dart';
import '../../providers.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);
  final ApiClient _api;

  Future<Set<int>> ids() async {
    final resp = await _api.get('/favorites/ids');
    return (resp.data as List).map((e) => e as int).toSet();
  }

  Future<List<Product>> list() async {
    final resp = await _api.get('/favorites');
    return (resp.data as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(int productId) => _api.post('/favorites/$productId');
  Future<void> remove(int productId) => _api.delete('/favorites/$productId');
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(apiClientProvider)),
);

/// Set of favorited product ids; toggled optimistically.
final favoriteIdsProvider =
    AsyncNotifierProvider<FavoritesController, Set<int>>(FavoritesController.new);

class FavoritesController extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    // Only buyers have favorites; failures degrade to an empty set.
    try {
      return await ref.read(favoritesRepositoryProvider).ids();
    } catch (_) {
      return <int>{};
    }
  }

  bool isFavorite(int productId) =>
      state.valueOrNull?.contains(productId) ?? false;

  Future<void> toggle(int productId) async {
    final current = {...(state.valueOrNull ?? <int>{})};
    final repo = ref.read(favoritesRepositoryProvider);
    final wasFav = current.contains(productId);
    // Optimistic update.
    if (wasFav) {
      current.remove(productId);
    } else {
      current.add(productId);
    }
    state = AsyncData(current);
    try {
      if (wasFav) {
        await repo.remove(productId);
      } else {
        await repo.add(productId);
      }
    } catch (_) {
      // Revert on failure.
      final reverted = {...current};
      if (wasFav) {
        reverted.add(productId);
      } else {
        reverted.remove(productId);
      }
      state = AsyncData(reverted);
    }
  }
}

final favoritesListProvider = FutureProvider<List<Product>>((ref) {
  // Recompute when the id set changes.
  ref.watch(favoriteIdsProvider);
  return ref.watch(favoritesRepositoryProvider).list();
});
