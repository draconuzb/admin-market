import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
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
  final _focusNode = FocusNode();

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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(catalogListProvider(_filter));
    final isFiltered =
        widget.initialCategoryId != null || widget.initialFactoryId != null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  if (isFiltered)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'catalog.search_hint'.tr(),
                          hintStyle: const TextStyle(
                              color: AppTheme.textTertiary, fontSize: 15),
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.textTertiary, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (v) =>
                            setState(() => _filter = _filter.copyWith(search: v)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category chips ──
            SizedBox(
              height: 44,
              child: categories.maybeWhen(
                data: (list) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    _catChip('catalog.filter_all'.tr(),
                        _filter.categoryId == null,
                        () => setState(
                            () => _filter = _filter.copyWith(clearCategory: true))),
                    for (final c in list)
                      _catChip(c.name(lang),
                          _filter.categoryId == c.id,
                          () => setState(
                              () => _filter = _filter.copyWith(categoryId: c.id))),
                  ],
                ),
                orElse: () => const SizedBox(),
              ),
            ),

            // ── Product grid ──
            Expanded(
              child: products.when(
                loading: () => const GridSkeleton(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(catalogListProvider(_filter)),
                ),
                data: (page) => page.items.isEmpty
                    ? EmptyView(message: 'catalog.empty'.tr(),
                        icon: Icons.search_off_rounded)
                    : GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        padding: const EdgeInsets.all(20),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
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
      ),
    );
  }

  Widget _catChip(String text, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected ? [] : AppTheme.cardShadow,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('catalog.sort'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _sortTile('catalog.sort_newest'.tr(), 'newest'),
            _sortTile('catalog.sort_price_asc'.tr(), 'price_asc'),
            _sortTile('catalog.sort_price_desc'.tr(), 'price_desc'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String text, String value) => ListTile(
        title: Text(text, style: const TextStyle(fontSize: 16)),
        trailing: _filter.sort == value
            ? const Icon(Icons.check, color: AppTheme.accent, size: 20)
            : null,
        onTap: () {
          setState(() => _filter = _filter.copyWith(sort: value));
          Navigator.pop(context);
        },
      );
}
