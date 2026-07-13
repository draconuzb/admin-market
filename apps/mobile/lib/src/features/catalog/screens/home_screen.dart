import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/product_card.dart';
import '../catalog_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = [
    Icons.restaurant, Icons.local_drink, Icons.kitchen,
    Icons.category, Icons.shopping_basket,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredProductsProvider);
    final factories = ref.watch(factoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(factoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero()),
            SliverToBoxAdapter(child: _sectionTitle(context, 'home.categories'.tr())),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: categories.maybeWhen(
                  data: (list) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ActionChip(
                      avatar: Icon(_categoryIcons[i % _categoryIcons.length],
                          size: 18, color: AppTheme.accent),
                      label: Text(list[i].name(lang)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade200),
                      onPressed: () => context.push('/products?category=${list[i].id}'),
                    ),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle(context, 'home.featured'.tr())),
            featured.when(
              loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 200, child: LoadingView())),
              error: (e, _) => SliverToBoxAdapter(
                  child: SizedBox(height: 120, child: ErrorView(message: e.toString()))),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ProductCard(
                        product: list[i], onTap: () => context.push('/product/${list[i].id}')),
                    childCount: list.length,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle(context, 'home.factories'.tr())),
            factories.when(
              loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 80, child: LoadingView())),
              error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
              data: (list) => SliverList.list(children: [
                for (final f in list)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                        child: Text(f.name.characters.first,
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(f.name),
                      subtitle: f.region != null ? Text(f.region!) : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/products?factory=${f.id}'),
                    ),
                  ),
                const SizedBox(height: 16),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

/// Gradient welcome banner with a search shortcut into the catalog.
class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color(0xFF3A6BF0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white),
                const SizedBox(width: 8),
                Text('app_name'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/products'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text('catalog.search_hint'.tr(),
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
