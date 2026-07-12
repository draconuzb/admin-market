import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/product_card.dart';
import '../catalog_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredProductsProvider);
    final factories = ref.watch(factoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('app_name'.tr())),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(factoriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _sectionTitle(context, 'home.categories'.tr()),
            SizedBox(
              height: 44,
              child: categories.when(
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
                data: (list) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    label: Text(list[i].name(lang)),
                    onPressed: () => context.push('/products?category=${list[i].id}'),
                  ),
                ),
              ),
            ),
            _sectionTitle(context, 'home.featured'.tr()),
            featured.when(
              loading: () => const SizedBox(height: 200, child: LoadingView()),
              error: (e, _) => SizedBox(height: 120, child: ErrorView(message: e.toString())),
              data: (list) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final p in list)
                    ProductCard(product: p, onTap: () => context.push('/product/${p.id}')),
                ],
              ),
            ),
            _sectionTitle(context, 'home.factories'.tr()),
            factories.when(
              loading: () => const SizedBox(height: 80, child: LoadingView()),
              error: (e, _) => const SizedBox(),
              data: (list) => Column(
                children: [
                  for (final f in list)
                    ListTile(
                      leading: CircleAvatar(child: Text(f.name.characters.first)),
                      title: Text(f.name),
                      subtitle: f.region != null ? Text(f.region!) : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/products?factory=${f.id}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );
}
