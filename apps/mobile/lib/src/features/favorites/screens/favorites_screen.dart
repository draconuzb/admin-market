import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/product_card.dart';
import '../favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesListProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('favorites.title'.tr())),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteIdsProvider);
          ref.invalidate(favoritesListProvider);
        },
        child: async.when(
          loading: () => const GridSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(favoritesListProvider),
          ),
          data: (products) => products.isEmpty
              ? Stack(children: [
                  ListView(),
                  EmptyView(
                      message: 'favorites.empty'.tr(),
                      icon: Icons.favorite_border_rounded),
                ])
              : GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  padding: const EdgeInsets.all(20),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: [
                    for (final p in products)
                      ProductCard(product: p, onTap: () => context.push('/product/${p.id}')),
                  ],
                ),
        ),
      ),
    );
  }
}
