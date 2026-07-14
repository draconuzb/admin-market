import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/catalog.dart';
import '../../models/page.dart';
import '../../providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).categories();
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Featured = newest sort, first page; the UI filters is_featured client-side
  // and falls back to newest so the home screen is never empty.
  final page = await ref.watch(catalogRepositoryProvider).products(pageSize: 20);
  final featured = page.items.where((p) => p.isFeatured).toList();
  return featured.isNotEmpty ? featured : page.items.take(6).toList();
});

final factoriesProvider = FutureProvider<List<Factory>>((ref) async {
  final page = await ref.watch(catalogRepositoryProvider).factories();
  return page.items;
});

final productDetailProvider =
    FutureProvider.family<Product, int>((ref, id) {
  return ref.watch(catalogRepositoryProvider).product(id);
});

/// Immutable filter for the catalog list.
class CatalogFilter {
  const CatalogFilter({
    this.search,
    this.categoryId,
    this.factoryId,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.sort = 'newest',
  });
  final String? search;
  final int? categoryId;
  final int? factoryId;
  final num? minPrice;
  final num? maxPrice;
  final bool inStock;
  final String sort;

  /// Count of active advanced filters (for the filter button badge).
  int get activeCount =>
      (minPrice != null ? 1 : 0) + (maxPrice != null ? 1 : 0) + (inStock ? 1 : 0);

  CatalogFilter copyWith({
    String? search,
    int? categoryId,
    int? factoryId,
    String? sort,
    bool clearCategory = false,
  }) {
    return CatalogFilter(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      factoryId: factoryId ?? this.factoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock,
      sort: sort ?? this.sort,
    );
  }

  /// Replace the advanced filters (price + stock) from the filter sheet.
  CatalogFilter withAdvanced({num? minPrice, num? maxPrice, bool? inStock, String? sort}) {
    return CatalogFilter(
      search: search,
      categoryId: categoryId,
      factoryId: factoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock ?? this.inStock,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.factoryId == factoryId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.inStock == inStock &&
      other.sort == sort;

  @override
  int get hashCode =>
      Object.hash(search, categoryId, factoryId, minPrice, maxPrice, inStock, sort);
}

final catalogListProvider =
    FutureProvider.family<Paged<Product>, CatalogFilter>((ref, filter) {
  return ref.watch(catalogRepositoryProvider).products(
        search: filter.search,
        categoryId: filter.categoryId,
        factoryId: filter.factoryId,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        inStock: filter.inStock,
        sort: filter.sort,
      );
});
