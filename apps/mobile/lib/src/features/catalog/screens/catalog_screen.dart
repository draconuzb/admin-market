import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/product_card.dart';
import '../catalog_providers.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, this.initialCategoryId, this.initialFactoryId});
  final int? initialCategoryId;
  final int? initialFactoryId;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late CatalogFilter _filter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = CatalogFilter(
      categoryId: widget.initialCategoryId,
      factoryId: widget.initialFactoryId,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(catalogListProvider(_filter));
    // A filtered view opened from Home is pushed (has a back button);
    // the Catalog tab is not.
    final isFiltered = widget.initialCategoryId != null || widget.initialFactoryId != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: isFiltered,
        title: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'catalog.search_hint'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
          ),
          onSubmitted: (v) => setState(() => _filter = _filter.copyWith(search: v)),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _filter = _filter.copyWith(sort: v)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'newest', child: Text('catalog.sort_newest'.tr())),
              PopupMenuItem(value: 'price_asc', child: Text('catalog.sort_price_asc'.tr())),
              PopupMenuItem(value: 'price_desc', child: Text('catalog.sort_price_desc'.tr())),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: categories.maybeWhen(
              data: (list) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text('catalog.filter_all'.tr()),
                      selected: _filter.categoryId == null,
                      onSelected: (_) =>
                          setState(() => _filter = _filter.copyWith(clearCategory: true)),
                    ),
                  ),
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: ChoiceChip(
                        label: Text(c.name(lang)),
                        selected: _filter.categoryId == c.id,
                        onSelected: (_) =>
                            setState(() => _filter = _filter.copyWith(categoryId: c.id)),
                      ),
                    ),
                ],
              ),
              orElse: () => const SizedBox(),
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const ListSkeleton(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(catalogListProvider(_filter)),
              ),
              data: (page) => page.items.isEmpty
                  ? EmptyView(message: 'catalog.empty'.tr())
                  : GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        for (final p in page.items)
                          ProductCard(
                            product: p,
                            onTap: () => context.push('/product/${p.id}'),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
